import SwiftUI

// MARK: - Rule Model
struct Rule: Identifiable {
    let id: Int
    var name: String
    var priority: Int
    var floor: String
    var deviceCategory: String // "LIGHT", "FAN", "AIR_CONDITION"
    var targetDeviceId: Int
    var room: String
    var device: String
    var currentDeviceInfo: [RuleDeviceInfo]
    var isEnabled: Bool
    var conditions: [RuleCondition]
    var actionSettings: ActionSettings
}

struct RuleDeviceInfo: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

// MARK: - Action Settings Model
struct ActionSettings: Equatable {
    // Common settings
    var power: Bool = false
    
    // LIGHT settings
    var brightness: Int = 50 // 0-100
    
    // FAN settings
    var fanMode: String = "NORMAL" // NORMAL, SLEEP, NATURAL
    var fanSpeed: Int = 3 // 0-5
    var fanSwing: Bool = false
    var fanLight: Bool = false
    
    // AIR_CONDITION settings
    var temperature: Int = 25 // 16-36
    var acMode: String = "COOL" // COOL, HEAT, DRY, FAN, AUTO
    var acFanSpeed: Int = 3 // 0-5
    var acSwing: Bool = false
}

// MARK: - Rule Condition Model
struct RuleCondition: Identifiable, Equatable {
    let id = UUID()
    var backendConditionId: Int? = nil
    var type: String // "Temperature", "Humidity", or custom
    var isCustomType: Bool = false
    var customTypeText: String = ""
    var dataSource: String = "SYSTEM" // SYSTEM, ROOM, DEVICE, SENSOR
    var propertyKey: String = "current_time"
    var conditionDeviceCategory: String = "FAN" // LIGHT, FAN, AIR_CONDITION
    var conditionFloor: String = ""
    var conditionRoom: String = ""
    var conditionTarget: String = "" // Device/Sensor name
    var operatorType: String // ">=", "<=", ">", "<", "=="
    var value: String
    var logicOperator: String = "AND" // "AND" or "OR" (used to connect to next condition)
}

