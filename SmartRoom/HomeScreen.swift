import SwiftUI

struct HomeScreen: View {
    let onLogout: () -> Void
    
    @State private var activeMode: String = "home"
    @State private var selectedTab: Int = 0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // API Test State
    @State private var apiTestResponse: String = "Chưa test API..."
    @State private var isTestingAPI: Bool = false
    
    // API data
    @State private var floors: [Floor] = []
    @State private var allRooms: [Room] = []
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    AppColors.appBackground.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // ======================
                        // TOP BAR HEADER
                        // ======================
                        HStack {
                            Text("My Home")
                                .font(AppTypography.headlineMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                TokenManager.shared.logout()
                                onLogout()
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, geometry.safeAreaInsets.top + 8)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.appBackground)
                        
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                
                                HeroWeatherCard()
                                    .padding(.top, 16)
                                
                                SmartModesSection(activeMode: $activeMode)
                                
                                SegmentedControlView(selectedTab: $selectedTab)
                                
                                if isLoading && floors.isEmpty {
                                    LoadingView()
                                } else if let error = errorMessage {
                                    ErrorView(message: error) {
                                        retry()
                                    }
                                } else if selectedTab == 0 {
                                    VStack(spacing: 16) {
                                        DebugInfoView(
                                            floors: floors,
                                            rooms: allRooms,
                                            isLoading: isLoading
                                        )
                                        
                                        if floors.isEmpty {
                                            EmptyFloorsView()
                                        } else {
                                            ForEach(floors) { floor in
                                                let roomsInFloor = getRoomsForFloor(floor.id)
                                                FloorSectionView(
                                                    floorName: "\(floor.name) • \(roomsInFloor.count) phòng",
                                                    rooms: roomsInFloor
                                                )
                                            }
                                        }
                                    }
                                } else {
                                    DevicesView()
                                }
                                
                                // API TEST SECTION
                                APITestSection(
                                    apiResponse: apiTestResponse,
                                    isTesting: isTestingAPI,
                                    onTestAPI: {
                                        testFloorsAPI()
                                    }
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true) // Ẩn nav bar mặc định
        }
        .onAppear {
            loadFloorsAndRooms()
        }
    }
    
    private func retry() {
        errorMessage = nil
        loadFloorsAndRooms()
    }
    
    private func loadFloorsAndRooms() {
        Task { await performDataLoad() }
    }
    
    @MainActor
    private func performDataLoad() async {
        isLoading = true
        errorMessage = nil
        
        let service = SmartRoomAPIService.shared
        
        do {
            let loadedFloors = try await service.getFloors()
            floors = loadedFloors
            
            let roomsArrays = try await withThrowingTaskGroup(of: [Room].self) { group in
                for floor in loadedFloors {
                    group.addTask {
                        try await service.getRoomsByFloor(floor.id)
                    }
                }
                
                var result: [[Room]] = []
                for try await rooms in group {
                    result.append(rooms)
                }
                return result
            }
            
            allRooms = roomsArrays.flatMap { $0 }
            isLoading = false
            
        } catch SmartRoomAPIError.tokenExpired {
            isLoading = false
        } catch {
            errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func getRoomsForFloor(_ floorId: Int) -> [Room] {
        allRooms.filter { $0.floorId == floorId }
    }
    
    // ======================
    // API TEST LOGIC
    // ======================
    private func testFloorsAPI() {
        Task { await performAPITest() }
    }
    
    @MainActor
    private func performAPITest() async {
        isTestingAPI = true
        apiTestResponse = "🔄 Đang gọi API GET /floors...\n"
        
        let service = SmartRoomAPIService.shared
        
        do {
            let floors = try await service.getFloors()
            
            var text = ""
            text += "🏢 FLOORS API RESPONSE\n"
            text += "============================\n"
            text += "Total floors: \(floors.count)\n\n"
            
            for (index, floor) in floors.enumerated() {
                text += "\(index + 1). \(floor.name)\n"
                text += "   • id: \(floor.id)\n"
                
                if let desc = floor.description, !desc.isEmpty {
                    text += "   • description: \(desc)\n"
                }
                
                text += "\n"
            }
            
            apiTestResponse = text
            
        } catch {
            apiTestResponse =
            """
            ❌ FLOORS API ERROR
            -------------------
            \(error.localizedDescription)
            """
        }
        
        isTestingAPI = false
    }
}


// === TẤT CẢ CÁC SUBVIEW BÊN DƯỚI GIỮ NGUYÊN 100% NHƯ CŨ ===
// (Không thay đổi gì để tránh làm file quá dài và giữ nguyên thiết kế của bạn)


// MARK: - Hero Weather Card
struct HeroWeatherCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My location")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Montreal")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Text("-10°")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("Partly Cloudy")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Smart Modes Section
struct SmartModesSection: View {
    @Binding var activeMode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Modes")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                SmartModeCard(
                    title: "At Home",
                    subtitle: "All Active",
                    icon: "house.fill",
                    isActive: activeMode == "home"
                ) {
                    activeMode = "home"
                }
                
                SmartModeCard(
                    title: "Left Home",
                    subtitle: "Security On",
                    icon: "door.right.hand.open",
                    isActive: activeMode == "away"
                ) {
                    activeMode = "away"
                }
            }
        }
    }
}

