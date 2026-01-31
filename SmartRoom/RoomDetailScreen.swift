import SwiftUI

// MARK: - Room Detail UI State
struct RoomDetailUiState {
    var isLoading: Bool = true
    var isLoadingLights: Bool = true
    var isLoadingACs: Bool = true
    var roomName: String = ""
    var currentTemp: Double = 0.0
    var lights: [Light] = []
    var airConditioners: [ACDevice] = []
    var errorMessage: String? = nil
    var togglingLightIds: Set<Int> = [] // Track which lights are being toggled
    var togglingACIds: Set<Int> = [] // Track which ACs are being toggled
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
            uiState.isLoadingACs = true
            
            // Try to get lights from API
            let lights = try await SmartRoomAPIService.shared.getLightsByRoom(roomId)
            uiState.lights = lights
            uiState.isLoadingLights = false
            
            // Try to get air conditioners from API
            let acs = try await SmartRoomAPIService.shared.getAirConditionsByRoom(roomId)
            uiState.airConditioners = acs.map { ACDevice(from: $0) }
            uiState.isLoadingACs = false
            
        } catch {
            // Check if it's a token expiry error - don't show error message as app will logout automatically
            if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                uiState.isLoadingLights = false
                uiState.isLoadingACs = false
                return // Don't set error message, let the logout flow handle it
            }
            
            // Set room name from constructor
            uiState.roomName = roomName
            uiState.currentTemp = 26.0
            
            // Show error message instead of fake data
            uiState.isLoadingLights = false
            uiState.isLoadingACs = false
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
                // Call toggle API
                _ = try await SmartRoomAPIService.shared.toggleLightAndGetResponse(lightId)
                
                // Refresh the specific light state to get updated status from server
                let updatedLight = try await SmartRoomAPIService.shared.getLightById(lightId)
                
                // Update UI state with actual server response
                await MainActor.run {
                    uiState.lights[index] = updatedLight
                }
                
            } catch {
                print("❌ API error when toggling light \(lightId): \(error.localizedDescription)")
                
                // Check if it's a token expiry error
                if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                    await MainActor.run {
                        uiState.togglingLightIds.remove(lightId)
                    }
                    return // Don't set error message, let logout flow handle it
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
                }
            } catch {
                // Check if it's a token expiry error
                if let apiError = error as? SmartRoomAPIError, apiError == .tokenExpired {
                    return // Don't revert state, let logout flow handle it
                }
            }
        }
    }
    
    // Reload ACs only
    func reloadACs() {
        Task {
            do {
                let acs = try await SmartRoomAPIService.shared.getAirConditionsByRoom(roomId)
                await MainActor.run {
                    uiState.airConditioners = acs.map { ACDevice(from: $0) }
                }
            } catch {
                print("⚠️ Failed to reload ACs: \(error.localizedDescription)")
            }
        }
    }
    
    // Toggle AC
    func toggleAC(_ acId: Int) {
        guard let index = uiState.airConditioners.firstIndex(where: { $0.id == acId }) else { return }
        
        // Add to toggling set
        uiState.togglingACIds.insert(acId)
        
        // Toggle state immediately
        uiState.airConditioners[index].isOn.toggle()
        let newState = uiState.airConditioners[index].isOn
        
        Task {
            let power = newState ? "ON" : "OFF"
            do {
                _ = try await SmartRoomAPIService.shared.updateAirCondition(acId, power: power)
            } catch {
                print("⚠️ Failed to toggle AC: \(error.localizedDescription)")
            }
            
            // Remove from toggling set
            await MainActor.run {
                uiState.togglingACIds.remove(acId)
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
        .onAppear {
            // Reload ACs when returning from ACDetailScreen
            if !viewModel.uiState.isLoading {
                viewModel.reloadACs()
            }
        }
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
                
                NavigationLink(destination: PowerScreen(room: room)) {
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.primaryPurple)
                        
                        Text("Power")
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
    }
    
    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Devices")
                .font(AppTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            if viewModel.uiState.isLoadingLights || viewModel.uiState.isLoadingACs {
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
            } else if viewModel.uiState.lights.isEmpty && viewModel.uiState.airConditioners.isEmpty {
                Text("No devices found")
                    .foregroundColor(AppColors.textSecondary)
            } else {
                // Lights
                ForEach(viewModel.uiState.lights) { light in
                    DeviceControlCard(
                        light: light,
                        onToggle: { viewModel.toggleLight(light.id) },
                        onLevelChange: { viewModel.setLightLevel(light.id, $0) },
                        isToggling: viewModel.uiState.togglingLightIds.contains(light.id)
                    )
                }
                
                // Air Conditioners
                ForEach(viewModel.uiState.airConditioners) { ac in
                    ACDeviceCard(
                        device: ac,
                        onToggle: { viewModel.toggleAC(ac.id) },
                        isToggling: viewModel.uiState.togglingACIds.contains(ac.id)
                    )
                }
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
            HStack(spacing: 15) {
                // Icon + Info
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(AppColors.surfaceWhite)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 22))
                            .foregroundColor(light.isActive ? Color(red: 1.0, green: 0.8, blue: 0.0) : AppColors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(light.name)
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 6) {
                            Text("\(light.level)%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.primaryPurple)
                            
                            Text("•")
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(light.isActive ? "ON" : "OFF")
                                .font(.system(size: 13))
                                .foregroundColor(light.isActive ? Color.green : AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Toggle Switch
                ZStack {
                    if isToggling {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { light.isActive },
                            set: { _ in onToggle() }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
                        .disabled(isToggling)
                    }
                }
                .frame(width: 51, height: 31)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceWhite)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
            )
        }
    }
    
    // MARK: - AC Device Card
    struct ACDeviceCard: View {
        let device: ACDevice
        let onToggle: () -> Void
        let isToggling: Bool
        @State private var navigateToDetail: Bool = false
        
        var body: some View {
            ZStack {
                NavigationLink(destination: ACDetailScreen(device: device), isActive: $navigateToDetail) {
                    EmptyView()
                }
                .hidden()
                
                HStack(spacing: 15) {
                    // Icon + Info
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(AppColors.surfaceWhite)
                                .frame(width: 50, height: 50)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            Image(systemName: "snowflake")
                                .font(.system(size: 22))
                                .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name)
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: 6) {
                                Text("\(device.temperature)°C")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.primaryPurple)
                                
                                Text("•")
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(device.mode)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Toggle Switch
                    ZStack {
                        if isToggling {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Toggle("", isOn: Binding(
                                get: { device.isOn },
                                set: { _ in onToggle() }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.0, green: 0.48, blue: 1.0)))
                            .disabled(isToggling)
                        }
                    }
                    .frame(width: 51, height: 31)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.surfaceWhite)
                        .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    navigateToDetail = true
                }
            }
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
