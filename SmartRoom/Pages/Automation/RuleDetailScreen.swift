import SwiftUI

// MARK: - Rule Detail Sheet
struct RuleDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RuleDetailViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    init(editMode: Bool = false, existingRule: Rule? = nil, onSave: @escaping (String, Int, String, String, String, String, [RuleCondition], ActionSettings) -> Void) {
        _viewModel = StateObject(wrappedValue: RuleDetailViewModel(
            editMode: editMode,
            existingRule: existingRule,
            onSave: onSave
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                
                // Content - Scrollable
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 8)
                        
                        // GENERAL INFORMATION SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            Text("GENERAL INFORMATION")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 16) {
                                // Rule Name
                                FormField(label: "Rule name") {
                                    TextField("Enter rule name...", text: $viewModel.ruleName)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceWhite))
                                        )
                                }
                                
                                // Priority & Floor
                                HStack(spacing: 16) {
                                    FormField(label: "Priority") {
                                        Menu {
                                            ForEach(1...10, id: \.self) { priority in
                                                Button("\(priority)") {
                                                    viewModel.priority = priority
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text("\(viewModel.priority)")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textPrimary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceWhite))
                                            )
                                        }
                                    }
                                    
                                    FormField(label: "Floor") {
                                        Menu {
                                            if viewModel.isLoadingFloors {
                                                Text("Loading floors...")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textSecondary)
                                            } else if viewModel.floorOptions.isEmpty {
                                                Text("No floors found")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textSecondary)
                                            } else {
                                                ForEach(viewModel.floorOptions, id: \.self) { floorName in
                                                    Button(floorName) {
                                                        viewModel.floor = floorName
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(viewModel.floor.isEmpty ? "Select floor..." : viewModel.floor)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(viewModel.floor.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceWhite))
                                            )
                                        }
                                        .disabled(viewModel.floorOptions.isEmpty && !viewModel.isLoadingFloors)
                                    }
                                }
                                
                                // Device Category
                                FormField(label: "Device Category") {
                                    Menu {
                                        Button("LIGHT") {
                                            viewModel.deviceCategory = "LIGHT"
                                        }
                                        Button("FAN") {
                                            viewModel.deviceCategory = "FAN"
                                        }
                                        Button("AIR_CONDITION") {
                                            viewModel.deviceCategory = "AIR_CONDITION"
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.deviceCategory)
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceWhite))
                                        )
                                    }
                                }
                                
                                // Room & Device
                                // Room
                                FormField(label: "Room") {
                                    Menu {
                                        if viewModel.isLoadingRooms {
                                            Text("Loading rooms...")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else if viewModel.floor.isEmpty {
                                            Text("Select Floor first")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else if viewModel.availableRooms.isEmpty {
                                            Text("No rooms found")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else {
                                            ForEach(viewModel.availableRooms, id: \.self) { room in
                                                Button(room) {
                                                    viewModel.room = room
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.room.isEmpty ? "Select room..." : viewModel.room)
                                                .font(.system(size: 14))
                                                .foregroundColor(viewModel.room.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.availableRooms.isEmpty ? Color(hex: 0xF8F8F8) : AppColors.surfaceWhite))
                                        )
                                    }
                                    .disabled(viewModel.floor.isEmpty || (viewModel.availableRooms.isEmpty && !viewModel.isLoadingRooms))
                                }
                                
                                // Device
                                FormField(label: "Device") {
                                    Menu {
                                        if viewModel.isLoadingDevices {
                                            Text("Loading devices...")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else if viewModel.room.isEmpty {
                                            Text("Select Room first")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else if viewModel.availableDevices.isEmpty {
                                            Text("No devices found for selected category")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        } else {
                                            ForEach(viewModel.availableDevices, id: \.self) { deviceName in
                                                Button(deviceName) {
                                                    viewModel.selectDevice(named: deviceName)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.device.isEmpty ? "Select device..." : viewModel.device)
                                                .font(.system(size: 14))
                                                .foregroundColor(viewModel.device.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.availableDevices.isEmpty ? Color(hex: 0xF8F8F8) : AppColors.surfaceWhite))
                                        )
                                    }
                                    .disabled(viewModel.room.isEmpty || (viewModel.availableDevices.isEmpty && !viewModel.isLoadingDevices))
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.surfaceLight.opacity(0.3))
                            )
                        }
                        
                        // ACTION SETTINGS SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ACTION SETTINGS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, 4)
                            
                            VStack(spacing: 16) {
                                // Common: Power
                                FormField(label: "Power") {
                                    HStack(spacing: 12) {
                                        PowerButton(title: "ON", isSelected: viewModel.actionSettings.power) {
                                            viewModel.actionSettings.power = true
                                        }
                                        PowerButton(title: "OFF", isSelected: !viewModel.actionSettings.power) {
                                            viewModel.actionSettings.power = false
                                        }
                                    }
                                }
                                
                                // Device-specific settings
                                if viewModel.deviceCategory == "LIGHT" {
                                    LightSettingsView(actionSettings: $viewModel.actionSettings)
                                } else if viewModel.deviceCategory == "FAN" {
                                    FanSettingsView(actionSettings: $viewModel.actionSettings)
                                } else if viewModel.deviceCategory == "AIR_CONDITION" {
                                    ACSettingsView(actionSettings: $viewModel.actionSettings)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppColors.surfaceLight.opacity(0.3))
                            )
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(AppColors.surfaceLight.opacity(0.5))
                            .frame(height: 1)
                        
                        // Conditions Section (Old conditions if needed)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CONDITIONS (Optional)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, 4)
                            
                            ForEach(Array(viewModel.conditions.enumerated()), id: \.element.id) { index, condition in
                                VStack(spacing: 8) {
                                    ConditionCard(
                                        condition: $viewModel.conditions[index],
                                        index: index,
                                        onDelete: index > 0 ? { viewModel.removeCondition(at: index) } : nil
                                    )
                                }
                            }
                            
                            Button(action: {
                                viewModel.addCondition()
                            }) {
                                Text("+ Add new condition")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.primaryPurple)
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer().frame(height: 16)
                        
                        // Save Button
                        Button(action: {
                            isLoading = true
                            Task {
                                let success = await viewModel.saveRuleToAPI()
                                isLoading = false
                                if success {
                                    dismiss()
                                } else {
                                    errorMessage = viewModel.saveErrorMessage ?? "Failed to save rule. Please try again."
                                    showErrorAlert = true
                                }
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 48)
                            } else {
                                Text("Save")
                                    .font(AppTypography.titleMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .background(
                            viewModel.canSave && !isLoading
                                ? AppColors.primaryPurple
                                : AppColors.textSecondary.opacity(0.3)
                        )
                        .cornerRadius(12)
                        .disabled(!viewModel.canSave || isLoading)
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Rule Detail" : "New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("Retry", role: .none) {
                    // User can retry by clicking Save again
                }
                Button("Dismiss", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

// MARK: - Form Field
struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)
            content
        }
    }
}

// MARK: - Power Button
struct PowerButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppColors.primaryPurple : Color(hex: 0xF1F5F9))
                )
        }
    }
}