// MARK: - Rules Screen
struct RulesScreen: View {
    @StateObject private var viewModel = RulesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddRuleSheet = false
    @State private var selectedRuleForEdit: Rule?
    @State private var showDeleteConfirmation = false
    @State private var ruleToDelete: Rule?
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 6)

                        if viewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                                    .scaleEffect(1.2)

                                Text("Loading rules...")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    )
                            )
                            .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 10, x: 0, y: 5)
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.red)

                                Text(errorMessage)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)

                                Button("Retry") {
                                    Task {
                                        await viewModel.loadRules()
                                    }
                                }
                                .font(AppTypography.titleMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(AppColors.primaryPurple)
                                .cornerRadius(12)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    )
                            )
                            .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 10, x: 0, y: 5)
                        } else if viewModel.rules.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.3))

                                Text("No rules yet")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)

                                Text("Create your first smart rule to automate your room.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                    )
                            )
                            .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 10, x: 0, y: 5)
                        } else {
                            ForEach(viewModel.rules) { rule in
                                RuleCard(
                                    rule: rule,
                                    onDelete: {
                                        ruleToDelete = rule
                                        showDeleteConfirmation = true
                                    },
                                    onEdit: {
                                        selectedRuleForEdit = rule
                                    }
                                )
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddRuleSheet, onDismiss: {
            Task {
                await viewModel.loadRules()
            }
        }) {
            RuleDetailSheet(onSave: { name, priority, floor, deviceCategory, room, device, conditions, actionSettings in
                viewModel.createRule(
                    name: name,
                    priority: priority,
                    floor: floor,
                    deviceCategory: deviceCategory,
                    room: room,
                    device: device,
                    conditions: conditions,
                    actionSettings: actionSettings
                )
            })
        }
        .sheet(item: $selectedRuleForEdit, onDismiss: {
            selectedRuleForEdit = nil
            Task {
                await viewModel.loadRules()
            }
        }) { rule in
            RuleDetailSheet(
                editMode: true,
                existingRule: rule,
                onSave: { name, priority, floor, deviceCategory, room, device, conditions, actionSettings in
                    viewModel.updateRule(
                        id: rule.id,
                        name: name,
                        priority: priority,
                        floor: floor,
                        deviceCategory: deviceCategory,
                        room: room,
                        device: device,
                        conditions: conditions,
                        actionSettings: actionSettings
                    )
                }
            )
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let rule = ruleToDelete {
                    viewModel.deleteRule(rule)
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                Text("Are you sure you want to delete rule '\(rule.name)'?")
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }

            Spacer()

            Text("Smart Rules")
                .font(AppTypography.headlineMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button(action: {
                showAddRuleSheet = true
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
}

// MARK: - Rule Card
struct RuleCard: View {
    let rule: Rule
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var isEnabled: Bool

    init(rule: Rule, onDelete: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.rule = rule
        self.onDelete = onDelete
        self.onEdit = onEdit
        _isEnabled = State(initialValue: rule.isEnabled)
    }

    private var iconName: String {
        switch rule.deviceCategory {
        case "LIGHT":
            return "lightbulb.fill"
        case "FAN":
            return "fanblades.fill"
        default:
            return "snowflake"
        }
    }

    private var targetText: String {
        "Device ID: \(rule.targetDeviceId) (Room: \(rule.room))"
    }

    private var actionTextColor: Color {
        rule.actionSettings.power ? Color(hex: 0x16A34A) : AppColors.textSecondary
    }

    private var actionSummaryText: String {
        let powerValue = onOff(rule.actionSettings.power)

        switch rule.deviceCategory {
        case "LIGHT":
            return "Lệnh: \(powerValue) | Mức: \(rule.actionSettings.brightness)%"
        case "FAN":
            return "Lệnh: \(powerValue) | Mode: \(rule.actionSettings.fanMode) | Speed: \(rule.actionSettings.fanSpeed)"
        default:
            return "Lệnh: \(powerValue) | Temp: \(rule.actionSettings.temperature)°C | Mode: \(rule.actionSettings.acMode)"
        }
    }

    private func onOff(_ value: Bool) -> String {
        value ? "ON" : "OFF"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppColors.primaryPurple.opacity(0.14))
                            .frame(width: 46, height: 46)

                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.primaryPurple)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)

                        Text("Priority: \(rule.priority) | Conditions: \(rule.conditions.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                            .textCase(.uppercase)
                    }
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(RuleSwitchToggleStyle(activeColor: AppColors.primaryPurple))
                    .padding(.top, 2)
            }

            VStack(spacing: 10) {
                RuleHighlightInfoRow(
                    label: "Target",
                    value: targetText,
                    valueColor: AppColors.textPrimary
                )

                RuleHighlightInfoRow(
                    label: "Action",
                    value: actionSummaryText,
                    valueColor: actionTextColor
                )
            }

            HStack {
                Spacer()

                HStack(spacing: 8) {
                    RuleCardIconButton(
                        systemName: "pencil",
                        foregroundColor: AppColors.primaryPurple,
                        backgroundColor: Color(hex: 0xF3E8FF),
                        action: onEdit
                    )

                    RuleCardIconButton(
                        systemName: "trash",
                        foregroundColor: Color(hex: 0xDC2626),
                        backgroundColor: Color(hex: 0xFEE2E2),
                        action: onDelete
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(isEnabled ? 0.92 : 0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.primaryPurple.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(
            color: AppColors.primaryPurple.opacity(isEnabled ? 0.16 : 0.08),
            radius: isEnabled ? 12 : 8,
            x: 0,
            y: isEnabled ? 7 : 4
        )
        .opacity(isEnabled ? 1 : 0.88)
    }
}

private struct RuleHighlightInfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xFDFCFF))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xF3F0FF), lineWidth: 1)
                )
        )
    }
}

