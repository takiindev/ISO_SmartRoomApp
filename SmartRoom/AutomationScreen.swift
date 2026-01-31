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
    
    // Helper to convert cron expression to readable schedule
    var scheduleText: String {
        // Basic cron parser for common patterns
        // Format: second minute hour day month weekday
        let parts = cronExpression.split(separator: " ")
        guard parts.count >= 5 else { return cronExpression }
        
        let minute = String(parts[1])
        let hour = String(parts[2])
        let day = String(parts[3])
        let month = String(parts[4])
        let weekday = parts.count > 5 ? String(parts[5]) : "*"
        
        // If day is *, check weekday for weekly pattern
        if day == "*" && weekday != "*" && weekday != "?" {
            let weekdayName = getWeekdayName(weekday)
            return "\(weekdayName) / Week"
        }
        
        // If all are *, it's everyday
        if day == "*" && weekday == "*" || weekday == "?" {
            return "Everyday"
        }
        
        return cronExpression
    }
    
    var timeText: String {
        let parts = cronExpression.split(separator: " ")
        guard parts.count >= 3 else { return "Unknown" }
        
        let minute = String(parts[1])
        let hour = String(parts[2])
        
        // Convert to 12-hour format
        if let hourInt = Int(hour) {
            let hour12 = hourInt == 0 ? 12 : (hourInt > 12 ? hourInt - 12 : hourInt)
            let ampm = hourInt >= 12 ? "PM" : "AM"
            let minuteStr = minute == "0" ? "00" : minute
            return "\(hour12):\(minuteStr) \(ampm)"
        }
        
        return "\(hour):\(minute)"
    }
    
    private func getWeekdayName(_ weekday: String) -> String {
        switch weekday {
        case "1": return "T2"
        case "2": return "T3"
        case "3": return "T4"
        case "4": return "T5"
        case "5": return "T6"
        case "6": return "T7"
        case "0", "7": return "CN"
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
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
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
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(AppColors.appBackground)
                
                // Hidden Navigation Link
                NavigationLink(
                    destination: EquipmentScreen(automationId: selectedJobForEquipment?.id)
                        .id(selectedJobForEquipment?.id ?? 0), // Force recreate when automation changes
                    isActive: $navigateToEquipment
                ) {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .opacity(0)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)
                        
                        if viewModel.isLoading {
                            ManagementLoadingView()
                        } else if let error = viewModel.errorMessage {
                            VStack(spacing: 16) {
                                Text("❌ Error")
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
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(AppColors.primaryPurple)
                                .cornerRadius(8)
                            }
                            .padding(20)
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
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 20)
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
}

// MARK: - Automation Job Card
struct AutomationJobCard: View {
    let job: AutomationJob
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onAddEquipments: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(job.jobName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                HStack(spacing: 10) {
                    // Delete Button
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: 0xFF3B30))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Edit Button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: 0x007AFF))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AppColors.surfaceWhite)
            .overlay(
                Rectangle()
                    .fill(Color(hex: 0xDDDDDD))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Time Row
            AutomationJobRow(label: "Time", value: job.timeText)
            
            AutomationDivider()
            
            // Schedule Row
            AutomationJobRow(label: "Schedule", value: job.scheduleText)
            
            AutomationDivider()
            
            // Equipments Row
            AutomationJobRow(
                label: "Equipments",
                value: job.equipments.isEmpty ? "No equipments" : job.equipments.joined(separator: ", ")
            )
            
            AutomationDivider()
            
            // Edit Equipments Button
            Button(action: onAddEquipments) {
                HStack {
                    Spacer()
                    Text("Edit equipments")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: 0xEB5757))
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(AppColors.surfaceWhite)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(AppColors.surfaceWhite)
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Automation Job Row
struct AutomationJobRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: 0x444444))
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0x222222))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppColors.surfaceWhite)
    }
}