// MARK: - Light Settings View
struct LightSettingsView: View {
    @Binding var actionSettings: ActionSettings
    
    var body: some View {
        VStack(spacing: 16) {
            FormField(label: "Brightness (0-100)") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(actionSettings.brightness) },
                        set: { actionSettings.brightness = Int($0) }
                    ), in: 0...100, step: 1)
                    .accentColor(AppColors.primaryPurple)
                    
                    Text("\(actionSettings.brightness)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF1F5F9))
                        )
                }
            }
        }
    }
}

// MARK: - Fan Settings View
struct FanSettingsView: View {
    @Binding var actionSettings: ActionSettings
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode
            FormField(label: "Mode") {
                HStack(spacing: 8) {
                    ModeButton(title: "NORMAL", isSelected: actionSettings.fanMode == "NORMAL") {
                        actionSettings.fanMode = "NORMAL"
                    }
                    ModeButton(title: "SLEEP", isSelected: actionSettings.fanMode == "SLEEP") {
                        actionSettings.fanMode = "SLEEP"
                    }
                    ModeButton(title: "NATURAL", isSelected: actionSettings.fanMode == "NATURAL") {
                        actionSettings.fanMode = "NATURAL"
                    }
                }
            }
            
            // Speed
            FormField(label: "Speed (0-5)") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(actionSettings.fanSpeed) },
                        set: { actionSettings.fanSpeed = Int($0) }
                    ), in: 0...5, step: 1)
                    .accentColor(AppColors.primaryPurple)
                    
                    Text("\(actionSettings.fanSpeed)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF1F5F9))
                        )
                }
            }
            
            // Swing
            FormField(label: "Swing") {
                HStack(spacing: 12) {
                    PowerButton(title: "ON", isSelected: actionSettings.fanSwing) {
                        actionSettings.fanSwing = true
                    }
                    PowerButton(title: "OFF", isSelected: !actionSettings.fanSwing) {
                        actionSettings.fanSwing = false
                    }
                }
            }
            
            // Light
            FormField(label: "Light") {
                HStack(spacing: 12) {
                    PowerButton(title: "ON", isSelected: actionSettings.fanLight) {
                        actionSettings.fanLight = true
                    }
                    PowerButton(title: "OFF", isSelected: !actionSettings.fanLight) {
                        actionSettings.fanLight = false
                    }
                }
            }
        }
    }
}

// MARK: - AC Settings View
struct ACSettingsView: View {
    @Binding var actionSettings: ActionSettings
    
    var body: some View {
        VStack(spacing: 16) {
            // Temperature
            FormField(label: "Temperature (16-36°C)") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(actionSettings.temperature) },
                        set: { actionSettings.temperature = Int($0) }
                    ), in: 16...36, step: 1)
                    .accentColor(AppColors.primaryPurple)
                    
                    Text("\(actionSettings.temperature)°C")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 60)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF1F5F9))
                        )
                }
            }
            
            // Mode
            FormField(label: "Mode") {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ModeButton(title: "COOL", isSelected: actionSettings.acMode == "COOL") {
                            actionSettings.acMode = "COOL"
                        }
                        ModeButton(title: "HEAT", isSelected: actionSettings.acMode == "HEAT") {
                            actionSettings.acMode = "HEAT"
                        }
                        ModeButton(title: "DRY", isSelected: actionSettings.acMode == "DRY") {
                            actionSettings.acMode = "DRY"
                        }
                    }
                    HStack(spacing: 8) {
                        ModeButton(title: "FAN", isSelected: actionSettings.acMode == "FAN") {
                            actionSettings.acMode = "FAN"
                        }
                        ModeButton(title: "AUTO", isSelected: actionSettings.acMode == "AUTO") {
                            actionSettings.acMode = "AUTO"
                        }
                    }
                }
            }
            
            // Fan Speed
            FormField(label: "Fan Speed (0-5)") {
                HStack {
                    Slider(value: Binding(
                        get: { Double(actionSettings.acFanSpeed) },
                        set: { actionSettings.acFanSpeed = Int($0) }
                    ), in: 0...5, step: 1)
                    .accentColor(AppColors.primaryPurple)
                    
                    Text("\(actionSettings.acFanSpeed)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: 0xF1F5F9))
                        )
                }
            }
            
            // Swing
            FormField(label: "Swing") {
                HStack(spacing: 12) {
                    PowerButton(title: "ON", isSelected: actionSettings.acSwing) {
                        actionSettings.acSwing = true
                    }
                    PowerButton(title: "OFF", isSelected: !actionSettings.acSwing) {
                        actionSettings.acSwing = false
                    }
                }
            }
        }
    }
}

