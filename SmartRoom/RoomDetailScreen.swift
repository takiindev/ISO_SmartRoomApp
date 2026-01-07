import SwiftUI

// MARK: - Room Detail UI State
struct RoomDetailUiState {
    var isLoading: Bool = true
    var isLoadingLights: Bool = true
    var roomName: String = ""
    var currentTemp: Double = 0.0
    var lights: [Light] = []
    var errorMessage: String? = nil
    var apiResponse: String = ""
    var toggleResponse: String = ""
    var lightStatusResponse: String = ""
    var togglingLightIds: Set<Int> = [] // Track which lights are being toggled
}

// MARK: - Room Detail ViewModel
@MainActor
class RoomDetailViewModel: ObservableObject {
    let roomId: Int
    let roomName: String
    @Published var uiState = RoomDetailUiState()
    
    init(roomId: Int, roomName: String) {
        self.roomId = roomId
        self.roomName = roomName
        loadData()
    }
    
    func loadData() {
        Task {
            uiState.isLoading = true
            uiState.errorMessage = nil
            
            // Load real data from API
            await loadRoomData()
            
            uiState.isLoading = false
        }
    }
    
    private func loadRoomData() async {
        do {
            // Set room name from constructor
            uiState.roomName = roomName
            
            // Hardcode temperature to 26 degrees
            uiState.currentTemp = 26.0
            
            // Set lights loading state
            uiState.isLoadingLights = true
            
            // Try to get lights from API
            let lights = try await SmartRoomAPIService.shared.getLightsByRoom(roomId)
            uiState.lights = lights
            uiState.isLoadingLights = false
            
            // Get raw API response for debugging
            let rawResponse = try await SmartRoomAPIService.shared.getRawLightsByRoom(roomId)
            uiState.apiResponse = rawResponse
            
        } catch {
            print("❌ API error for room \(roomId): \(error.localizedDescription)")
            
            // Check if it's a token expiry error - don't show error message as app will logout automatically
            if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                print("🚨 Token expired while loading room data - auto logout will trigger")
                uiState.isLoadingLights = false
                return // Don't set error message, let the logout flow handle it
            }
            
            // Set room name from constructor
            uiState.roomName = roomName
            uiState.currentTemp = 26.0
            
            // Show error message instead of fake data
            uiState.isLoadingLights = false
            uiState.errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
        }
    }

    
    // Toggle light
    func toggleLight(_ lightId: Int) {
        guard let index = uiState.lights.firstIndex(where: { $0.id == lightId }) else { return }
        
        // Add to toggling set to disable the toggle
        uiState.togglingLightIds.insert(lightId)
        
        Task {
            do {
                // Call toggle API and get raw response
                let rawResponse = try await SmartRoomAPIService.shared.toggleLightAndGetResponse(lightId)
                uiState.toggleResponse = rawResponse
                
                // Refresh the specific light state to get updated status from server
                let updatedLight = try await SmartRoomAPIService.shared.getLightById(lightId)
                
                // Get raw response from individual light API for comparison
                let lightStatusRaw = try await SmartRoomAPIService.shared.getRawLightById(lightId)
                
                // Update UI state with actual server response
                await MainActor.run {
                    uiState.lights[index] = updatedLight
                    uiState.lightStatusResponse = lightStatusRaw
                }
                
                print("✅ Toggle light \(lightId) successful - new state: \(updatedLight.isActive)")
                
            } catch {
                print("❌ API error when toggling light \(lightId): \(error.localizedDescription)")
                
                // Check if it's a token expiry error
                if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                    print("🚨 Token expired while toggling light - auto logout will trigger")
                    await MainActor.run {
                        uiState.togglingLightIds.remove(lightId)
                    }
                    return // Don't set error message, let logout flow handle it
                }
                
                // Show error in toggle response
                await MainActor.run {
                    uiState.toggleResponse = "❌ Lỗi: \(error.localizedDescription)"
                    uiState.lightStatusResponse = "❌ Không thể lấy trạng thái đèn sau khi toggle"
                }
            }
            
            // Remove from toggling set
            await MainActor.run {
                uiState.togglingLightIds.remove(lightId)
            }
        }
    }
    
    // Set light level
    func setLightLevel(_ lightId: Int, _ level: Int) {
        guard let index = uiState.lights.firstIndex(where: { $0.id == lightId }) else { return }
        
        // Store original active state for comparison
        let originalActive = uiState.lights[index].isActive
        
        Task {
            do {
                let success = try await SmartRoomAPIService.shared.updateLightLevel(lightId, level: level)
                
                if success {
                    // Update UI state
                    uiState.lights[index].level = level
                    uiState.lights[index].isActive = level > 0
                    
                    // If level > 0 but light was off, also update the active state on server
                    if level > 0 && !originalActive {
                        _ = try await SmartRoomAPIService.shared.updateLightState(lightId, isActive: true)
                    }
                } else {
                    print("❌ Failed to set light level for light \(lightId)")
                }
            } catch {
                print("❌ API error when setting light level for light \(lightId): \(error.localizedDescription)")
                
                // Check if it's a token expiry error
                if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                    print("🚨 Token expired while setting light level - auto logout will trigger")
                    return // Don't revert state, let logout flow handle it
                }
                
                // Don't update UI state on error - keep original state
                print("❌ Failed to set light \(lightId) level to \(level)%")
            }
        }
    }
    

}