// MARK: - Automation Divider
struct AutomationDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 1)
            .padding(.horizontal, 20)
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
            // 1️⃣ Load automations with pagination
            let paginatedData = try await SmartRoomAPIService.shared.getAllAutomations(page: 0, size: 100)
            
            let automations = paginatedData.content
            
            // 2️⃣ Với mỗi automation → lấy actions (equipments)
            var loadedJobs: [AutomationJob] = []
            
            // 2.5️⃣ Load all lights once để map tên equipment
            let allLights = try await SmartRoomAPIService.shared.getAllLights(page: 0, size: 1000)
            
            for automation in automations {
                do {
                    let actionsRes = try await SmartRoomAPIService.shared.getAutomationActions(automationId: automation.id)
                    
                    // Map từ targetId sang tên thực tế của equipment
                    let equipmentNames = actionsRes.compactMap { action -> String? in
                        if action.targetType == "LIGHT" {
                            // Tìm light theo ID và lấy tên
                            return allLights.first(where: { $0.id == action.targetId })?.name
                        }
                        // Các loại equipment khác có thể thêm ở đây
                        return action.targetName // Fallback to targetName if not found
                    }
                    
                    let job = AutomationJob(from: automation, equipments: equipmentNames)
                    loadedJobs.append(job)
                } catch {
                    // Nếu không load được actions, tạo job với equipments rỗng
                    print("Failed to load actions for automation \(automation.id): \(error)")
                    let job = AutomationJob(from: automation, equipments: [])
                    loadedJobs.append(job)
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
            
            // Remove from local list after successful deletion
            jobs.removeAll { $0.id == job.id }
            
            print("✅ Successfully deleted automation: \(job.jobName)")
        } catch {
            errorMessage = "Không thể xóa automation: \(error.localizedDescription)"
            print("❌ Failed to delete automation: \(error)")
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
            
            // Reload jobs after updating
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
            
            // Reload jobs after creating
            await loadJobs()
        } catch {
            errorMessage = "Failed to create automation: \(error.localizedDescription)"
        }
    }
}