// MARK: - Mode Button
struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppColors.primaryPurple : Color(hex: 0xF1F5F9))
                )
        }
    }
}

// MARK: - Condition Card
struct ConditionCard: View {
    @Binding var condition: RuleCondition
    let index: Int
    let onDelete: (() -> Void)?

    private let sourceOptions = ["SYSTEM", "ROOM", "DEVICE", "SENSOR"]
    private let deviceCategoryOptions = ["LIGHT", "FAN", "AIR_CONDITION"]
    private let sensorCategoryOptions = ["TEMPERATURE", "HUMIDITY", "POWER"]
    private let floorOptions = ["Ground Floor", "Floor 1", "Floor 2", "Floor 3"]

    private let systemPropertyOptions: [(key: String, label: String)] = [
        ("current_time", "current_time (hours + min/60)"),
        ("day_of_week", "day_of_week (1=Mon ... 7=Sun)"),
        ("day_of_month", "day_of_month (1-31)")
    ]

    private let roomPropertyOptions: [(key: String, label: String)] = [
        ("avg_temperature", "avg_temperature (°C)"),
        ("sum_watt", "sum_watt (Watt)")
    ]

    private let devicePropertyOptionsByCategory: [String: [(key: String, label: String)]] = [
        "LIGHT": [
            ("power", "power"),
            ("brightness", "brightness")
        ],
        "FAN": [
            ("power", "power"),
            ("mode", "mode"),
            ("speed", "speed"),
            ("swing", "swing"),
            ("light", "light")
        ],
        "AIR_CONDITION": [
            ("power", "power"),
            ("temperature", "temperature"),
            ("mode", "mode"),
            ("fan_speed", "fan_speed"),
            ("swing", "swing")
        ]
    ]

    private let sensorPropertyOptionsByCategory: [String: [(key: String, label: String)]] = [
        "TEMPERATURE": [
            ("temperature", "temperature")
        ],
        "HUMIDITY": [
            ("humidity", "humidity")
        ],
        "POWER": [
            ("sum_watt", "sum_watt"),
            ("power", "power")
        ]
    ]

    private let roomsByFloor: [String: [String]] = [
        "Ground Floor": ["Central Server Room", "Main Lobby", "Living Room"],
        "Floor 1": ["Meeting Room A", "Meeting Room B", "Room 101"],
        "Floor 2": ["Room 201", "Room 202", "Room 203"],
        "Floor 3": ["Room 301", "Room 302", "Room 303"]
    ]

    private let targetsByRoomAndCategory: [String: [String: [String]]] = [
        "Central Server Room": [
            "LIGHT": ["Central Ceiling Light (#1)", "Technical Light (#2)"],
            "FAN": ["Standing Fan (#1)", "Server Ceiling Fan (#2)"],
            "AIR_CONDITION": ["Central AC (#1)"]
        ],
        "Main Lobby": [
            "LIGHT": ["Lobby Light (#1)", "Entrance Light (#2)"],
            "FAN": ["Lobby Fan (#1)"],
            "AIR_CONDITION": ["Lobby AC (#1)"]
        ],
        "Living Room": [
            "LIGHT": ["Living Room Light (#1)", "Table Light (#2)"],
            "FAN": ["Living Room Fan (#1)"],
            "AIR_CONDITION": ["Living Room AC (#1)"]
        ],
        "Meeting Room A": [
            "LIGHT": ["Meeting Room A Light (#1)", "Projector Light (#2)"],
            "FAN": ["Meeting Room A Fan (#1)"],
            "AIR_CONDITION": ["Meeting Room A AC (#1)"]
        ],
        "Meeting Room B": [
            "LIGHT": ["Meeting Room B Light (#1)"],
            "FAN": ["Meeting Room B Fan (#1)"],
            "AIR_CONDITION": ["Meeting Room B AC (#1)"]
        ],
        "Room 101": [
            "LIGHT": ["Room 101 Light (#1)"],
            "FAN": ["Room 101 Fan (#1)"],
            "AIR_CONDITION": ["Room 101 AC (#1)"]
        ],
        "Room 201": [
            "LIGHT": ["Room 201 Light (#1)"],
            "FAN": ["Room 201 Fan (#1)"],
            "AIR_CONDITION": ["Room 201 AC (#1)"]
        ],
        "Room 202": [
            "LIGHT": ["Room 202 Light (#1)"],
            "FAN": ["Room 202 Fan (#1)"],
            "AIR_CONDITION": ["Room 202 AC (#1)"]
        ],
        "Room 203": [
            "LIGHT": ["Room 203 Light (#1)"],
            "FAN": ["Room 203 Fan (#1)"],
            "AIR_CONDITION": ["Room 203 AC (#1)"]
        ],
        "Room 301": [
            "LIGHT": ["Room 301 Light (#1)"],
            "FAN": ["Room 301 Fan (#1)"],
            "AIR_CONDITION": ["Room 301 AC (#1)"]
        ],
        "Room 302": [
            "LIGHT": ["Room 302 Light (#1)"],
            "FAN": ["Room 302 Fan (#1)"],
            "AIR_CONDITION": ["Room 302 AC (#1)"]
        ],
        "Room 303": [
            "LIGHT": ["Room 303 Light (#1)"],
            "FAN": ["Room 303 Fan (#1)"],
            "AIR_CONDITION": ["Room 303 AC (#1)"]
        ]
    ]

