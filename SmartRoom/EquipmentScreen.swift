import SwiftUI

// MARK: - Equipment Models
struct Equipment: Identifiable {
    let id: Int
    let name: String
    let floorId: Int
    let roomId: Int
    let type: String
    var isSelected: Bool = false
}

struct EquipmentRoom: Identifiable {
    let id: Int
    let name: String
    let floorId: Int
    var equipments: [Equipment]
}

struct EquipmentFloor: Identifiable {
    let id: Int
    let name: String
    var rooms: [EquipmentRoom]
}

// MARK: - Equipment Screen
struct EquipmentScreen: View {
    let automationId: Int?
    @StateObject private var viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    
    init(automationId: Int? = nil) {
        self.automationId = automationId
        _viewModel = StateObject(wrappedValue: EquipmentViewModel(automationId: automationId))
    }
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { 
                        if viewModel.hasChanges() {
                            showExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: 0x999999))
                    }
                    
                    Spacer()
                    
                    Text("Equipment")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: 0x666666))
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await viewModel.saveSelection()
                            dismiss()
                        }
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.appBackground)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.isLoading {
                            ManagementLoadingView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                        } else if let errorMessage = viewModel.errorMessage {
                            ManagementEmptyStateView(
                                icon: "exclamationmark.triangle",
                                message: errorMessage
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else if viewModel.floors.isEmpty {
                            ManagementEmptyStateView(
                                icon: "lightbulb.slash",
                                message: "Không có thiết bị nào"
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                        } else {
                            ForEach(viewModel.floors.indices, id: \.self) { floorIndex in
                            FloorSection(
                                floor: viewModel.floors[floorIndex],
                                isExpanded: viewModel.expandedFloors.contains(floorIndex),
                                expandedRooms: viewModel.expandedRooms,
                                onFloorToggle: {
                                    viewModel.toggleFloor(floorIndex)
                                },
                                onRoomToggle: { roomIndex in
                                    viewModel.toggleRoom(roomIndex)
                                },
                                onEquipmentToggle: { roomIndex, equipmentIndex in
                                    viewModel.toggleEquipment(floorIndex: floorIndex, roomIndex: roomIndex, equipmentIndex: equipmentIndex)
                                }
                            )
                            }
                        }
                        
                        Spacer().frame(height: 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadData()
        }
        .alert("Thông báo", isPresented: $showExitConfirmation) {
            Button("Có", role: .cancel) {
                // Stay on the page to continue editing
            }
            Button("Không", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Đã có sự thay đổi, bạn có muốn tiếp tục sửa không?")
        }
    }
}

// MARK: - Floor Section
struct FloorSection: View {
    let floor: EquipmentFloor
    let isExpanded: Bool
    let expandedRooms: Set<Int>
    let onFloorToggle: () -> Void
    let onRoomToggle: (Int) -> Void
    let onEquipmentToggle: (Int, Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Floor Header
            Button(action: onFloorToggle) {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    
                    Text(floor.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: 0xF5F5F5))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Rooms (if expanded)
            if isExpanded {
                ForEach(floor.rooms.indices, id: \.self) { roomIndex in
                    RoomSection(
                        room: floor.rooms[roomIndex],
                        isExpanded: expandedRooms.contains(floor.rooms[roomIndex].id),
                        onRoomToggle: {
                            onRoomToggle(floor.rooms[roomIndex].id)
                        },
                        onEquipmentToggle: { equipmentIndex in
                            onEquipmentToggle(roomIndex, equipmentIndex)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Room Section
struct RoomSection: View {
    let room: EquipmentRoom
    let isExpanded: Bool
    let onRoomToggle: () -> Void
    let onEquipmentToggle: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Room Header
            Button(action: onRoomToggle) {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        .padding(.leading, 16)
                    
                    Text(room.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: 0xFAFAFA))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Equipments (if expanded)
            if isExpanded {
                ForEach(room.equipments.indices, id: \.self) { equipmentIndex in
                    EquipmentRow(
                        equipment: room.equipments[equipmentIndex],
                        onToggle: {
                            onEquipmentToggle(equipmentIndex)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Equipment Row
struct EquipmentRow: View {
    let equipment: Equipment
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: equipment.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(equipment.isSelected ? AppColors.primaryPurple : Color(hex: 0xCCCCCC))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(equipment.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(equipment.type)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                equipment.isSelected ? 
                AppColors.primaryPurple.opacity(0.05) : 
                AppColors.surfaceWhite
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Equipment ViewModel
@MainActor
class EquipmentViewModel: ObservableObject {
    @Published var floors: [EquipmentFloor] = []
    @Published var expandedFloors: Set<Int> = []
    @Published var expandedRooms: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = SmartRoomAPIService.shared
    private let automationId: Int?
    private var initialActions: [AutomationAction] = [] // Store initial actions
    
    init(automationId: Int? = nil) {
        self.automationId = automationId
    }
    
    func loadData() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // 1. Fetch all floors
                let apiFloors = try await apiService.getFloors(page: 0, size: 50)
                
                // 2. Fetch all lights
                let allLights = try await apiService.getAllLights(page: 0, size: 1000)
                
                // 3. Fetch automation actions if automationId is provided
                var selectedLightIds = Set<Int>()
                if let automationId = automationId {
                    do {
                        let actions = try await apiService.getAutomationActions(automationId: automationId)
                        initialActions = actions // Store for comparison on save
                        selectedLightIds = Set(actions.filter { $0.targetType == "LIGHT" }.map { $0.targetId })
                        print("Loaded \(selectedLightIds.count) selected lights from automation \(automationId)")
                    } catch {
                        print("Error loading automation actions: \(error)")
                        // Continue without pre-selection if actions fail to load
                    }
                }
                
                // 4. For each floor, fetch rooms and build the hierarchy
                var equipmentFloors: [EquipmentFloor] = []
                
                for apiFloor in apiFloors {
                    // Fetch rooms for this floor
                    let apiRooms = try await apiService.getRoomsByFloor(apiFloor.id, page: 0, size: 50)
                    
                    // Build equipment rooms
                    var equipmentRooms: [EquipmentRoom] = []
                    
                    for apiRoom in apiRooms {
                        // Filter lights for this room
                        let roomLights = allLights.filter { $0.roomId == apiRoom.id }
                        
                        // Convert lights to Equipment
                        let equipments = roomLights.map { light in
                            Equipment(
                                id: light.id,
                                name: light.name,
                                floorId: apiFloor.id,
                                roomId: apiRoom.id,
                                type: "Light",
                                isSelected: selectedLightIds.contains(light.id)
                            )
                        }
                        
                        if !equipments.isEmpty {
                            equipmentRooms.append(EquipmentRoom(
                                id: apiRoom.id,
                                name: apiRoom.name,
                                floorId: apiFloor.id,
                                equipments: equipments
                            ))
                        }
                    }
                    
                    if !equipmentRooms.isEmpty {
                        equipmentFloors.append(EquipmentFloor(
                            id: apiFloor.id,
                            name: apiFloor.name,
                            rooms: equipmentRooms
                        ))
                    }
                }
                
                floors = equipmentFloors
                isLoading = false
            } catch {
                errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
                isLoading = false
                print("Error loading equipment data: \(error)")
            }
        }
    }
    
    func toggleFloor(_ index: Int) {
        if expandedFloors.contains(index) {
            expandedFloors.remove(index)
        } else {
            expandedFloors.insert(index)
        }
    }
    
    func toggleRoom(_ roomId: Int) {
        if expandedRooms.contains(roomId) {
            expandedRooms.remove(roomId)
        } else {
            expandedRooms.insert(roomId)
        }
    }
    
    func toggleEquipment(floorIndex: Int, roomIndex: Int, equipmentIndex: Int) {
        floors[floorIndex].rooms[roomIndex].equipments[equipmentIndex].isSelected.toggle()
    }
    
    func hasChanges() -> Bool {
        // Get currently selected light IDs
        let selectedEquipments = floors.flatMap { floor in
            floor.rooms.flatMap { room in
                room.equipments.filter { $0.isSelected }
            }
        }
        let currentSelectedIds = Set(selectedEquipments.map { $0.id })
        
        // Get initially selected light IDs (from loaded actions)
        let initialSelectedIds = Set(initialActions.filter { $0.targetType == "LIGHT" }.map { $0.targetId })
        
        // Check if there are any differences
        return currentSelectedIds != initialSelectedIds
    }
    
    func saveSelection() async {
        guard let automationId = automationId else {
            print("No automation ID provided, cannot save")
            return
        }
        
        // Get currently selected light IDs
        let selectedEquipments = floors.flatMap { floor in
            floor.rooms.flatMap { room in
                room.equipments.filter { $0.isSelected }
            }
        }
        let currentSelectedIds = Set(selectedEquipments.map { $0.id })
        
        // Get initially selected light IDs (from loaded actions)
        let initialSelectedIds = Set(initialActions.filter { $0.targetType == "LIGHT" }.map { $0.targetId })
        
        // Find lights to add (newly selected)
        let lightsToAdd = currentSelectedIds.subtracting(initialSelectedIds)
        
        // Find lights to remove (unselected)
        let lightsToRemove = initialSelectedIds.subtracting(currentSelectedIds)
        
        print("Saving selection for automation \(automationId)")
        print("Adding \(lightsToAdd.count) lights: \(lightsToAdd)")
        print("Removing \(lightsToRemove.count) lights: \(lightsToRemove)")
        
        do {
            // Delete actions for unselected lights
            for lightId in lightsToRemove {
                if let action = initialActions.first(where: { $0.targetType == "LIGHT" && $0.targetId == lightId }) {
                    try await apiService.deleteAutomationAction(actionId: action.id)
                    print("Deleted action \(action.id) for light \(lightId)")
                }
            }
            
            // Create actions for newly selected lights
            for lightId in lightsToAdd {
                let _ = try await apiService.createAutomationAction(
                    automationId: automationId,
                    targetType: "LIGHT",
                    targetId: lightId,
                    actionType: "ON",
                    parameterValue: nil,
                    executionOrder: 0
                )
                print("Created action for light \(lightId)")
            }
            
            print("✅ Successfully saved equipment selection")
        } catch {
            print("❌ Error saving equipment selection: \(error)")
            errorMessage = "Không thể lưu: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        EquipmentScreen()
    }
}