// MARK: - Add Automation Sheet
struct AddAutomationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var scheduleType: String
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var selectedWeekday: String
    @State private var selectedDayOfMonth: Int
    @State private var isActive: Bool
    @State private var description: String
    @State private var isSubmitting: Bool = false
    
    let editMode: Bool
    let scheduleTypes = ["Hàng ngày", "Hàng tuần", "Hàng tháng"]
    let weekdays = ["Thứ hai", "Thứ ba", "Thứ tư", "Thứ năm", "Thứ sáu", "Thứ bảy", "Chủ nhật"]
    let daysOfMonth = Array(1...31)
    let hours = Array(0...23)
    let minutes = Array(0...59)
    
    let onAdd: (String, String, Bool, String?) -> Void
    
    init(editMode: Bool = false, existingJob: AutomationJob? = nil, onAdd: @escaping (String, String, Bool, String?) -> Void) {
        self.editMode = editMode
        self.onAdd = onAdd
        
        if let job = existingJob {
            // Parse existing job data
            _name = State(initialValue: job.jobName)
            _description = State(initialValue: job.description ?? "")
            _isActive = State(initialValue: job.isActive)
            
            // Parse cron expression
            let parts = job.cronExpression.split(separator: " ")
            let minute = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
            let hour = parts.count > 2 ? Int(parts[2]) ?? 0 : 0
            let day = parts.count > 3 ? String(parts[3]) : "*"
            let weekday = parts.count > 5 ? String(parts[5]) : "?"
            
            _selectedHour = State(initialValue: hour)
            _selectedMinute = State(initialValue: minute)
            
            // Determine schedule type
            if day == "*" && (weekday == "*" || weekday == "?") {
                _scheduleType = State(initialValue: "Hàng ngày")
                _selectedWeekday = State(initialValue: "Thứ hai")
                _selectedDayOfMonth = State(initialValue: 1)
            } else if day == "?" && weekday != "*" && weekday != "?" {
                _scheduleType = State(initialValue: "Hàng tuần")
                _selectedWeekday = State(initialValue: Self.getWeekdayFromCode(String(weekday)))
                _selectedDayOfMonth = State(initialValue: 1)
            } else {
                _scheduleType = State(initialValue: "Hàng tháng")
                _selectedWeekday = State(initialValue: "Thứ hai")
                _selectedDayOfMonth = State(initialValue: Int(day) ?? 1)
            }
        } else {
            // New automation - use current time
            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            
            _name = State(initialValue: "")
            _scheduleType = State(initialValue: "Hàng ngày")
            _selectedHour = State(initialValue: currentHour)
            _selectedMinute = State(initialValue: currentMinute)
            _selectedWeekday = State(initialValue: "Thứ hai")
            _selectedDayOfMonth = State(initialValue: 1)
            _isActive = State(initialValue: true)
            _description = State(initialValue: "")
        }
    }
    
    private static func getWeekdayFromCode(_ code: String) -> String {
        switch code.uppercased() {
        case "MON", "1": return "Thứ hai"
        case "TUE", "2": return "Thứ ba"
        case "WED", "3": return "Thứ tư"
        case "THU", "4": return "Thứ năm"
        case "FRI", "5": return "Thứ sáu"
        case "SAT", "6": return "Thứ bảy"
        case "SUN", "0", "7": return "Chủ nhật"
        default: return "Thứ hai"
        }
    }
    
    var showDaySelection: Bool {
        scheduleType == "Hàng tuần" || scheduleType == "Hàng tháng"
    }
    
    var daySelectionLabel: String {
        scheduleType == "Hàng tuần" ? "Days of the week" : "Day of the month"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 8)
                            
                            // Schedule Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Schedule name")
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Enter schedule name", text: $name)
                                    .font(AppTypography.bodyMedium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: 0x999999), lineWidth: 1)
                                    )
                            }
                            
                            // Schedule Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Schedule type")
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Menu {
                                    ForEach(scheduleTypes, id: \.self) { type in
                                        Button(type) {
                                            scheduleType = type
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(scheduleType)
                                            .foregroundColor(AppColors.textPrimary)
                                            .font(.system(size: 15))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: 0x999999), lineWidth: 1)
                                    )
                                }
                            }
                            
                            // Day Selection (Conditional - only for weekly/monthly)
                            if showDaySelection {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(daySelectionLabel)
                                        .font(AppTypography.bodyMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    if scheduleType == "Hàng tuần" {
                                        // Weekday selector
                                        Menu {
                                            ForEach(weekdays, id: \.self) { weekday in
                                                Button(weekday) {
                                                    selectedWeekday = weekday
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(selectedWeekday)
                                                    .foregroundColor(AppColors.textPrimary)
                                                    .font(.system(size: 15))
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(AppColors.surfaceWhite)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color(hex: 0x999999), lineWidth: 1)
                                            )
                                        }
                                    } else {
                                        // Day of month selector
                                        Menu {
                                            ForEach(daysOfMonth, id: \.self) { day in
                                                Button("\(day)") {
                                                    selectedDayOfMonth = day
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text("\(selectedDayOfMonth)")
                                                    .foregroundColor(AppColors.textPrimary)
                                                    .font(.system(size: 15))
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(AppColors.surfaceWhite)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color(hex: 0x999999), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Schedule Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Schedule time")
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                HStack(spacing: 12) {
                                    // Hour Menu
                                    Menu {
                                        ForEach(hours, id: \.self) { hour in
                                            Button(String(format: "%02d", hour)) {
                                                selectedHour = hour
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(String(format: "%02d", selectedHour))
                                                .foregroundColor(AppColors.textPrimary)
                                                .font(.system(size: 16))
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(AppColors.surfaceWhite)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: 0x999999), lineWidth: 1)
                                        )
                                    }
                                    
                                    // Minute Menu
                                    Menu {
                                        ForEach(minutes, id: \.self) { minute in
                                            Button(String(format: "%02d", minute)) {
                                                selectedMinute = minute
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(String(format: "%02d", selectedMinute))
                                                .foregroundColor(AppColors.textPrimary)
                                                .font(.system(size: 16))
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(AppColors.surfaceWhite)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: 0x999999), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Description (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Enter description", text: $description)
                                    .font(AppTypography.bodyMedium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: 0xCCCCCC), lineWidth: 1)
                                    )
                            }
                            
                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Save Button (Fixed at bottom)
                VStack {
                    Spacer()
                    
                    Button(action: {
                        isSubmitting = true
                        let cronExpression = generateCronExpression()
                        onAdd(
                            name,
                            cronExpression,
                            isActive,
                            description.isEmpty ? nil : description
                        )
                        dismiss()
                    }) {
                        Text(editMode ? "Update" : "Save")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                name.isEmpty ?
                                AppColors.textSecondary.opacity(0.3) :
                                Color(hex: 0xBD52F5)
                            )
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || isSubmitting)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(editMode ? "Edit Schedule" : "Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
    }
    
    // Generate Cron Expression from user selections
    private func generateCronExpression() -> String {
        // Cron format: second minute hour day month weekday
        let second = "0"
        let minute = String(selectedMinute)
        let hour = String(selectedHour)
        
        switch scheduleType {
        case "Hàng ngày":
            // Every day at selected time
            return "\(second) \(minute) \(hour) * * ?"
            
        case "Hàng tuần":
            // Specific weekday at selected time
            let weekdayCode = getWeekdayCode(selectedWeekday)
            return "\(second) \(minute) \(hour) ? * \(weekdayCode)"
            
        case "Hàng tháng":
            // Specific day of month at selected time
            return "\(second) \(minute) \(hour) \(selectedDayOfMonth) * ?"
            
        default:
            return "\(second) \(minute) \(hour) * * ?"
        }
    }
    
    private func getWeekdayCode(_ weekday: String) -> String {
        switch weekday {
        case "Thứ hai": return "MON"
        case "Thứ ba": return "TUE"
        case "Thứ tư": return "WED"
        case "Thứ năm": return "THU"
        case "Thứ sáu": return "FRI"
        case "Thứ bảy": return "SAT"
        case "Chủ nhật": return "SUN"
        default: return "MON"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AutomationScreen()
    }
}