private struct RuleCardIconButton: View {
    let systemName: String
    let foregroundColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct RuleSwitchToggleStyle: ToggleStyle {
    let activeColor: Color

    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) {
                configuration.isOn.toggle()
            }
        }) {
            RoundedRectangle(cornerRadius: 999)
                .fill(configuration.isOn ? activeColor : Color(hex: 0xD1D5DB))
                .frame(width: 50, height: 28)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(3)
                        .shadow(color: .black.opacity(0.16), radius: 2, x: 0, y: 1)
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Rules ViewModel
@MainActor
class RulesViewModel: ObservableObject {
    @Published var rules: [Rule] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService = SmartRoomAPIService.shared

    private struct RoomMeta {
        let roomName: String
        let floorName: String
    }

    private struct DeviceLookupKey: Hashable {
        let category: String
        let id: Int
    }

    private struct DevicePresentation {
        let name: String
        let currentInfoRows: [RuleDeviceInfo]
    }

    init() {
        Task {
            await loadRules()
        }
    }

    func loadRules() async {
        isLoading = true
        errorMessage = nil

        do {
            async let rulesTask = apiService.getAllRules()
            async let roomMetaTask = loadRoomMetaMap()

            let (apiRules, roomMetaMap) = try await (rulesTask, roomMetaTask)
            let deviceMap = await loadDevicePresentationMap(for: apiRules)

            rules = apiRules
                .map { mapAPIRuleToUIRule($0, roomMetaMap: roomMetaMap, deviceMap: deviceMap) }
                .sorted {
                    if $0.priority == $1.priority {
                        return $0.id < $1.id
                    }
                    return $0.priority > $1.priority
                }

            isLoading = false
        } catch SmartRoomAPIError.tokenExpired {
            isLoading = false
        } catch {
            errorMessage = "Failed to load rules: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func loadRoomMetaMap() async -> [Int: RoomMeta] {
        do {
            let floors = try await apiService.getFloors(page: 0, size: 200)
            var map: [Int: RoomMeta] = [:]

            for floor in floors {
                let rooms = try await apiService.getRoomsByFloor(floor.id, page: 0, size: 200)
                for room in rooms {
                    map[room.id] = RoomMeta(roomName: room.name, floorName: floor.name)
                }
            }

            return map
        } catch {
            // Rules can still render with roomId fallback if room metadata fails.
            return [:]
        }
    }

    private func loadDevicePresentationMap(for apiRules: [APIRule]) async -> [DeviceLookupKey: DevicePresentation] {
        var deviceMap: [DeviceLookupKey: DevicePresentation] = [:]

        for rule in apiRules {
            let normalizedCategory = normalizeDeviceCategory(rule.targetDeviceCategory)
            let key = DeviceLookupKey(category: normalizedCategory, id: rule.targetDeviceId)

            if deviceMap[key] != nil {
                continue
            }

            if let presentation = await fetchDevicePresentation(for: key) {
                deviceMap[key] = presentation
            }
        }

        return deviceMap
    }

    private func fetchDevicePresentation(for key: DeviceLookupKey) async -> DevicePresentation? {
        do {
            switch key.category {
            case "LIGHT":
                let light = try await apiService.getLightById(key.id)
                return DevicePresentation(
                    name: light.name,
                    currentInfoRows: [
                        RuleDeviceInfo(label: "Current Power", value: onOff(light.isActive)),
                        RuleDeviceInfo(label: "Current Level", value: "\(light.level ?? 0)%")
                    ]
                )

            case "FAN":
                let fan = try await apiService.getFanById(key.id)
                var rows: [RuleDeviceInfo] = [
                    RuleDeviceInfo(label: "Current Power", value: fan.power.uppercased())
                ]

                if let mode = fan.mode, !mode.isEmpty {
                    rows.append(RuleDeviceInfo(label: "Current Mode", value: mode.uppercased()))
                }
                if let speed = fan.speed {
                    rows.append(RuleDeviceInfo(label: "Current Speed", value: "\(speed)"))
                }
                if let swing = fan.swing, !swing.isEmpty {
                    rows.append(RuleDeviceInfo(label: "Current Swing", value: swing.uppercased()))
                }
                if let light = fan.light, !light.isEmpty {
                    rows.append(RuleDeviceInfo(label: "Current Light", value: light.uppercased()))
                }

                return DevicePresentation(name: fan.name, currentInfoRows: rows)

            case "AIR_CONDITION":
                let ac = try await apiService.getAirConditionById(key.id)
                return DevicePresentation(
                    name: ac.name,
                    currentInfoRows: [
                        RuleDeviceInfo(label: "Current Power", value: ac.power.uppercased()),
                        RuleDeviceInfo(label: "Current Temp", value: "\(ac.temperature)°C"),
                        RuleDeviceInfo(label: "Current Mode", value: ac.mode.uppercased()),
                        RuleDeviceInfo(label: "Current Fan Speed", value: "\(ac.fanSpeed)"),
                        RuleDeviceInfo(label: "Current Swing", value: ac.swing.uppercased())
                    ]
                )

            default:
                return nil
            }
        } catch {
            // If device detail API fails, rules still render with fallback device name.
            return nil
        }
    }

    private func normalizeDeviceCategory(_ raw: String) -> String {
        let upper = raw.uppercased()
        switch upper {
        case "AC", "AIR_CONDITION", "AIR-CONDITION":
            return "AIR_CONDITION"
        case "LIGHT":
            return "LIGHT"
        case "FAN":
            return "FAN"
        default:
            return upper
        }
    }

    private func onOff(_ value: Bool) -> String {
        value ? "ON" : "OFF"
    }

    private func mapAPIRuleToUIRule(
        _ apiRule: APIRule,
        roomMetaMap: [Int: RoomMeta],
        deviceMap: [DeviceLookupKey: DevicePresentation]
    ) -> Rule {
        let normalizedCategory = normalizeDeviceCategory(apiRule.targetDeviceCategory)
        let deviceKey = DeviceLookupKey(category: normalizedCategory, id: apiRule.targetDeviceId)
        let presentation = deviceMap[deviceKey]
        let roomMeta = roomMetaMap[apiRule.roomId]

        let floorDisplay = roomMeta?.floorName ?? "Unknown Floor"
        let roomDisplay = roomMeta?.roomName ?? "Room #\(apiRule.roomId)"
        let deviceDisplay = presentation?.name ?? "Device #\(apiRule.targetDeviceId)"

        let mappedConditions = mapConditions(
            apiRule.conditions,
            fallbackCategory: normalizedCategory,
            fallbackFloor: floorDisplay,
            fallbackRoom: roomDisplay,
            fallbackTarget: deviceDisplay
        )

        return Rule(
            id: apiRule.id,
            name: apiRule.name,
            priority: apiRule.priority,
            floor: floorDisplay,
            deviceCategory: normalizedCategory,
            targetDeviceId: apiRule.targetDeviceId,
            room: roomDisplay,
            device: deviceDisplay,
            currentDeviceInfo: presentation?.currentInfoRows ?? [],
            isEnabled: apiRule.isActive,
            conditions: mappedConditions,
            actionSettings: mapActionSettings(apiRule.actionParams, category: normalizedCategory)
        )
    }

    private func mapActionSettings(_ actionParams: [String: RuleJSONValue]?, category: String) -> ActionSettings {
        var settings = ActionSettings()

        if let powerRaw = actionParams?["power"] {
            settings.power = powerRaw.boolValue ?? false
        }

        switch category {
        case "LIGHT":
            if let brightness = actionParams?["brightness"]?.intValue ?? actionParams?["level"]?.intValue {
                settings.brightness = min(max(brightness, 0), 100)
            }

        case "FAN":
            if let mode = actionParams?["mode"]?.stringValue {
                settings.fanMode = mode.uppercased()
            }
            if let speed = actionParams?["speed"]?.intValue {
                settings.fanSpeed = min(max(speed, 0), 5)
            }
            if let swingRaw = actionParams?["swing"] {
                settings.fanSwing = swingRaw.boolValue ?? false
            }
            if let lightRaw = actionParams?["light"] {
                settings.fanLight = lightRaw.boolValue ?? false
            }

        default:
            if let temp = actionParams?["temp"]?.intValue ?? actionParams?["temperature"]?.intValue {
                settings.temperature = min(max(temp, 16), 36)
            }
            if let mode = actionParams?["mode"]?.stringValue {
                settings.acMode = mode.uppercased()
            }
            if let fanSpeed = actionParams?["fanSpeed"]?.intValue
                ?? actionParams?["fan_speed"]?.intValue
                ?? actionParams?["speed"]?.intValue {
                settings.acFanSpeed = min(max(fanSpeed, 0), 5)
            }
            if let swingRaw = actionParams?["swing"] {
                settings.acSwing = swingRaw.boolValue ?? false
            }
        }

        return settings
    }

    private func mapConditions(
        _ apiConditions: [APIRuleCondition]?,
        fallbackCategory: String,
        fallbackFloor: String,
        fallbackRoom: String,
        fallbackTarget: String
    ) -> [RuleCondition] {
        guard let apiConditions, !apiConditions.isEmpty else {
            return [
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

        let sorted = apiConditions.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        return sorted.map { apiCondition in
            mapSingleCondition(
                apiCondition,
                fallbackCategory: fallbackCategory,
                fallbackFloor: fallbackFloor,
                fallbackRoom: fallbackRoom,
                fallbackTarget: fallbackTarget
            )
        }
    }

    private func mapSingleCondition(
        _ apiCondition: APIRuleCondition,
        fallbackCategory: String,
        fallbackFloor: String,
        fallbackRoom: String,
        fallbackTarget: String
    ) -> RuleCondition {
        let source = apiCondition.dataSource.uppercased()
        let params = apiCondition.resourceParam ?? [:]

        let propertyKey = extractPropertyKey(from: params)
        let conditionCategory = extractCategory(from: params, source: source, fallback: fallbackCategory)
        let conditionFloor = extractFloor(from: params, source: source, fallback: fallbackFloor)
        let conditionRoom = extractRoom(from: params, source: source, fallback: fallbackRoom)
        let conditionTarget = extractTarget(from: params, source: source, fallback: fallbackTarget)
        let conditionValue = extractValue(from: apiCondition.value)

        return RuleCondition(
            backendConditionId: apiCondition.id,
            type: propertyKey.capitalized,
            isCustomType: false,
            customTypeText: "",
            dataSource: source,
            propertyKey: propertyKey,
            conditionDeviceCategory: conditionCategory,
            conditionFloor: conditionFloor,
            conditionRoom: conditionRoom,
            conditionTarget: conditionTarget,
            operatorType: normalizeOperator(apiCondition.operator),
            value: conditionValue,
            logicOperator: (apiCondition.nextLogic?.uppercased() ?? "AND")
        )
    }

    private func extractPropertyKey(from params: [String: RuleJSONValue]) -> String {
        params["property"]?.stringValue ?? params["metric"]?.stringValue ?? "current_time"
    }

    private func extractCategory(from params: [String: RuleJSONValue], source: String, fallback: String) -> String {
        params["deviceCategory"]?.stringValue?.uppercased() ?? fallback
    }

    private func extractFloor(from params: [String: RuleJSONValue], source: String, fallback: String) -> String {
        let isDeviceSource = source == "DEVICE" || source == "SENSOR"
        let fromParams = params["floor"]?.stringValue ?? params["floorName"]?.stringValue
        return fromParams ?? (isDeviceSource ? fallback : "")
    }

    private func extractRoom(from params: [String: RuleJSONValue], source: String, fallback: String) -> String {
        let isDeviceSource = source == "DEVICE" || source == "SENSOR"
        let fromParams = params["room"]?.stringValue ?? params["roomName"]?.stringValue
        return fromParams ?? (isDeviceSource ? fallback : "")
    }

    private func extractTarget(from params: [String: RuleJSONValue], source: String, fallback: String) -> String {
        let isDeviceSource = source == "DEVICE" || source == "SENSOR"
        let fromParams = params["device"]?.stringValue
            ?? params["deviceName"]?.stringValue
            ?? params["sensor"]?.stringValue
            ?? params["sensorName"]?.stringValue
            ?? params["target"]?.stringValue
        return fromParams ?? (isDeviceSource ? fallback : "")
    }

    private func extractValue(from jsonValue: RuleJSONValue) -> String {
        jsonValue.stringValue ?? jsonValue.intValue.map(String.init) ?? ""
    }

    private func normalizeOperator(_ rawOperator: String) -> String {
        switch rawOperator {
        case "==", "=", "!=", ">", "<", ">=", "<=":
            return rawOperator
        default:
            return "="
        }
    }
    
    func createRule(name: String, priority: Int, floor: String, deviceCategory: String, room: String, device: String, conditions: [RuleCondition], actionSettings: ActionSettings) {
        let newId = (rules.map { $0.id }.max() ?? 0) + 1
        let newRule = Rule(
            id: newId,
            name: name,
            priority: priority,
            floor: floor,
            deviceCategory: deviceCategory,
            targetDeviceId: extractDeviceId(from: device),
            room: room,
            device: device,
            currentDeviceInfo: [],
            isEnabled: true,
            conditions: conditions,
            actionSettings: actionSettings
        )
        rules.append(newRule)
        // TODO: Call API to create rule
        print("Created rule: \(name) with \(conditions.count) conditions")
    }
    
    func updateRule(id: Int, name: String, priority: Int, floor: String, deviceCategory: String, room: String, device: String, conditions: [RuleCondition], actionSettings: ActionSettings) {
        if let index = rules.firstIndex(where: { $0.id == id }) {
            rules[index].name = name
            rules[index].priority = priority
            rules[index].floor = floor
            rules[index].deviceCategory = deviceCategory
            rules[index].targetDeviceId = extractDeviceId(from: device)
            rules[index].room = room
            rules[index].device = device
            rules[index].currentDeviceInfo = []
            rules[index].conditions = conditions
            rules[index].actionSettings = actionSettings
            // TODO: Call API to update rule
            print("Updated rule: \(name)")
        }
    }

    private func extractDeviceId(from device: String) -> Int {
        let digits = device.filter { $0.isNumber }
        return Int(digits) ?? 0
    }
    
    func deleteRule(_ rule: Rule) {
        Task {
            do {
                try await apiService.deleteRule(id: rule.id)
                rules.removeAll { $0.id == rule.id }
            } catch {
                errorMessage = "Failed to delete rule: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        RulesScreen()
    }
}