// MARK: - Room Detail Screen
struct RoomDetailScreen: View {
    let room: Room
    @StateObject private var viewModel: RoomDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(room: Room) {
        self.room = room
        self._viewModel = StateObject(wrappedValue: RoomDetailViewModel(roomId: room.id, roomName: room.name))
    }
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            if viewModel.uiState.isLoading {
                RoomDetailLoadingView()
            } else if let errorMessage = viewModel.uiState.errorMessage {
                RoomDetailErrorView(message: errorMessage) {
                    viewModel.loadData()
                }
            } else {
                mainContent
            }
        }
        .navigationBarHidden(true)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // TOP BAR
            topBar
            
            // MAIN CONTENT
            ScrollView {
                LazyVStack(spacing: 24) {
                    // HERO GAUGE (3D Temperature)
                    Circular3DGauge(value: viewModel.uiState.currentTemp, size: 220)
                    
                    // NAVIGATION CARDS (Temperature & Power)
                    monitoringSection
                    
                    // DEVICE LIST
                    devicesSection
                    
                    // API RESPONSE SECTION
                    apiResponseSection
                    
                    // TOGGLE RESPONSE SECTION
                    toggleResponseSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text(viewModel.uiState.roomName)
                .font(AppTypography.headlineMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitoring")
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                NavigationLink(destination: TemperatureScreen(room: room)) {
                    VStack(spacing: 8) {
                        Image(systemName: "thermometer")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.accentPink)
                        
                        Text("Climate")
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surfaceWhite)
                            .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavDetailCard(
                    title: "Power",
                    icon: "bolt.fill",
                    color: AppColors.primaryPurple,
                    onClick: {
                        print("Navigate to power chart")
                    }
                )
            }
        }
    }
    
    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Devices")
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            if viewModel.uiState.isLoadingLights {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                        Text("Loading devices...")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if viewModel.uiState.lights.isEmpty {
                Text("No devices found")
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(viewModel.uiState.lights) { light in
                    DeviceControlCard(
                        light: light,
                        onToggle: { viewModel.toggleLight(light.id) },
                        onLevelChange: { viewModel.setLightLevel(light.id, $0) },
                        isToggling: viewModel.uiState.togglingLightIds.contains(light.id)
                    )
                }
            }
        }
    }
    
    private var apiResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Response")
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("/api/v1/lights/room/\(viewModel.roomId)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, 4)
            
            ScrollView {
                if viewModel.uiState.isLoadingLights {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                            Text("Loading API response...")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    Text(viewModel.uiState.apiResponse)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
            .frame(height: 200)
            .background(AppColors.surfaceLight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.surfaceLight.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var toggleResponseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Responses Comparison")
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            // Toggle Response
            VStack(alignment: .leading, spacing: 8) {
                Text("Toggle Response")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("/api/v1/lights/{id}/toggle-state")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                ScrollView {
                    if viewModel.uiState.toggleResponse.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "lightswitch.on")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Toggle any light to see response")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    } else {
                        Text(viewModel.uiState.toggleResponse)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
                .frame(height: 120)
                .background(AppColors.surfaceLight)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.surfaceLight.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Light Status Response
            VStack(alignment: .leading, spacing: 8) {
                Text("Light Status Response")
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("/api/v1/lights/{id}")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                ScrollView {
                    if viewModel.uiState.lightStatusResponse.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Toggle any light to see status")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    } else {
                        Text(viewModel.uiState.lightStatusResponse)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
                .frame(height: 120)
                .background(AppColors.surfaceLight)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.surfaceLight.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - 3D Gauge Component
    struct Circular3DGauge: View {
        let value: Double
        let size: CGFloat
        
        var body: some View {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(AppColors.surfaceLight, lineWidth: 8)
                    .frame(width: size, height: size)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: CGFloat(value / 40.0)) // Assuming max temp is 40°C
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primaryPurple, AppColors.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                
                // Center Content
                VStack(spacing: 8) {
                    Text("\(Int(value))°")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Temperature")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 12, x: 0, y: 6)
        }
    }
    
    // MARK: - Navigation Detail Card
    struct NavDetailCard: View {
        let title: String
        let icon: String
        let color: Color
        let onClick: () -> Void
        
        var body: some View {
            Button(action: onClick) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.surfaceWhite)
                        .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Device Control Card
    struct DeviceControlCard: View {
        let light: Light
        let onToggle: () -> Void
        let onLevelChange: (Int) -> Void
        let isToggling: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(light.isActive ? AppColors.primaryPurple : AppColors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(light.name)
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(light.isActive ? "\(light.level)%" : "Off")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { light.isActive },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryPurple))
                    .disabled(isToggling)
                }
                
                // Slider (only show when device is on)
                if light.isActive {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brightness")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Slider(
                            value: Binding(
                                get: { Double(light.level) },
                                set: { onLevelChange(Int($0)) }
                            ),
                            in: 1...100,
                            step: 1
                        )
                        .accentColor(AppColors.primaryPurple)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceWhite)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
            )
        }
    }
    
    // MARK: - Light Model
    
    
    // MARK: - Room Detail Loading View
    private struct RoomDetailLoadingView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                    .scaleEffect(1.5)
                
                Text("Loading room details...")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Room Detail Error View
    private struct RoomDetailErrorView: View {
        let message: String
        let onRetry: () -> Void
        
        var body: some View {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.accentPink)
                
                VStack(spacing: 8) {
                    Text("Oops! Something went wrong")
                        .font(AppTypography.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(message)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Custom Shape for Rounded Corners
    struct RoundedCorner: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    // MARK: - Preview
    #Preview {
        RoomDetailScreen(
            room: Room(id: 1, name: "Living Room", floorId: 1, description: "Main living area")
        )
    }
}
