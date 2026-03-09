import SwiftUI

// MARK: - Automation Job Model
struct AutomationJob: Identifiable {
    let id: Int
    let jobName: String
    let cronExpression: String
    let isActive: Bool
    let description: String?
    let equipments: [String]

    init(from apiAutomation: APIAutomation, equipments: [String]) {
        self.id = apiAutomation.id
        self.jobName = apiAutomation.name
        self.cronExpression = apiAutomation.cronExpression
        self.isActive = apiAutomation.isActive
        self.description = apiAutomation.description
        self.equipments = equipments
    }

    private var normalizedCron: (minute: String, hour: String, day: String, month: String, weekday: String)? {
        let parts = cronExpression.split(separator: " ").map(String.init)

        if parts.count >= 6 {
            return (parts[1], parts[2], parts[3], parts[4], parts[5])
        }

        if parts.count == 5 {
            return (parts[0], parts[1], parts[2], parts[3], parts[4])
        }

        return nil
    }

    // Helper to convert cron expression to readable schedule
    var scheduleText: String {
        guard let cron = normalizedCron else { return cronExpression }

        if cron.day == "*" && cron.weekday != "*" && cron.weekday != "?" {
            return "Hằng tuần (\(getWeekdayName(cron.weekday)))"
        }

        if cron.day == "?" && cron.weekday != "*" && cron.weekday != "?" {
            return "Hằng tuần (\(getWeekdayName(cron.weekday)))"
        }

        if cron.day != "*" && cron.day != "?" {
            return "Hằng tháng (Ngày \(cron.day))"
        }

        if (cron.day == "*" || cron.day == "?") && (cron.weekday == "*" || cron.weekday == "?") {
            return "Hằng ngày"
        }

        return cronExpression
    }

    var timeText: String {
        guard let cron = normalizedCron else { return "--:--" }

        if let hour = Int(cron.hour), let minute = Int(cron.minute) {
            return String(format: "%02d:%02d", hour, minute)
        }

        return "\(cron.hour):\(cron.minute)"
    }

    var scheduleDetailText: String {
        "\(scheduleText) lúc \(timeText)"
    }

    var scheduleIconName: String {
        if scheduleText.contains("Hằng tuần") {
            return "calendar.badge.clock"
        }

        if scheduleText.contains("Hằng tháng") {
            return "calendar.badge.clock"
        }

        return "calendar.badge.checkmark"
    }

    var equipmentSummaryText: String {
        let count = equipments.count
        return count == 1 ? "1 Equipment Controlled" : "\(count) Equipment Controlled"
    }

    private func getWeekdayName(_ weekday: String) -> String {
        switch weekday.uppercased() {
        case "MON", "1": return "T2"
        case "TUE", "2": return "T3"
        case "WED", "3": return "T4"
        case "THU", "4": return "T5"
        case "FRI", "5": return "T6"
        case "SAT", "6": return "T7"
        case "SUN", "0", "7": return "CN"
        default: return weekday
        }
    }
}