    private let sensorTargetsByCategory: [String: [String]] = [
        "TEMPERATURE": ["Temperature Sensor (#50)", "Temperature Sensor (#51)"],
        "HUMIDITY": ["Humidity Sensor (#60)", "Humidity Sensor (#61)"],
        "POWER": ["Power Sensor (#70)", "Power Sensor (#71)"]
    ]

    private var sourcePropertyOptions: [(key: String, label: String)] {
        switch condition.dataSource {
        case "SYSTEM":
            return systemPropertyOptions
        case "ROOM":
            return roomPropertyOptions
        case "DEVICE":
            return devicePropertyOptionsByCategory[condition.conditionDeviceCategory] ?? []
        case "SENSOR":
            return sensorPropertyOptionsByCategory[condition.conditionDeviceCategory] ?? []
        default:
            return []
        }
    }

    private var sourceCategoryOptions: [String] {
        condition.dataSource == "SENSOR" ? sensorCategoryOptions : deviceCategoryOptions
    }

    private var availableRooms: [String] {
        guard !condition.conditionFloor.isEmpty else { return [] }
        return roomsByFloor[condition.conditionFloor] ?? []
    }

    private var availableTargets: [String] {
        guard !condition.conditionRoom.isEmpty else { return [] }

        if condition.dataSource == "SENSOR" {
            return sensorTargetsByCategory[condition.conditionDeviceCategory] ?? []
        }

        return targetsByRoomAndCategory[condition.conditionRoom]?[condition.conditionDeviceCategory] ?? []
    }

    private var selectedPropertyLabel: String {
        sourcePropertyOptions.first(where: { $0.key == condition.propertyKey })?.label ?? "Select property"
    }

    private var selectedOperatorLabel: String {
        switch condition.operatorType {
        case "==", "=": return "= (equal)"
        case "!=": return "!= (not equal)"
        case ">": return ">"
        case "<": return "<"
        case ">=": return ">="
        case "<=": return "<="
        default: return condition.operatorType
        }
    }

    private func defaultProperty(for source: String, category: String) -> String {
        switch source {
        case "SYSTEM":
            return systemPropertyOptions.first?.key ?? ""
        case "ROOM":
            return roomPropertyOptions.first?.key ?? ""
        case "DEVICE":
            return devicePropertyOptionsByCategory[category]?.first?.key ?? ""
        case "SENSOR":
            return sensorPropertyOptionsByCategory[category]?.first?.key ?? ""
        default:
            return ""
        }
    }

    private func defaultCategory(for source: String) -> String {
        switch source {
        case "DEVICE":
            return deviceCategoryOptions.first ?? ""
        case "SENSOR":
            return sensorCategoryOptions.first ?? ""
        default:
            return ""
        }
    }