struct SmartModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isActive ? AppColors.surfaceWhite : AppColors.textPrimary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(isActive ? AppColors.surfaceWhite : AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(isActive ? AppColors.surfaceWhite.opacity(0.8) : AppColors.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? AppColors.primaryPurple : AppColors.surfaceWhite)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Segmented Control
struct SegmentedControlView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            SegmentButton(title: "Room", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            SegmentButton(title: "Devices", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surfaceWhite)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.labelLarge)
                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color(red: 0.94, green: 0.96, blue: 0.98) : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 1, x: 0, y: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                .scaleEffect(1.2)
            
            Text("Đang tải dữ liệu...")
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(height: 200)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("❌ Lỗi")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.accentPink)
            
            Text(message)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Button("Thử lại") {
                retry()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.primaryPurple)
            .foregroundColor(AppColors.surfaceWhite)
            .cornerRadius(8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surfaceWhite)
                .stroke(AppColors.accentPink.opacity(0.3), lineWidth: 1)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Debug Info View
struct DebugInfoView: View {
    let floors: [Floor]
    let rooms: [Room]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📀 Debug Info:")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text("• \(floors.count) tầng")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text("• \(rooms.count) phòng")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
            
            if isLoading {
                Text("• Đang tải...")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primaryPurple)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Empty Floors View
struct EmptyFloorsView: View {
    var body: some View {
        Text("Không có tầng nào.")
            .foregroundColor(AppColors.textSecondary)
            .padding(20)
    }
}

// MARK: - Devices View
struct DevicesView: View {
    var body: some View {
        VStack {
            Text("Devices view coming soon...")
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(height: 100)
    }
}

// MARK: - Floor Section View
struct FloorSectionView: View {
    let floorName: String
    let rooms: [Room]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(floorName)
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(rooms) { room in
                        NavigationLink(destination: RoomDetailScreen(room: room)) {
                            RoomCard(room: room)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    @State private var isOn: Bool = true
    
    private var roomImageURL: String {
        switch room.name.lowercased() {
        case let name where name.contains("living") || name.contains("khách"):
            return "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        case let name where name.contains("bed") || name.contains("ngủ"):
            return "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?q=80&w=580&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        case let name where name.contains("kitchen") || name.contains("bếp"):
            return "https://images.unsplash.com/photo-1556910096-6f5e72db6803?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        default:
            return "https://images.unsplash.com/photo-1628012209120-d9db7abf7eab?q=80&w=436&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: roomImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(AppColors.surfaceLight)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                }
            }
            .frame(height: 120)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("4 devices")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                HStack {
                    Text(isOn ? "ON" : "OFF")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(isOn ? AppColors.primaryPurple : AppColors.textSecondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isOn)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(0.8)
                        .onTapGesture {
                            // Ngăn NavigationLink kích hoạt khi tap toggle
                        }
                }
            }
            .padding(16)
        }
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - API Test Section
struct APITestSection: View {
    let apiResponse: String
    let isTesting: Bool
    let onTestAPI: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🧪 API Test")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: onTestAPI) {
                    HStack(spacing: 8) {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.surfaceWhite))
                        } else {
                            Image(systemName: "play.fill")
                        }
                        
                        Text(isTesting ? "Testing..." : "Test API")
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.surfaceWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isTesting ? AppColors.textSecondary : AppColors.primaryPurple)
                    )
                }
                .disabled(isTesting)
            }
            
            ScrollView {
                Text(apiResponse)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
            
            Text("Flow: GET /api/v1/floors → GET /api/v1/floors/{id}/rooms")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Preview
#Preview {
    HomeScreen(onLogout: {
        print("Logout in preview")
    })
}