// MARK: - Automation Screen
struct AutomationScreen: View {
    @StateObject private var viewModel = AutomationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddAutomationSheet = false
    @State private var navigateToEquipment = false
    @State private var selectedJobForEquipment: AutomationJob?
    @State private var selectedJobForEdit: AutomationJob?
    @State private var showDeleteConfirmation = false
    @State private var jobToDelete: AutomationJob?

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                NavigationLink(
                    destination: EquipmentScreen(automationId: selectedJobForEquipment?.id)
                        .id(selectedJobForEquipment?.id ?? 0),
                    isActive: $navigateToEquipment
                ) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .opacity(0)

                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 6)

                        if viewModel.isLoading {
                            ManagementLoadingView()
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 14) {
                                Text("Error")
                                    .font(AppTypography.titleMedium)
                                    .foregroundColor(.red)

                                Text(error)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)

                                Button("Retry") {
                                    Task {
                                        await viewModel.loadJobs()
                                    }
                                }
                                .font(AppTypography.titleMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(AppColors.primaryPurple)
                                .cornerRadius(10)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.92))
                            )
                        } else if viewModel.jobs.isEmpty {
                            ManagementEmptyStateView(
                                icon: "wand.and.stars",
                                message: "No automation jobs yet"
                            )
                        } else {
                            ForEach(viewModel.jobs) { job in
                                AutomationJobCard(
                                    job: job,
                                    onDelete: {
                                        jobToDelete = job
                                        showDeleteConfirmation = true
                                    },
                                    onEdit: {
                                        selectedJobForEdit = job
                                    },
                                    onAddEquipments: {
                                        selectedJobForEquipment = job
                                        navigateToEquipment = true
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
        .onAppear {
            Task {
                await viewModel.loadJobs()
            }
        }
        .onChange(of: navigateToEquipment) { newValue in
            // Reset selectedJobForEquipment when returning from EquipmentScreen
            if !newValue {
                selectedJobForEquipment = nil
            }
        }
        .sheet(isPresented: $showAddAutomationSheet) {
            AddAutomationSheet(onAdd: { name, cronExpression, isActive, description in
                Task {
                    await viewModel.createAutomation(
                        name: name,
                        cronExpression: cronExpression,
                        isActive: isActive,
                        description: description
                    )
                }
            })
        }
        .sheet(item: $selectedJobForEdit, onDismiss: {
            selectedJobForEdit = nil
        }) { job in
            AddAutomationSheet(
                editMode: true,
                existingJob: job,
                onAdd: { name, cronExpression, isActive, description in
                    Task {
                        await viewModel.updateAutomation(
                            id: job.id,
                            name: name,
                            cronExpression: cronExpression,
                            isActive: isActive,
                            description: description
                        )
                    }
                }
            )
        }
        .alert("Xác nhận xóa", isPresented: $showDeleteConfirmation) {
            Button("Xóa", role: .destructive) {
                if let job = jobToDelete {
                    Task {
                        await viewModel.deleteJob(job)
                    }
                }
            }
            Button("Hủy", role: .cancel) {
                jobToDelete = nil
            }
        } message: {
            if let job = jobToDelete {
                Text("Bạn có chắc chắn muốn xóa automation '\(job.jobName)' không?")
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

            Text("Automation")
                .font(AppTypography.headlineMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button(action: {
                showAddAutomationSheet = true
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

// MARK: - Automation Job Card
struct AutomationJobCard: View {
    let job: AutomationJob
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onAddEquipments: () -> Void
    @State private var isEnabled: Bool

    init(job: AutomationJob, onDelete: @escaping () -> Void, onEdit: @escaping () -> Void, onAddEquipments: @escaping () -> Void) {
        self.job = job
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onAddEquipments = onAddEquipments
        _isEnabled = State(initialValue: job.isActive)
    }

    private var equipmentNamesText: String {
        if job.equipments.isEmpty {
            return "Chưa có thiết bị"
        }

        return job.equipments.prefix(3).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppColors.primaryPurple.opacity(0.14))
                            .frame(width: 44, height: 44)

                        Image(systemName: job.scheduleIconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primaryPurple)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.jobName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)

                        Text(job.scheduleDetailText)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(2)
                    }
                    .foregroundColor(isEnabled ? AppColors.primaryPurple : AppColors.textSecondary)
                }

                Spacer(minLength: 6)

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(AutomationSwitchToggleStyle(activeColor: AppColors.primaryPurple))
            }

            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 12))
                Text(job.equipmentSummaryText)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.textSecondary)

            Text(equipmentNamesText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)

            Divider()
                .overlay(Color.black.opacity(0.06))

            HStack(spacing: 10) {
                Button(action: onAddEquipments) {
                    Label("Thiết bị", systemImage: "square.stack.3d.up.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0xDBEAFE))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                HStack(spacing: 8) {
                    AutomationCardIconButton(
                        systemName: "pencil",
                        foregroundColor: AppColors.primaryPurple,
                        backgroundColor: Color(hex: 0xF3E8FF),
                        action: onEdit
                    )

                    AutomationCardIconButton(
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
                .fill(Color.white.opacity(isEnabled ? 0.92 : 0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(
            color: AppColors.primaryPurple.opacity(isEnabled ? 0.16 : 0.08),
            radius: isEnabled ? 12 : 8,
            x: 0,
            y: isEnabled ? 7 : 4
        )
        .opacity(isEnabled ? 1 : 0.86)
    }
}

private struct AutomationCardIconButton: View {
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

private struct AutomationSwitchToggleStyle: ToggleStyle {
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

// MARK: - Automation ViewModel
@MainActor
class AutomationViewModel: ObservableObject {
    @Published var jobs: [AutomationJob] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadJobs() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1) Load automations with pagination
            let paginatedData = try await SmartRoomAPIService.shared.getAllAutomations(page: 0, size: 100)
            let automations = paginatedData.content

            // 2) For each automation, get actions/equipments
            var loadedJobs: [AutomationJob] = []

            // 3) Load all lights once to map equipment names
            let allLights = try await SmartRoomAPIService.shared.getAllLights(page: 0, size: 1000)

            for automation in automations {
                do {
                    let actionsRes = try await SmartRoomAPIService.shared.getAutomationActions(automationId: automation.id)

                    let equipmentNames = actionsRes.compactMap { action -> String? in
                        if action.targetType == "LIGHT" {
                            return allLights.first(where: { $0.id == action.targetId })?.name
                        }

                        return action.targetName
                    }

                    loadedJobs.append(AutomationJob(from: automation, equipments: equipmentNames))
                } catch {
                    print("Failed to load actions for automation \(automation.id): \(error)")
                    loadedJobs.append(AutomationJob(from: automation, equipments: []))
                }
            }

            jobs = loadedJobs
            isLoading = false
        } catch {
            errorMessage = "Failed to load automations: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func deleteJob(_ job: AutomationJob) async {
        do {
            try await SmartRoomAPIService.shared.deleteAutomation(automationId: job.id)
            jobs.removeAll { $0.id == job.id }
            print("Successfully deleted automation: \(job.jobName)")
        } catch {
            errorMessage = "Không thể xóa automation: \(error.localizedDescription)"
            print("Failed to delete automation: \(error)")
        }
    }

    func updateAutomation(id: Int, name: String, cronExpression: String, isActive: Bool, description: String?) async {
        do {
            _ = try await SmartRoomAPIService.shared.updateAutomation(
                id: id,
                name: name,
                cronExpression: cronExpression,
                isActive: isActive,
                description: description
            )

            await loadJobs()
        } catch {
            errorMessage = "Failed to update automation: \(error.localizedDescription)"
        }
    }

    func addEquipments(to job: AutomationJob) {
        print("Add equipments to: \(job.jobName)")
        // TODO: Implement add equipments functionality
    }

    func createAutomation(name: String, cronExpression: String, isActive: Bool, description: String?) async {
        do {
            _ = try await SmartRoomAPIService.shared.createAutomation(
                name: name,
                cronExpression: cronExpression,
                isActive: isActive,
                description: description
            )

            await loadJobs()
        } catch {
            errorMessage = "Failed to create automation: \(error.localizedDescription)"
        }
    }
}

// MARK: - Add Automation Sheet
struct AddAutomationSheet: View {
    private enum FrequencyTab: String, CaseIterable, Identifiable {
        case daily
        case weekly
        case monthly
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .daily: return "Hằng ngày"
            case .weekly: return "Hằng tuần"
            case .monthly: return "Hằng tháng"
            case .custom: return "Tùy chỉnh"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedFrequency: FrequencyTab
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var selectedWeekdayCode: String
    @State private var selectedDayOfMonth: Int
    @State private var selectedCustomDays: Set<Int>
    @State private var isActive: Bool
    @State private var description: String
    @State private var isSubmitting = false

    let editMode: Bool
    let onAdd: (String, String, Bool, String?) -> Void

    private let weekdayCodes = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]
    private let daysOfMonth = Array(1...31)
    private let hours = Array(0...23)
    private let minutes = Array(0...59)

    init(editMode: Bool = false, existingJob: AutomationJob? = nil, onAdd: @escaping (String, String, Bool, String?) -> Void) {
        self.editMode = editMode
        self.onAdd = onAdd

        if let job = existingJob {
            let parsedCron = Self.parseCronExpression(job.cronExpression)
            let parsedDays = Self.parseDayField(parsedCron.day)
            let defaultDay = parsedDays.first ?? 1

            _name = State(initialValue: job.jobName)
            _selectedHour = State(initialValue: parsedCron.hour)
            _selectedMinute = State(initialValue: parsedCron.minute)
            _selectedWeekdayCode = State(initialValue: Self.normalizeWeekdayCode(parsedCron.weekday))
            _selectedDayOfMonth = State(initialValue: defaultDay)
            _selectedCustomDays = State(initialValue: Set(parsedDays.isEmpty ? [defaultDay] : parsedDays))
            _isActive = State(initialValue: job.isActive)
            _description = State(initialValue: job.description ?? "")

            if (parsedCron.day == "?" || parsedCron.day == "*") && !Self.isWildcardField(parsedCron.weekday) {
                _selectedFrequency = State(initialValue: .weekly)
            } else if parsedCron.day.contains(",") {
                _selectedFrequency = State(initialValue: .custom)
            } else if !Self.isWildcardField(parsedCron.day) {
                _selectedFrequency = State(initialValue: .monthly)
            } else {
                _selectedFrequency = State(initialValue: .daily)
            }
        } else {
            let now = Date()
            let calendar = Calendar.current

            _name = State(initialValue: "")
            _selectedFrequency = State(initialValue: .daily)
            _selectedHour = State(initialValue: calendar.component(.hour, from: now))
            _selectedMinute = State(initialValue: calendar.component(.minute, from: now))
            _selectedWeekdayCode = State(initialValue: "MON")
            _selectedDayOfMonth = State(initialValue: 1)
            _selectedCustomDays = State(initialValue: Set([1]))
            _isActive = State(initialValue: true)
            _description = State(initialValue: "")
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSaveDisabled: Bool {
        trimmedName.isEmpty || isSubmitting
    }

    private var showDaySelection: Bool {
        selectedFrequency != .daily
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            generalInformationSection
                            scheduleSettingsSection
                            saveButton
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(editMode ? "Edit Schedule" : "New Schedule")
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
            .onChange(of: selectedFrequency) { newValue in
                if newValue == .custom && selectedCustomDays.isEmpty {
                    selectedCustomDays = Set([selectedDayOfMonth])
                }
            }
        }
    }

    private var generalInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GENERAL INFORMATION")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 16) {
                nameSection
                descriptionSection
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceLight.opacity(0.3))
            )
        }
    }

    private var scheduleSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCHEDULE SETTINGS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 16) {
                frequencySection
                timeSection

                if showDaySelection {
                    chooseDaySection
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceLight.opacity(0.3))
            )
        }
    }

    private var saveButtonTitle: String {
        if isSubmitting {
            return editMode ? "Updating..." : "Saving..."
        }

        return editMode ? "Update" : "Save"
    }

    private var saveButton: some View {
        Button(action: saveAutomation) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                }

                Text(saveButtonTitle)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSaveDisabled
                    ? AppColors.textSecondary.opacity(0.3)
                    : AppColors.primaryPurple
            )
            .cornerRadius(12)
        }
        .disabled(isSaveDisabled)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schedule name")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)

            TextField("Job Name", text: $name)
                .font(.system(size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surfaceWhite)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Frequency")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(FrequencyTab.allCases) { tab in
                    frequencyButton(tab)
                }
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time trigger")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                scheduleTimeBox(
                    value: selectedHour,
                    title: "Giờ",
                    options: hours,
                    onSelect: { selectedHour = $0 }
                )

                Text(":")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color(hex: 0xD1D5DB))

                scheduleTimeBox(
                    value: selectedMinute,
                    title: "Phút",
                    options: minutes,
                    onSelect: { selectedMinute = $0 }
                )
            }
        }
    }

    private var chooseDaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedFrequency == .weekly ? "Choose a Day" : "Choose Days")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 14) {
                if selectedFrequency == .monthly {
                    Text("Chọn 1 ngày duy nhất trong tháng")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }

                if selectedFrequency == .weekly {
                    HStack(spacing: 10) {
                        ForEach(weekdayCodes.indices, id: \.self) { index in
                            weekdayButton(index: index)
                        }
                    }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                        ForEach(daysOfMonth, id: \.self) { day in
                            dayButton(day)
                        }
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description (Optional)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.leading, 4)

            TextField("Mô tả lịch tự động", text: $description)
                .font(.system(size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.surfaceWhite)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                )
        }
    }

    private func frequencyButton(_ tab: FrequencyTab) -> some View {
        let isSelected = selectedFrequency == tab

        return Button(action: {
            selectedFrequency = tab
        }) {
            Text(tab.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            .foregroundColor(isSelected ? Color(hex: 0x6D28D9) : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: 0xE9D5FF) : AppColors.surfaceWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: 0x8B5CF6) : Color(hex: 0xE2E8F0),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func scheduleTimeBox(
        value: Int,
        title: String,
        options: [Int],
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(String(format: "%02d", option)) {
                    onSelect(option)
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(String(format: "%02d", value))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3B0764))

                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: 0x9CA3AF))
                    .tracking(0.8)
            }
            .frame(width: 104)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0xF1F1F9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: 0xE2E8F0), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func weekdayButton(index: Int) -> some View {
        let code = weekdayCodes[index]
        let isSelected = selectedWeekdayCode == code

        return Button(action: {
            selectedWeekdayCode = code
        }) {
            Text(weekdaySymbols[index])
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primaryPurple : Color(hex: 0xF8FAFC))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func dayButton(_ day: Int) -> some View {
        let isSelected = selectedFrequency == .monthly
            ? selectedDayOfMonth == day
            : selectedCustomDays.contains(day)

        return Button(action: {
            if selectedFrequency == .monthly {
                selectedDayOfMonth = day
            } else {
                if selectedCustomDays.contains(day) {
                    if selectedCustomDays.count > 1 {
                        selectedCustomDays.remove(day)
                    }
                } else {
                    selectedCustomDays.insert(day)
                }
            }
        }) {
            Text("\(day)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(isSelected ? AppColors.primaryPurple : Color(hex: 0xF8FAFC))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func saveAutomation() {
        guard !isSaveDisabled else { return }

        isSubmitting = true
        let cronExpression = generateCronExpression()
        onAdd(
            trimmedName,
            cronExpression,
            isActive,
            trimmedDescription.isEmpty ? nil : trimmedDescription
        )
        dismiss()
    }

    private func generateCronExpression() -> String {
        // Cron format: second minute hour day month weekday
        let second = "0"
        let minute = String(selectedMinute)
        let hour = String(selectedHour)

        switch selectedFrequency {
        case .daily:
            return "\(second) \(minute) \(hour) * * ?"

        case .weekly:
            return "\(second) \(minute) \(hour) ? * \(selectedWeekdayCode)"

        case .monthly:
            return "\(second) \(minute) \(hour) \(selectedDayOfMonth) * ?"

        case .custom:
            let customDays = selectedCustomDays.isEmpty
                ? [max(1, min(31, selectedDayOfMonth))]
                : selectedCustomDays.sorted()
            let dayField = customDays.map(String.init).joined(separator: ",")
            return "\(second) \(minute) \(hour) \(dayField) * ?"
        }
    }

    private static func parseCronExpression(_ expression: String) -> (minute: Int, hour: Int, day: String, weekday: String) {
        let parts = expression.split(separator: " ").map(String.init)

        if parts.count >= 6 {
            return (
                minute: Int(parts[1]) ?? 0,
                hour: Int(parts[2]) ?? 0,
                day: parts[3],
                weekday: parts[5]
            )
        }

        if parts.count == 5 {
            return (
                minute: Int(parts[0]) ?? 0,
                hour: Int(parts[1]) ?? 0,
                day: parts[2],
                weekday: parts[4]
            )
        }

        return (minute: 0, hour: 0, day: "*", weekday: "?")
    }

    private static func parseDayField(_ dayField: String) -> [Int] {
        dayField
            .split(separator: ",")
            .compactMap { Int($0) }
            .filter { (1...31).contains($0) }
    }

    private static func normalizeWeekdayCode(_ weekday: String) -> String {
        switch weekday.uppercased() {
        case "MON", "1": return "MON"
        case "TUE", "2": return "TUE"
        case "WED", "3": return "WED"
        case "THU", "4": return "THU"
        case "FRI", "5": return "FRI"
        case "SAT", "6": return "SAT"
        case "SUN", "0", "7": return "SUN"
        default: return "MON"
        }
    }

    private static func isWildcardField(_ value: String) -> Bool {
        value == "*" || value == "?"
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AutomationScreen()
    }
}