    @ViewBuilder
    private func menuLabel(_ text: String, isPlaceholder: Bool = false, disabled: Bool = false) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isPlaceholder ? AppColors.textSecondary : AppColors.textPrimary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0xCBD5E1), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(disabled ? Color(hex: 0xF8FAFC) : AppColors.surfaceWhite)
                )
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Condition \(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primaryPurple)

                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            // Data Source
            VStack(alignment: .leading, spacing: 12) {
                Text("Data Source")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x16A34A))

                FormField(label: "Data Source") {
                    Menu {
                        ForEach(sourceOptions, id: \.self) { source in
                            Button(source) {
                                condition.dataSource = source
                                if source == "DEVICE" || source == "SENSOR" {
                                    condition.conditionDeviceCategory = defaultCategory(for: source)
                                }
                                condition.propertyKey = defaultProperty(for: source, category: condition.conditionDeviceCategory)
                                if source == "SYSTEM" || source == "ROOM" {
                                    condition.conditionFloor = ""
                                    condition.conditionRoom = ""
                                    condition.conditionTarget = ""
                                } else {
                                    condition.conditionFloor = ""
                                    condition.conditionRoom = ""
                                    condition.conditionTarget = ""
                                }
                            }
                        }
                    } label: {
                        menuLabel(condition.dataSource)
                    }
                }

                if condition.dataSource == "SYSTEM" || condition.dataSource == "ROOM" {
                    FormField(label: "Property") {
                        Menu {
                            ForEach(sourcePropertyOptions, id: \.key) { property in
                                Button(property.label) {
                                    condition.propertyKey = property.key
                                }
                            }
                        } label: {
                            menuLabel(selectedPropertyLabel, isPlaceholder: condition.propertyKey.isEmpty)
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        FormField(label: condition.dataSource == "SENSOR" ? "Sensor Category" : "Device Category") {
                            Menu {
                                Button("-- not set --") {
                                    condition.conditionDeviceCategory = ""
                                    condition.propertyKey = ""
                                    condition.conditionTarget = ""
                                }
                                ForEach(sourceCategoryOptions, id: \.self) { category in
                                    Button(category) {
                                        condition.conditionDeviceCategory = category
                                        condition.propertyKey = defaultProperty(for: condition.dataSource, category: category)
                                        condition.conditionTarget = ""
                                    }
                                }
                            } label: {
                                menuLabel(
                                    condition.conditionDeviceCategory.isEmpty ? "-- not set --" : condition.conditionDeviceCategory,
                                    isPlaceholder: condition.conditionDeviceCategory.isEmpty
                                )
                            }
                        }

                        FormField(label: "Property") {
                            Menu {
                                ForEach(sourcePropertyOptions, id: \.key) { property in
                                    Button(property.label) {
                                        condition.propertyKey = property.key
                                    }
                                }
                            } label: {
                                menuLabel(selectedPropertyLabel, isPlaceholder: condition.propertyKey.isEmpty)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        FormField(label: "Floor") {
                            Menu {
                                Button("-- not set --") {
                                    condition.conditionFloor = ""
                                    condition.conditionRoom = ""
                                    condition.conditionTarget = ""
                                }
                                ForEach(floorOptions, id: \.self) { floor in
                                    Button(floor) {
                                        condition.conditionFloor = floor
                                        condition.conditionRoom = ""
                                        condition.conditionTarget = ""
                                    }
                                }
                            } label: {
                                menuLabel(
                                    condition.conditionFloor.isEmpty ? "-- not set --" : condition.conditionFloor,
                                    isPlaceholder: condition.conditionFloor.isEmpty
                                )
                            }
                        }

                        FormField(label: "Room") {
                            Menu {
                                Button("-- not set --") {
                                    condition.conditionRoom = ""
                                    condition.conditionTarget = ""
                                }
                                if !availableRooms.isEmpty {
                                    ForEach(availableRooms, id: \.self) { room in
                                        Button(room) {
                                            condition.conditionRoom = room
                                            condition.conditionTarget = ""
                                        }
                                    }
                                }
                            } label: {
                                menuLabel(
                                    condition.conditionRoom.isEmpty ? "-- not set --" : condition.conditionRoom,
                                    isPlaceholder: condition.conditionRoom.isEmpty
                                )
                            }
                        }
                    }

                    FormField(label: "Device / Sensor") {
                        Menu {
                            Button("-- not set --") {
                                condition.conditionTarget = ""
                            }
                            if !availableTargets.isEmpty {
                                ForEach(availableTargets, id: \.self) { target in
                                    Button(target) {
                                        condition.conditionTarget = target
                                    }
                                }
                            }
                        } label: {
                            menuLabel(
                                condition.conditionTarget.isEmpty ? "-- not set --" : condition.conditionTarget,
                                isPlaceholder: condition.conditionTarget.isEmpty
                            )
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surfaceWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0x16A34A).opacity(0.3), lineWidth: 1)
                    )
            )

            // Operator & Value
            VStack(alignment: .leading, spacing: 12) {
                Text("Operator & Value")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xEAB308))

                HStack(spacing: 10) {
                    FormField(label: "Operator") {
                        Menu {
                            Button("= (equal)") {
                                condition.operatorType = "="
                            }
                            Button("!= (not equal)") {
                                condition.operatorType = "!="
                            }
                            Button(">") {
                                condition.operatorType = ">"
                            }
                            Button("<") {
                                condition.operatorType = "<"
                            }
                            Button(">=") {
                                condition.operatorType = ">="
                            }
                            Button("<=") {
                                condition.operatorType = "<="
                            }
                        } label: {
                            menuLabel(selectedOperatorLabel)
                        }
                    }

                    FormField(label: "Comparison Value") {
                        TextField("30", text: $condition.value)
                            .font(.system(size: 14))
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: 0xCBD5E1), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.surfaceWhite))
                            )
                    }
                }

                FormField(label: "Next Logic Connector") {
                    Menu {
                        Button("AND") {
                            condition.logicOperator = "AND"
                        }
                        Button("OR") {
                            condition.logicOperator = "OR"
                        }
                    } label: {
                        menuLabel(condition.logicOperator)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surfaceWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0xEAB308).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surfaceLight.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.surfaceLight, lineWidth: 1)
                )
        )
    }
}

// MARK: - Rule Detail ViewModel
@MainActor
class RuleDetailViewModel: ObservableObject {
    @Published var ruleName: String = ""
    @Published var priority: Int = 5
    @Published var floor: String = "" {
        didSet {
            guard floor != oldValue else { return }
            room = ""
            device = ""
            selectedDeviceId = nil
            Task {
                await loadRoomsForSelectedFloor()
            }
        }
    }
    @Published var deviceCategory: String = "LIGHT" {
        didSet {
            guard deviceCategory != oldValue else { return }
            device = ""
            selectedDeviceId = nil
            syncSelectedDeviceIfNeeded()
        }
    }
    @Published var room: String = "" {
        didSet {
            guard room != oldValue else { return }
            device = ""
            selectedDeviceId = nil
            Task {
                await loadDevicesForSelectedRoom()
            }
        }
    }
    @Published var device: String = ""
    @Published var selectedDeviceId: Int?
    @Published var conditions: [RuleCondition] = []
    @Published var actionSettings: ActionSettings = ActionSettings()
    @Published var floorOptions: [String] = []
    @Published var isLoadingFloors = false
    @Published var isLoadingRooms = false
    @Published var isLoadingDevices = false
    @Published var saveErrorMessage: String?
    
