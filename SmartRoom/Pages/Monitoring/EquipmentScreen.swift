import SwiftUI

// MARK: - Equipment Models
struct Equipment: Identifiable {
    let id: Int
    let name: String
    let floorId: Int
    let roomId: Int
    let floorName: String
    let roomName: String
    let type: String
    var isSelected: Bool = false

    var locationText: String {
        "\(floorName) • \(roomName)"
    }
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
    @State private var showAddEquipmentSheet = false
    @State private var showDeleteConfirmation = false
    @State private var equipmentToDelete: Equipment?

    init(automationId: Int? = nil) {
        self.automationId = automationId
        _viewModel = StateObject(wrappedValue: EquipmentViewModel(automationId: automationId))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 6)

                        if viewModel.isLoading {
                            ManagementLoadingView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                        } else if let errorMessage = viewModel.errorMessage {
                            ManagementEmptyStateView(
                                icon: "exclamationmark.triangle",
                                message: errorMessage
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else if viewModel.selectedEquipments.isEmpty {
                            ManagementEmptyStateView(
                                icon: "bolt.horizontal.circle",
                                message: "Chưa có thiết bị hành động"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(viewModel.selectedEquipments) { equipment in
                                SelectedEquipmentCard(
                                    equipment: equipment,
                                    onDelete: {
                                        equipmentToDelete = equipment
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showAddEquipmentSheet) {
            AddEquipmentSheet(viewModel: viewModel)
        }
        .alert("Xác nhận xóa?", isPresented: $showDeleteConfirmation) {
            Button("Hủy", role: .cancel) {
                equipmentToDelete = nil
            }
            Button("Xóa", role: .destructive) {
                if let equipment = equipmentToDelete {
                    Task {
                        await deleteEquipment(equipment)
                        equipmentToDelete = nil
                    }
                }
            }
        } message: {
            if let equipment = equipmentToDelete {
                Text("Bạn có chắc chắn muốn xóa \"\(equipment.name)\" khỏi danh sách hành động?")
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }

            Spacer()

            Text("Equipment")
                .font(AppTypography.headlineMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button(action: {
                showAddEquipmentSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primaryPurple)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func deleteEquipment(_ equipment: Equipment) async {
        guard let automationId = automationId else { return }
        
        await viewModel.deleteEquipment(automationId: automationId, equipmentId: equipment.id)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.setEquipmentSelection(equipmentId: equipment.id, isSelected: false)
        }
    }
}

private struct SelectedEquipmentCard: View {
    let equipment: Equipment
    let onDelete: () -> Void

    private var iconName: String {
        equipment.type.uppercased().contains("LIGHT") ? "lightbulb.fill" : "switch.2"
    }

    private var iconTintColor: Color {
        equipment.type.uppercased().contains("LIGHT") ? Color(hex: 0xD97706) : AppColors.primaryPurple
    }

    private var iconBackgroundColor: Color {
        equipment.type.uppercased().contains("LIGHT") ? Color(hex: 0xFEF3C7) : AppColors.primaryPurple.opacity(0.12)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconBackgroundColor)
                    .frame(width: 46, height: 46)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconTintColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("Hành động:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text("ON")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.primaryPurple)
                }

                Text(equipment.locationText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: 0xDC2626))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: 0xFEE2E2))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.surfaceWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primaryPurple.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

private struct AddEquipmentSheet: View {
    @ObservedObject var viewModel: EquipmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 1
    @State private var selectedFloor: EquipmentFloor?
    @State private var selectedRoom: EquipmentRoom?
    @State private var selectedEquipment: Equipment?
    @State private var selectedAction = "ON"
    @State private var executionOrder = 1

    private let titles = ["Chọn Tầng", "Chọn Phòng", "Chọn Thiết bị", "Cấu hình"]
    
    private var availableFloorsWithEquipment: [EquipmentFloor] {
        viewModel.floors.filter { floor in
            floor.rooms.contains { room in
                room.equipments.contains { !$0.isSelected }
            }
        }
    }
    
    private var availableRoomsInSelectedFloor: [EquipmentRoom] {
        guard let floor = selectedFloor else { return [] }
        return floor.rooms.filter { room in
            room.equipments.contains { !$0.isSelected }
        }
    }
    
    private var availableEquipmentsInSelectedRoom: [Equipment] {
        guard let room = selectedRoom else { return [] }
        return room.equipments.filter { !$0.isSelected }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    progressBar
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 8)
                            
                            if currentStep == 1 {
                                step1FloorsView
                            } else if currentStep == 2 {
                                step2RoomsView
                            } else if currentStep == 3 {
                                step3EquipmentsView
                            } else if currentStep == 4 {
                                step4ConfigView
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle(titles[currentStep - 1])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if currentStep > 1 {
                            withAnimation {
                                currentStep -= 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(currentStep == 1 ? "Đóng" : "Quay lại")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...4, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? AppColors.primaryPurple : Color(hex: 0xE2E8F0))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Step 1: Floors
    private var step1FloorsView: some View {
        VStack(spacing: 12) {
            ForEach(availableFloorsWithEquipment) { floor in
                Button(action: {
                    selectedFloor = floor
                    withAnimation {
                        currentStep = 2
                    }
                }) {
                    HStack {
                        Text(floor.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: 0xD1D5DB))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surfaceWhite)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Step 2: Rooms
    private var step2RoomsView: some View {
        VStack(spacing: 12) {
            if let floor = selectedFloor {
                selectedBadge(label: "Tầng", value: floor.name)
            }
            
            ForEach(availableRoomsInSelectedFloor) { room in
                Button(action: {
                    selectedRoom = room
                    withAnimation {
                        currentStep = 3
                    }
                }) {
                    HStack {
                        Text(room.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: 0xD1D5DB))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surfaceWhite)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Step 3: Equipments
    private var step3EquipmentsView: some View {
        VStack(spacing: 12) {
            if let room = selectedRoom {
                selectedBadge(label: "Phòng", value: room.name)
            }
            
            ForEach(availableEquipmentsInSelectedRoom) { equipment in
                Button(action: {
                    selectedEquipment = equipment
                    withAnimation {
                        currentStep = 4
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(equipment.type.uppercased().contains("LIGHT") ?
                                      Color(hex: 0xFEF3C7) : AppColors.primaryPurple.opacity(0.12))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: equipment.type.uppercased().contains("LIGHT") ? "lightbulb.fill" : "switch.2")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(equipment.type.uppercased().contains("LIGHT") ?
                                                Color(hex: 0xD97706) : AppColors.primaryPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(equipment.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Device ID: \(equipment.id)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .textCase(.uppercase)
                        }
                        
                        Spacer()
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surfaceWhite)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Step 4: Configuration
    private var step4ConfigView: some View {
        VStack(spacing: 16) {
            if let equipment = selectedEquipment {
                selectedBadge(label: "Thiết bị", value: equipment.name)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trạng thái:")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedAction = "ON"
                        }) {
                            Text("BẬT (ON)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedAction == "ON" ?
                                                Color(hex: 0x059669) : Color(hex: 0x9CA3AF))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedAction == "ON" ?
                                             Color(hex: 0xECFDF5) : AppColors.surfaceWhite)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedAction == "ON" ?
                                                       Color(hex: 0x10B981) : Color(hex: 0xE5E7EB),
                                                       lineWidth: 2)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            selectedAction = "OFF"
                        }) {
                            Text("TẮT (OFF)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedAction == "OFF" ?
                                                Color(hex: 0x059669) : Color(hex: 0x9CA3AF))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedAction == "OFF" ?
                                             Color(hex: 0xECFDF5) : AppColors.surfaceWhite)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedAction == "OFF" ?
                                                       Color(hex: 0x10B981) : Color(hex: 0xE5E7EB),
                                                       lineWidth: 2)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("THỨ TỰ (ORDER)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("", value: $executionOrder, format: .number)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: 0xF9FAFB))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: 0xE5E7EB), lineWidth: 1)
                                )
                        )
                        .keyboardType(.numberPad)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.surfaceWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: 0xF1F1F1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            
            Button(action: completeConfiguration) {
                Text("Hoàn tất cấu hình")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.primaryPurple)
                    )
                    .shadow(color: AppColors.primaryPurple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func selectedBadge(label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(label):")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x059669))
                
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x059669))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x10B981))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xECFDF5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(Color(hex: 0x10B981))
                )
        )
    }
    
    private func completeConfiguration() {
        guard let equipment = selectedEquipment else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.setEquipmentSelection(equipmentId: equipment.id, isSelected: true)
        }
        
        dismiss()
    }
}

// MARK: - Equipment ViewModel
@MainActor
class EquipmentViewModel: ObservableObject {
    @Published var floors: [EquipmentFloor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = SmartRoomAPIService.shared
    private let automationId: Int?
    private var initialActions: [AutomationAction] = []

    init(automationId: Int? = nil) {
        self.automationId = automationId
    }

    var selectedEquipments: [Equipment] {
        allEquipments
            .filter { $0.isSelected }
            .sorted(by: sortEquipment)
    }

    var availableEquipments: [Equipment] {
        allEquipments
            .filter { !$0.isSelected }
            .sorted(by: sortEquipment)
    }

    private var allEquipments: [Equipment] {
        floors.flatMap { floor in
            floor.rooms.flatMap { room in
                room.equipments
            }
        }
    }

    private func sortEquipment(_ lhs: Equipment, _ rhs: Equipment) -> Bool {
        if lhs.floorName == rhs.floorName {
            if lhs.roomName == rhs.roomName {
                return lhs.name < rhs.name
            }
            return lhs.roomName < rhs.roomName
        }
        return lhs.floorName < rhs.floorName
    }

    func loadData() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let apiFloors = try await apiService.getFloors(page: 0, size: 50)
                let allLights = try await apiService.getAllLights(page: 0, size: 1000)

                var selectedLightIds = Set<Int>()
                if let automationId = automationId {
                    do {
                        let actions = try await apiService.getAutomationActions(automationId: automationId)
                        initialActions = actions
                        selectedLightIds = Set(actions.filter { $0.targetType == "LIGHT" }.map { $0.targetId })
                    } catch {
                        print("Error loading automation actions: \(error)")
                    }
                }

                var equipmentFloors: [EquipmentFloor] = []

                for apiFloor in apiFloors {
                    let apiRooms = try await apiService.getRoomsByFloor(apiFloor.id, page: 0, size: 50)
                    var equipmentRooms: [EquipmentRoom] = []

                    for apiRoom in apiRooms {
                        let roomLights = allLights.filter { $0.roomId == apiRoom.id }

                        let equipments = roomLights.map { light in
                            Equipment(
                                id: light.id,
                                name: light.name,
                                floorId: apiFloor.id,
                                roomId: apiRoom.id,
                                floorName: apiFloor.name,
                                roomName: apiRoom.name,
                                type: "LIGHT",
                                isSelected: selectedLightIds.contains(light.id)
                            )
                        }

                        if !equipments.isEmpty {
                            equipmentRooms.append(
                                EquipmentRoom(
                                    id: apiRoom.id,
                                    name: apiRoom.name,
                                    floorId: apiFloor.id,
                                    equipments: equipments
                                )
                            )
                        }
                    }

                    if !equipmentRooms.isEmpty {
                        equipmentFloors.append(
                            EquipmentFloor(
                                id: apiFloor.id,
                                name: apiFloor.name,
                                rooms: equipmentRooms
                            )
                        )
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

    func setEquipmentSelection(equipmentId: Int, isSelected: Bool) {
        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                if let equipmentIndex = floors[floorIndex].rooms[roomIndex].equipments.firstIndex(where: { $0.id == equipmentId }) {
                    floors[floorIndex].rooms[roomIndex].equipments[equipmentIndex].isSelected = isSelected
                    
                    // If adding, create the action immediately
                    if isSelected, let automationId = automationId {
                        Task {
                            await addEquipment(automationId: automationId, equipmentId: equipmentId)
                        }
                    }
                    return
                }
            }
        }
    }
    
    func addEquipment(automationId: Int, equipmentId: Int) async {
        do {
            _ = try await apiService.createAutomationAction(
                automationId: automationId,
                targetType: "LIGHT",
                targetId: equipmentId,
                actionType: "ON",
                parameterValue: nil,
                executionOrder: 0
            )
            
            // Refresh actions
            let refreshedActions = try await apiService.getAutomationActions(automationId: automationId)
            initialActions = refreshedActions
        } catch {
            print("Error adding equipment: \(error)")
            errorMessage = "Không thể thêm: \(error.localizedDescription)"
        }
    }
    
    func deleteEquipment(automationId: Int, equipmentId: Int) async {
        do {
            if let action = initialActions.first(where: { $0.targetType == "LIGHT" && $0.targetId == equipmentId }) {
                try await apiService.deleteAutomationAction(actionId: action.id)
                
                // Remove from initialActions
                initialActions.removeAll { $0.id == action.id }
            }
        } catch {
            print("Error deleting equipment: \(error)")
            errorMessage = "Không thể xóa: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        EquipmentScreen()
    }
}
