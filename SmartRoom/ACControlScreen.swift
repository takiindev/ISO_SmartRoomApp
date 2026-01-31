import SwiftUI

// MARK: - AC Data Models
struct ACDevice: Identifiable {
    let id: Int
    let name: String
    var temperature: Int
    var mode: String
    var isOn: Bool
    
    init(from ac: AirCondition) {
        self.id = ac.id
        self.name = ac.name
        self.temperature = ac.temperature
        self.mode = ac.mode
        self.isOn = ac.power == "ON"
    }
}

struct ACRoom: Identifiable {
    let id: Int
    let name: String
    var devices: [ACDevice]
    var isExpanded: Bool = false
    
    var activeDevicesCount: Int {
        devices.filter { $0.isOn }.count
    }
    
    init(from room: Room, devices: [ACDevice]) {
        self.id = room.id
        self.name = room.name
        self.devices = devices
    }
}

struct ACFloor: Identifiable {
    let id: Int
    let name: String
    var rooms: [ACRoom]
    var isLoaded: Bool = false
    
    init(from floor: Floor, rooms: [ACRoom] = []) {
        self.id = floor.id
        self.name = floor.name
        self.rooms = rooms
        self.isLoaded = false
    }
}

// MARK: - AC Control Screen
struct ACControlScreen: View {
    @State private var selectedFloorIndex: Int = 0
    @State private var floors: [ACFloor] = []
    @State private var isLoadingFloor: Bool = false
    @State private var isInitialLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var reloadTrigger: UUID = UUID()
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                ACHeaderView()
                
                // Tabs
                if !floors.isEmpty {
                    ACFloorTabsView(
                        floors: floors,
                        selectedIndex: $selectedFloorIndex,
                        onTabTapped: { index in
                            if index == selectedFloorIndex {
                                // Reload current floor
                                reloadFloorData(at: index)
                            } else {
                                selectedFloorIndex = index
                            }
                        }
                    )
                }
                
                // Content
                if isInitialLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(1.5)
                    Text("Đang tải dữ liệu...")
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 16)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("❌ Lỗi")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.accentPink)
                        
                        Text(error)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Button("Thử lại") {
                            loadFloors()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryPurple)
                        .foregroundColor(AppColors.surfaceWhite)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else if floors.isEmpty {
                    Spacer()
                    Text("Không có dữ liệu điều hòa")
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                } else {
                    ZStack {
                        ScrollView {
                            VStack(spacing: 16) {
                                if isLoadingFloor {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                                            .scaleEffect(1.2)
                                        Text("Đang tải dữ liệu tầng...")
                                            .foregroundColor(AppColors.textSecondary)
                                            .font(.system(size: 14))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                } else if floors[selectedFloorIndex].rooms.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 48))
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Text("Tầng này chưa có phòng nào")
                                            .font(AppTypography.titleMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Text("Vui lòng thêm phòng để quản lý điều hòa")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 80)
                                } else {
                                    ForEach($floors[selectedFloorIndex].rooms) { $room in
                                        ACRoomCard(room: $room)
                                    }
                                }
                            }
                            .padding(15)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
        }
        .onAppear {
            if floors.isEmpty {
                // First time loading
                loadFloors()
            } else if selectedFloorIndex >= 0 && selectedFloorIndex < floors.count {
                // Returning to screen - check if current floor needs reload
                if floors[selectedFloorIndex].rooms.isEmpty && !isLoadingFloor {
                    reloadFloorData(at: selectedFloorIndex)
                }
            }
        }
        .onChange(of: selectedFloorIndex) { oldValue, newValue in
            // Clear rooms and reload when changing floor
            if oldValue != newValue {
                reloadFloorData(at: newValue)
            }
        }
    }
    
    private func loadFloors() {
        Task { await performInitialLoad() }
    }
    
    private func loadFloorData(at index: Int) {
        guard index < floors.count else { return }
        if !floors[index].isLoaded {
            Task { await performFloorLoad(at: index) }
        }
    }
    
    private func reloadFloorData(at index: Int) {
        guard index >= 0, index < floors.count else { 
            print("⚠️ Cannot reload invalid floor index: \(index)")
            return 
        }
        print("🔄 Reloading floor \(index): \(floors[index].name)")
        // Clear rooms and mark as not loaded to force reload
        floors[index].rooms = []
        floors[index].isLoaded = false
        Task { await performFloorLoad(at: index) }
    }
    
    @MainActor
    private func reloadCurrentFloor() async {
        guard selectedFloorIndex >= 0, selectedFloorIndex < floors.count else { 
            print("⚠️ Cannot reload current floor, invalid index: \(selectedFloorIndex)")
            return 
        }
        print("🔄 Pull-to-refresh floor \(selectedFloorIndex): \(floors[selectedFloorIndex].name)")
        // Clear rooms and reload current floor
        floors[selectedFloorIndex].rooms = []
        floors[selectedFloorIndex].isLoaded = false
        await performFloorLoad(at: selectedFloorIndex)
    }
    
    @MainActor
    private func performInitialLoad() async {
        isInitialLoading = true
        errorMessage = nil
        
        let service = SmartRoomAPIService.shared
        
        do {
            // Load only floor list
            let loadedFloors = try await service.getFloors()
            floors = loadedFloors.map { ACFloor(from: $0) }
            isInitialLoading = false
            
            // Load first floor data
            if !floors.isEmpty {
                await performFloorLoad(at: 0)
            }
            
        } catch SmartRoomAPIError.tokenExpired {
            isInitialLoading = false
            errorMessage = "Phiên đăng nhập đã hết hạn"
        } catch {
            errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
            isInitialLoading = false
        }
    }
    
    @MainActor
    private func performFloorLoad(at index: Int) async {
        guard index >= 0, index < floors.count else { 
            print("⚠️ Invalid floor index: \(index), floors count: \(floors.count)")
            return 
        }
        
        isLoadingFloor = true
        let service = SmartRoomAPIService.shared
        let floorId = floors[index].id
        
        do {
            // Load rooms for this floor
            let rooms = try await service.getRoomsByFloor(floorId)
            
            // Load AC devices for each room
            var acRooms: [ACRoom] = []
            
            for room in rooms {
                let airConditions = try await service.getAirConditionsByRoom(room.id)
                let acDevices = airConditions.map { ACDevice(from: $0) }
                acRooms.append(ACRoom(from: room, devices: acDevices))
            }
            
            // Update floor with loaded data - ensure index is still valid
            if index >= 0 && index < floors.count {
                floors[index].rooms = acRooms
                floors[index].isLoaded = true
            }
            isLoadingFloor = false
            
        } catch {
            print("❌ Error loading floor \(index): \(error.localizedDescription)")
            isLoadingFloor = false
            // Could add per-floor error handling here if needed
        }
    }
}