    let isEditMode: Bool
    private let apiService = SmartRoomAPIService.shared
    private let editingRuleId: Int?
    private var floors: [Floor] = []
    private var roomsByFloorId: [Int: [Room]] = [:]
    private var devicesByRoomId: [Int: [Device]] = [:]

    private var selectedFloorId: Int? {
        floors.first(where: { $0.name == floor })?.id
    }

    private var selectedRoomId: Int? {
        guard let floorId = selectedFloorId else { return nil }
        return roomsByFloorId[floorId]?.first(where: { $0.name == room })?.id
    }
    
    // Computed property for available rooms based on selected floor
    var availableRooms: [String] {
        guard let floorId = selectedFloorId else { return [] }
        return roomsByFloorId[floorId, default: []].map { $0.name }
    }
    
    // Computed property for available devices based on selected room and device category
    var availableDevices: [String] {
        filteredDevicesForCurrentSelection().map(deviceDisplayName)
    }
    let onSave: (String, Int, String, String, String, String, [RuleCondition], ActionSettings) -> Void
    
    init(editMode: Bool = false, existingRule: Rule? = nil, onSave: @escaping (String, Int, String, String, String, String, [RuleCondition], ActionSettings) -> Void) {
        self.isEditMode = editMode
        self.onSave = onSave
        self.editingRuleId = existingRule?.id
        
        if let rule = existingRule {
            // Load existing rule data
            self.ruleName = rule.name
            self.priority = rule.priority
            self.floor = rule.floor
            self.deviceCategory = rule.deviceCategory
            self.room = rule.room
            self.device = rule.device
            self.selectedDeviceId = rule.targetDeviceId
            self.conditions = rule.conditions
            self.actionSettings = rule.actionSettings
        } else {
            // Initialize with at least one condition
            self.conditions = [
                RuleCondition(
                    type: "Temperature",
                    isCustomType: false,
                    dataSource: "SYSTEM",
                    propertyKey: "current_time",
                    operatorType: "=",
                    value: "30"
                )
            ]
        }

        Task {
            await loadInitialLocationData()
        }
    }

    func selectDevice(named deviceName: String) {
        device = deviceName
        selectedDeviceId = findDevice(for: deviceName)?.id
    }

    private func loadInitialLocationData() async {
        await loadFloors()
        if !floor.isEmpty {
            await loadRoomsForSelectedFloor()
        }
        if !room.isEmpty {
            await loadDevicesForSelectedRoom()
        }
    }

    private func loadFloors() async {
        isLoadingFloors = true
        defer { isLoadingFloors = false }

        do {
            let fetched = try await apiService.getFloors(page: 0, size: 200)
            floors = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            floorOptions = floors.map { $0.name }
        } catch {
            floorOptions = []
            print("Failed to load floors: \(error.localizedDescription)")
        }
    }

    private func loadRoomsForSelectedFloor() async {
        guard let floorId = selectedFloorId else {
            return
        }

        if roomsByFloorId[floorId] != nil {
            if !room.isEmpty && !availableRooms.contains(room) {
                room = ""
            }
            return
        }

        isLoadingRooms = true
        defer { isLoadingRooms = false }

        do {
            let fetched = try await apiService.getRoomsByFloor(floorId, page: 0, size: 200)
            roomsByFloorId[floorId] = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            if !room.isEmpty && !availableRooms.contains(room) {
                room = ""
            }
        } catch {
            roomsByFloorId[floorId] = []
            print("Failed to load rooms for floor \(floorId): \(error.localizedDescription)")
        }
    }

    private func loadDevicesForSelectedRoom() async {
        guard let roomId = selectedRoomId else {
            return
        }

        if devicesByRoomId[roomId] != nil {
            syncSelectedDeviceIfNeeded()
            return
        }

        isLoadingDevices = true
        defer { isLoadingDevices = false }

        do {
            let fetched = try await apiService.getDevicesByRoom(roomId)
            devicesByRoomId[roomId] = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            syncSelectedDeviceIfNeeded()
        } catch {
            devicesByRoomId[roomId] = []
            print("Failed to load devices for room \(roomId): \(error.localizedDescription)")
        }
    }

    private func filteredDevicesForCurrentSelection() -> [Device] {
        guard let roomId = selectedRoomId else { return [] }

        let normalizedCategory = normalizeCategory(deviceCategory)
        return devicesByRoomId[roomId, default: []].filter {
            normalizeCategory($0.category) == normalizedCategory
        }
    }

    private func findDevice(for displayValue: String) -> Device? {
        let trimmed = displayValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedId = extractDeviceId(from: trimmed)

        return filteredDevicesForCurrentSelection().first { device in
            if let parsedId, device.id == parsedId {
                return true
            }
            return deviceDisplayName(device) == trimmed || device.name == trimmed
        }
    }

    private func deviceDisplayName(_ device: Device) -> String {
        "\(device.name) (#\(device.id))"
    }

    private func syncSelectedDeviceIfNeeded() {
        guard !device.isEmpty || selectedDeviceId != nil else { return }

        if let selectedDeviceId,
           let matchedById = filteredDevicesForCurrentSelection().first(where: { $0.id == selectedDeviceId }) {
            device = deviceDisplayName(matchedById)
            return
        }

        if let matchedByName = findDevice(for: device) {
            selectedDeviceId = matchedByName.id
            device = deviceDisplayName(matchedByName)
            return
        }

        device = ""
        selectedDeviceId = nil
    }

