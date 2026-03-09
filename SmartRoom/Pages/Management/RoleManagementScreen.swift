import SwiftUI

// MARK: - Models
struct MgmtGroup: Identifiable {
    let id: Int
    let code: String
    let name: String
    let description: String?
    
    init(id: Int, code: String, name: String, description: String?) {
        self.id = id
        self.code = code
        self.name = name
        self.description = description
    }
    
    init(from group: APIGroup) {
        self.id = group.id
        self.code = group.groupCode
        self.name = group.name
        self.description = group.description
    }
}

struct MgmtFunction: Identifiable {
    let id: Int
    let code: String
    let name: String
    let description: String?
    
    init(id: Int, code: String, name: String, description: String?) {
        self.id = id
        self.code = code
        self.name = name
        self.description = description
    }
    
    init(from apiFunction: APIFunction) {
        self.id = apiFunction.id
        self.code = apiFunction.functionCode
        self.name = apiFunction.name
        self.description = apiFunction.description
    }
}

// MARK: - Role Management Screen
struct RoleManagementScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var repository = FakeRoleRepository()
    
    @State private var searchQuery = ""
    @State private var groups: [MgmtGroup] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Navigation State
    @State private var navigateToDetail = false
    @State private var selectedGroup: MgmtGroup?
    
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    
    var filteredGroups: [MgmtGroup] {
        if searchQuery.isEmpty {
            return groups
        }
        return groups.filter {
            $0.code.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    query: $searchQuery,
                    placeholder: "Search groups..."
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Text("❌ Error")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Retry") {
                            loadGroups()
                        }
                        .font(AppTypography.titleMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else if filteredGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(searchQuery.isEmpty ? "No groups yet" : "No groups found")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            NavigationLink(
                                destination: selectedGroup.map { RoleDetailScreen(group: $0, repository: repository).id($0.id) },
                                isActive: $navigateToDetail
                            ) {
                                EmptyView()
                            }
                            
                            ForEach(filteredGroups) { group in
                                ModernRoleItemView(
                                    group: group,
                                    onTap: {
                                        selectedGroup = group
                                        navigateToDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // Snackbar
            if showSnackbar {
                SnackbarView(message: snackbarMessage)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showSnackbar)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Role Management")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .onAppear {
            loadGroups()
        }
    }
    
    private func loadGroups() {
        Task {
            await performLoadGroups()
        }
    }
    
    @MainActor
    private func performLoadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiGroups = try await SmartRoomAPIService.shared.getAllGroups()
            // Convert APIGroup to MgmtGroup
            groups = apiGroups.map { apiGroup in
                MgmtGroup(from: apiGroup)
            }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Role Detail Screen
struct RoleDetailScreen: View {
    let group: MgmtGroup
    let repository: FakeRoleRepository
    
    @Environment(\.presentationMode) var presentationMode
    @State private var allFunctions: [MgmtFunction] = []
    @State private var selectedFunctionIds: Set<Int> = []
    @State private var originalSelectedFunctionIds: Set<Int> = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Group Info Section
                VStack(spacing: 16) {
                    // Icon
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0x2ECC71), Color(hex: 0x27AE60)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                    
                    // Group Info
                    VStack(spacing: 4) {
                        Text(group.code)
                            .font(AppTypography.headlineMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(group.description ?? "")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("ID: \(group.id)")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(AppColors.surfaceWhite)
                
                // Functions Section Header
                HStack {
                    Text("Assigned Functions")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                // Functions List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Text("❌ Error")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button("Retry") {
                            loadData()
                        }
                        .font(AppTypography.titleMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(allFunctions) { function in
                                FunctionSelectionRow(
                                    function: function,
                                    isSelected: selectedFunctionIds.contains(function.id),
                                    onToggle: {
                                        if selectedFunctionIds.contains(function.id) {
                                            selectedFunctionIds.remove(function.id)
                                        } else {
                                            selectedFunctionIds.insert(function.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Save Button
            if !isLoading {
                Button(action: saveChanges) {
                    HStack(spacing: 12) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text(isSaving ? "Saving..." : "Save Changes")
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isSaving ? AppColors.primaryPurple.opacity(0.7) : AppColors.primaryPurple)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if !isSaving {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(isSaving ? AppColors.textSecondary.opacity(0.3) : AppColors.textPrimary)
                }
                .disabled(isSaving)
            }
            
            ToolbarItem(placement: .principal) {
                Text("Role Details")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .onAppear {
            // Reset state first to clear previous group's data
            allFunctions = []
            selectedFunctionIds = []
            originalSelectedFunctionIds = []
            isLoading = true
            errorMessage = nil
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            await performLoadData()
        }
    }
    
    @MainActor
    private func performLoadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Load all system functions first
            print("Loading all functions...")
            let apiFunctions = try await SmartRoomAPIService.shared.getAllFunctions()
            print("Loaded \(apiFunctions.count) functions")
            allFunctions = apiFunctions.map { MgmtFunction(from: $0) }
            
            // Step 2: Load functions assigned to this group
            print("Loading group functions for group \(group.id)...")
            let groupFunctions = try await SmartRoomAPIService.shared.getGroupFunctions(groupId: group.id)
            print("Group has \(groupFunctions.count) assigned functions")
            selectedFunctionIds = Set(groupFunctions.map { $0.id })
            originalSelectedFunctionIds = selectedFunctionIds
            
            isLoading = false
        } catch {
            print("Error loading functions: \(error)")
            errorMessage = "Failed to load functions: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func saveChanges() {
        Task {
            await performSaveChanges()
        }
    }
    
    @MainActor
    private func performSaveChanges() async {
        isSaving = true
        
        // Compare current state with original state
        let toAdd = selectedFunctionIds.subtracting(originalSelectedFunctionIds)
        let toRemove = originalSelectedFunctionIds.subtracting(selectedFunctionIds)
        
        // Get function codes for the changed functions
        let functionsToAdd = allFunctions.filter { toAdd.contains($0.id) }.map { $0.code }
        let functionsToRemove = allFunctions.filter { toRemove.contains($0.id) }.map { $0.code }
        
        do {
            // Add new functions
            if !functionsToAdd.isEmpty {
                _ = try await SmartRoomAPIService.shared.batchAddFunctionsToGroup(
                    groupId: group.id,
                    functionCodes: functionsToAdd
                )
            }
            
            // Remove functions
            if !functionsToRemove.isEmpty {
                _ = try await SmartRoomAPIService.shared.batchRemoveFunctionsFromGroup(
                    groupId: group.id,
                    functionCodes: functionsToRemove
                )
            }
            
            // Dismiss after successful save
            presentationMode.wrappedValue.dismiss()
            
        } catch {
            isSaving = false
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - Modern Role Item View
struct ModernRoleItemView: View {
    let group: MgmtGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x2ECC71), Color(hex: 0x27AE60)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.code)
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.description ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Function Selection Row
struct FunctionSelectionRow: View {
    let function: MgmtFunction
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(function.name)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(function.code)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textSecondary.opacity(0.7))
                        
                        if let desc = function.description {
                            Text(desc)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3))
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fake Role Repository
class FakeRoleRepository: ObservableObject {
    private var groups: [MgmtGroup] = [
        MgmtGroup(id: 1, code: "ADMIN", name: "Administrator", description: "Administrator group"),
        MgmtGroup(id: 2, code: "USER", name: "User", description: "Standard user group"),
        MgmtGroup(id: 3, code: "GUEST", name: "Guest", description: "Guest user group"),
        MgmtGroup(id: 4, code: "MODERATOR", name: "Moderator", description: "Moderator group"),
        MgmtGroup(id: 5, code: "DEVELOPER", name: "Developer", description: "Developer group")
    ]
    
    private var functions: [MgmtFunction] = [
        MgmtFunction(id: 1, code: "USER_READ", name: "View Users", description: "View user information"),
        MgmtFunction(id: 2, code: "USER_WRITE", name: "Edit Users", description: "Create and edit users"),
        MgmtFunction(id: 3, code: "USER_DELETE", name: "Delete Users", description: "Delete users"),
        MgmtFunction(id: 4, code: "ROOM_READ", name: "View Rooms", description: "View rooms"),
        MgmtFunction(id: 5, code: "ROOM_WRITE", name: "Edit Rooms", description: "Create and edit rooms"),
        MgmtFunction(id: 6, code: "ROOM_DELETE", name: "Delete Rooms", description: "Delete rooms"),
        MgmtFunction(id: 7, code: "DEVICE_READ", name: "View Devices", description: "View devices"),
        MgmtFunction(id: 8, code: "DEVICE_WRITE", name: "Edit Devices", description: "Create and edit devices"),
        MgmtFunction(id: 9, code: "DEVICE_DELETE", name: "Delete Devices", description: "Delete devices"),
        MgmtFunction(id: 10, code: "SETTINGS_MANAGE", name: "Manage Settings", description: "Manage system settings")
    ]
    
    private var groupFunctions: [Int: [Int]] = [
        1: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // ADMIN has all
        2: [1, 4, 7], // USER has read access
        3: [4, 7], // GUEST has limited read
        4: [1, 2, 4, 5, 7, 8], // MODERATOR has read/write
        5: [1, 2, 4, 5, 7, 8, 10] // DEVELOPER has most
    ]
    
    func getGroups() -> [MgmtGroup] {
        return groups
    }
    
    func getFunctions() -> [MgmtFunction] {
        return functions
    }
    
    func getGroupFunctions(groupId: Int) -> Set<Int> {
        return Set(groupFunctions[groupId] ?? [])
    }
    
    func fetchFunctionsForGroup(groupId: Int) -> ([MgmtFunction], Set<Int>) {
        let allFunctions = getFunctions()
        let functionIds = getGroupFunctions(groupId: groupId)
        return (allFunctions, functionIds)
    }
    
    func updateGroupFunctions(groupId: Int, functionIds: [Int]) {
        groupFunctions[groupId] = functionIds
        print("Updated functions for group \(groupId): \(functionIds)")
    }
    
    func deleteFunction(functionId: Int) {
        functions.removeAll { $0.id == functionId }
        // Also remove from all group assignments
        for (groupId, funcIds) in groupFunctions {
            groupFunctions[groupId] = funcIds.filter { $0 != functionId }
        }
    }
}

// MARK: - Preview
struct RoleManagementScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RoleManagementScreen()
        }
    }
}