// MARK: - Header View
struct ACHeaderView: View {
    var body: some View {
        HStack {
            Text("AC Control")
                .font(AppTypography.headlineMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Floor Tabs View
struct ACFloorTabsView: View {
    let floors: [ACFloor]
    @Binding var selectedIndex: Int
    let onTabTapped: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(floors.indices, id: \.self) { index in
                    ACTabItem(
                        title: floors[index].name,
                        isActive: selectedIndex == index,
                        onTap: {
                            onTabTapped(index)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 44)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                    .frame(height: 1)
            }
        )
    }
}

struct ACTabItem: View {
    let title: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isActive ? AppColors.primaryPurple : Color(red: 0.69, green: 0.65, blue: 0.82))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                
                if isActive {
                    Rectangle()
                        .fill(AppColors.primaryPurple)
                        .frame(height: 3)
                        .cornerRadius(3, corners: [.topLeft, .topRight])
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Room Card
struct ACRoomCard: View {
    @Binding var room: ACRoom
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(room.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if room.devices.isEmpty {
                        Text("Chưa có thiết bị")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text("\(room.activeDevicesCount) / \(room.devices.count) đang bật")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
                
                Spacer()
                
                Image(systemName: room.isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    room.isExpanded.toggle()
                }
            }
            
            // Device List
            if room.isExpanded {
                if room.devices.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "snowflake.slash")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Phòng này chưa có điều hòa")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 15) {
                        ForEach($room.devices) { $device in
                            ACDeviceRow(device: $device)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(AppColors.surfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Device Row
struct ACDeviceRow: View {
    @Binding var device: ACDevice
    @State private var isToggling: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Navigable area - Icon + Info
            NavigationLink(destination: ACDetailScreen(device: device)) {
                HStack(spacing: 15) {
                    // Icon Circle
                    ZStack {
                        Circle()
                            .fill(AppColors.surfaceWhite)
                            .frame(width: 45, height: 45)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "snowflake")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                    }
                    
                    // Device Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(device.temperature)°C • \(device.mode)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Toggle Switch - independent from NavigationLink
            ZStack {
                if isToggling {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Toggle("", isOn: Binding(
                        get: { device.isOn },
                        set: { newValue in
                            toggleDevice(newValue: newValue)
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.0, green: 0.48, blue: 1.0)))
                    .scaleEffect(0.9)
                    .disabled(isToggling)
                }
            }
            .frame(width: 51, height: 31)
        }
        .padding(15)
        .background(Color(red: 0.95, green: 0.96, blue: 1.0))
        .cornerRadius(15)
    }
    
    private func toggleDevice(newValue: Bool) {
        let previousState = device.isOn
        device.isOn = newValue
        isToggling = true
        
        Task {
            do {
                let power = newValue ? "ON" : "OFF"
                let updatedAC = try await SmartRoomAPIService.shared.updateAirCondition(device.id, power: power)
                
                // Update device with response from server
                await MainActor.run {
                    device.isOn = updatedAC.power == "ON"
                    device.temperature = updatedAC.temperature
                    device.mode = updatedAC.mode
                    isToggling = false
                }
            } catch {
                // Revert to previous state on error
                await MainActor.run {
                    device.isOn = previousState
                    isToggling = false
                }
                print("❌ Failed to toggle AC \(device.id): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Helper Extension for Rounded Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

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

#Preview {
    ACControlScreen()
}