    private func normalizeCategory(_ rawCategory: String) -> String {
        switch rawCategory.uppercased() {
        case "AC", "AIR_CONDITION", "AIR-CONDITION":
            return "AIR_CONDITION"
        case "LIGHT":
            return "LIGHT"
        case "FAN":
            return "FAN"
        default:
            return rawCategory.uppercased()
        }
    }
    
    var canSave: Bool {
        let hasTargetDevice = selectedDeviceId != nil || extractDeviceId(from: device) != nil
        let hasRequiredRoomForCreate = isEditMode || selectedRoomId != nil

        return !ruleName.isEmpty &&
            hasTargetDevice &&
            hasRequiredRoomForCreate &&
            !conditions.isEmpty &&
            conditions.allSatisfy { condition in
                guard !condition.propertyKey.isEmpty && !condition.value.isEmpty else {
                    return false
                }
                let source = condition.dataSource.uppercased()
                if source == "DEVICE" || source == "SENSOR" {
                    guard !condition.conditionFloor.isEmpty,
                          !condition.conditionRoom.isEmpty,
                          !condition.conditionTarget.isEmpty else {
                        return false
                    }

                    // Backend condition payload expects concrete id for DEVICE/SENSOR resources.
                    if source == "SENSOR" {
                        return extractDeviceId(from: condition.conditionTarget) != nil
                    }

                    return extractDeviceId(from: condition.conditionTarget) != nil || selectedDeviceId != nil
                }
                return true
            }
    }
    
    func addCondition() {
        let newCondition = RuleCondition(
            type: "Temperature",
            isCustomType: false,
            dataSource: "SYSTEM",
            propertyKey: "current_time",
            operatorType: "=",
            value: "30"
        )
        conditions.append(newCondition)
    }
    
    func removeCondition(at index: Int) {
        guard index > 0 && index < conditions.count else { return }
        conditions.remove(at: index)
    }
    
    func toggleLogicOperator(at index: Int) {
        guard index < conditions.count else { return }
        conditions[index].logicOperator = conditions[index].logicOperator == "AND" ? "OR" : "AND"
    }
    
    func buildCreateRuleRequest() -> CreateRuleRequest? {
        guard let roomId = selectedRoomId else {
            print("Error: Could not resolve room ID for room \(room)")
            return nil
        }

        guard let targetDeviceId = selectedDeviceId ?? extractDeviceId(from: device) else {
            print("Error: Could not extract device ID from \(device)")
            return nil
        }

        let normalizedCategory = normalizeCategory(deviceCategory)
        let actionParams = buildActionParams(from: actionSettings, category: normalizedCategory)
        let apiConditions = buildCreateConditionRequests()

        return CreateRuleRequest(
            name: ruleName,
            priority: priority,
            roomId: roomId,
            targetDeviceId: targetDeviceId,
            targetDeviceCategory: normalizedCategory,
            actionParams: actionParams,
            isActive: true,
            conditions: apiConditions
        )
    }

    func buildUpdateRuleRequest() -> UpdateRuleRequest? {
        guard let targetDeviceId = selectedDeviceId ?? extractDeviceId(from: device) else {
            print("Error: Could not extract device ID from \(device)")
            return nil
        }

        let normalizedCategory = normalizeCategory(deviceCategory)
        let actionParams = buildActionParams(from: actionSettings, category: normalizedCategory)
        let apiConditions = buildUpdateConditionRequests()

        return UpdateRuleRequest(
            name: ruleName,
            priority: priority,
            targetDeviceId: targetDeviceId,
            targetDeviceCategory: normalizedCategory,
            actionParams: actionParams,
            isActive: true,
            conditions: apiConditions
        )
    }

    private func buildCreateConditionRequests() -> [CreateRuleConditionRequest] {
        conditions.enumerated().map { index, condition in
            let normalizedSource = condition.dataSource.uppercased()
            return CreateRuleConditionRequest(
                sortOrder: index,
                dataSource: normalizedSource,
                resourceParam: buildResourceParam(from: condition),
                operator: normalizedComparisonOperator(condition.operatorType),
                value: condition.value,
                nextLogic: normalizedNextLogic(for: condition, at: index)
            )
        }
    }

    private func buildUpdateConditionRequests() -> [UpdateRuleConditionRequest] {
        conditions.enumerated().map { index, condition in
            let normalizedSource = condition.dataSource.uppercased()
            return UpdateRuleConditionRequest(
                id: condition.backendConditionId,
                sortOrder: index,
                dataSource: normalizedSource,
                resourceParam: buildResourceParam(from: condition),
                operator: normalizedComparisonOperator(condition.operatorType),
                value: condition.value,
                nextLogic: normalizedNextLogic(for: condition, at: index)
            )
        }
    }

    private func normalizedNextLogic(for condition: RuleCondition, at index: Int) -> String? {
        guard index < conditions.count - 1 else {
            return nil
        }

        let next = condition.logicOperator.uppercased()
        return (next == "AND" || next == "OR") ? next : "AND"
    }

    private func normalizedComparisonOperator(_ rawOperator: String) -> String {
        switch rawOperator {
        case "==", "=":
            return "="
        case "!=", ">", "<", ">=", "<=":
            return rawOperator
        default:
            return "="
        }
    }
    
