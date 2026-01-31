import SwiftUI

struct HomeScreen: View {
    let onLogout: () -> Void
    
    var body: some View {
        MainTabView(onLogout: onLogout)
    }
}

// MARK: - Home Screen Content
struct HomeScreenContent: View {
    let onLogout: () -> Void
    
    @State private var activeMode: String = "home"
    @State private var selectedTab: Int = 0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // API data
    @State private var floors: [Floor] = []
    @State private var allRooms: [Room] = []
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // ======================
                // TOP BAR HEADER  
                // ======================
                HStack {
                    Text("My Home")
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    NavigationLink(destination: SettingScreen()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        HeroWeatherCard()
                            .padding(.top, 20)
                            
                            SmartModesSection(activeMode: $activeMode)
                                .padding(.vertical, 4)
                            
                            SegmentedControlView(selectedTab: $selectedTab)
                                .padding(.vertical, 4)
                            
                            if isLoading && floors.isEmpty {
                                LoadingView()
                            } else if let error = errorMessage {
                                ErrorView(message: error) {
                                    retry()
                                }
                            } else if selectedTab == 0 {
                                VStack(spacing: 16) {

                                    if floors.isEmpty {
                                        EmptyFloorsView()
                                    } else {
                                        ForEach(floors) { floor in
                                            let roomsInFloor = getRoomsForFloor(floor.id)
                                            FloorSectionView(
                                                floorName: "\(floor.name) • \(roomsInFloor.count) phòng",
                                                rooms: roomsInFloor,
                                                onRefresh: {
                                                    loadFloorsAndRooms()
                                                }
                                            )
                                        }
                                    }
                                }
                            } else {
                                DevicesView()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                        .padding(.bottom, 80) // Space for bottom navigation
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        .onAppear {
            loadFloorsAndRooms()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Reload data when switching tabs
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
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                onRefresh()
            }) {
                HStack {
                    Text(floorName)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
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
    @State private var imageError: String = ""
    
    private var roomImageURL: String {
        // Dùng ảnh placeholder đơn giản từ picsum.photos
        let imageId: Int
        switch room.name.lowercased() {
        case let name where name.contains("living") || name.contains("khách"):
            imageId = 1
        case let name where name.contains("bed") || name.contains("ngủ"):
            imageId = 2
        case let name where name.contains("kitchen") || name.contains("bếp"):
            imageId = 3
        default:
            imageId = room.id
        }
        return "https://picsum.photos/400/300?random=\(imageId)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: roomImageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Rectangle()
                            .fill(AppColors.surfaceLight)
                        
                        VStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                            Text("Loading...")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(let error):
                    ZStack {
                        Rectangle()
                            .fill(AppColors.surfaceLight)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("No image")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                            
                            // Debug error
                            Text(error.localizedDescription)
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                                .lineLimit(2)
                                .padding(.horizontal, 4)
                        }
                    }
                    .onAppear {
                        print("❌ Image load failed for \(room.name): \(error.localizedDescription)")
                        print("   URL: \(roomImageURL)")
                    }
                @unknown default:
                    Rectangle()
                        .fill(AppColors.surfaceLight)
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

// MARK: - Preview
#Preview {
    HomeScreen(onLogout: {
        // Logout action
    })
}