    private func extractDeviceId(from deviceString: String) -> Int? {
        let trimmed = deviceString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let hashRange = trimmed.range(of: "#", options: .backwards),
           let trailingId = Int(trimmed[hashRange.upperBound...].filter { $0.isNumber }) {
            return trailingId
        }

        if let devicePrefixRange = trimmed.range(of: "Device #", options: .caseInsensitive),
           let fallbackId = Int(trimmed[devicePrefixRange.upperBound...].filter { $0.isNumber }) {
            return fallbackId
        }

        let allDigits = trimmed.filter { $0.isNumber }
        if let id = Int(allDigits) {
            return id
        }

        return nil
    }
    
    private func buildActionParams(from settings: ActionSettings, category: String) -> [String: RuleJSONValue] {
        var params: [String: RuleJSONValue] = [:]
        
        params["power"] = .string(onOffString(settings.power))
        
        switch category {
        case "LIGHT":
            params["brightness"] = .int(settings.brightness)
            
        case "FAN":
            params["mode"] = .string(settings.fanMode.uppercased())
            params["speed"] = .int(settings.fanSpeed)
            params["swing"] = .string(onOffString(settings.fanSwing))
            params["light"] = .string(onOffString(settings.fanLight))
            
        default: // AIR_CONDITION
            // Backend rule action contract expects `temp` for AC target.
            params["temp"] = .int(settings.temperature)
            params["mode"] = .string(settings.acMode.uppercased())
            params["fanSpeed"] = .int(settings.acFanSpeed)
            params["swing"] = .string(onOffString(settings.acSwing))
        }
        
        return params
    }

    private func onOffString(_ value: Bool) -> String {
        value ? "ON" : "OFF"
    }

    private func inferredSensorCategory(for condition: RuleCondition) -> String {
        let property = condition.propertyKey.lowercased()
        if property.contains("temp") {
            return "TEMPERATURE"
        }
        if property.contains("humid") {
            return "HUMIDITY"
        }
        if property.contains("watt") || property.contains("power") {
            return "POWER"
        }

        let fallback = condition.conditionDeviceCategory.uppercased()
        return fallback.isEmpty ? "TEMPERATURE" : fallback
    }
    
    private func buildResourceParam(from condition: RuleCondition) -> [String: RuleJSONValue] {
        var params: [String: RuleJSONValue] = [:]
        let source = condition.dataSource.uppercased()
        
        if !condition.propertyKey.isEmpty {
            params["property"] = .string(condition.propertyKey)
        }

        switch source {
        case "DEVICE":
            params["category"] = .string(normalizeCategory(condition.conditionDeviceCategory))
            if let deviceId = selectedDeviceId ?? extractDeviceId(from: condition.conditionTarget) {
                params["deviceId"] = .int(deviceId)
            }

        case "SENSOR":
            params["category"] = .string(inferredSensorCategory(for: condition))
            if let sensorId = extractDeviceId(from: condition.conditionTarget) {
                params["sensorId"] = .int(sensorId)
            }

        case "SYSTEM", "ROOM":
            break

        default:
            break
        }
        
        return params
    }

    private struct BackendErrorBody: Decodable {
        let message: String?
        let errors: [String]?
    }

    private func userFriendlyErrorMessage(from error: Error) -> String {
        guard let apiError = error as? SmartRoomAPIError else {
            return error.localizedDescription
        }

        switch apiError {
        case .tokenExpired:
            return "Session expired. Please login again."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let message):
            return message
        case .networkError(let message):
            if let parsed = parseBackendErrorMessage(from: message) {
                return parsed
            }
            return message
        }
    }

    private func parseBackendErrorMessage(from rawMessage: String) -> String? {
        guard let jsonStart = rawMessage.firstIndex(of: "{") else {
            return nil
        }

        let jsonString = String(rawMessage[jsonStart...])
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(BackendErrorBody.self, from: data) else {
            return nil
        }

        if let errors = decoded.errors, !errors.isEmpty {
            return errors.joined(separator: "\n")
        }
        return decoded.message
    }
    
    func saveRuleToAPI() async -> Bool {
        saveErrorMessage = nil

        do {
            if isEditMode {
                guard let ruleId = editingRuleId else {
                    saveErrorMessage = "Missing rule ID for update."
                    return false
                }
                guard let request = buildUpdateRuleRequest() else {
                    saveErrorMessage = "Failed to build update request."
                    return false
                }
                _ = try await apiService.updateRule(id: ruleId, request)
            } else {
                guard let request = buildCreateRuleRequest() else {
                    saveErrorMessage = "Failed to build create request."
                    return false
                }
                let _ = try await apiService.createRule(request)
            }
            
            print("Rule saved successfully")
            return true
        } catch {
            saveErrorMessage = userFriendlyErrorMessage(from: error)
            print("Error saving rule: \(error.localizedDescription)")
            return false
        }
    }
    
    func saveRule() {
        onSave(ruleName, priority, floor, deviceCategory, room, device, conditions, actionSettings)
    }
}

// MARK: - Preview
#Preview {
    RuleDetailSheet(onSave: { name, priority, floor, deviceCategory, room, device, conditions, actionSettings in
        print("Saved: \(name), Priority: \(priority), Floor: \(floor)")
        print("Device Category: \(deviceCategory), Room: \(room), Device: \(device)")
        print("Conditions: \(conditions.count)")
    })
}
