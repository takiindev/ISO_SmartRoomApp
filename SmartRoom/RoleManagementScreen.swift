import SwiftUI

// MARK: - Models
struct MgmtGroup: Identifiable {
    let id: Int
    let code: String
    let description: String
}

struct MgmtFunction: Identifiable {
    let id: Int
    let code: String
    let description: String
}

// MARK: - Role Management Screen
struct RoleManagementScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var repository = FakeRoleRepository()
    
    @State private var searchQuery = ""
    @State private var groups: [MgmtGroup] = []
    @State private var isLoading = true
    
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
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            NavigationLink(
                                destination: selectedGroup.map { RoleDetailScreen(group: $0, repository: repository) },
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
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            groups = repository.getGroups()
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
    @State private var isLoading = true
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    
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
                        
                        Text(group.description)
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
                    Text("Save Changes")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
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
                Text("Role Details")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        let (functions, functionIds) = repository.fetchFunctionsForGroup(groupId: group.id)
        allFunctions = functions
        selectedFunctionIds = functionIds
        isLoading = false
    }
    
    private func saveChanges() {
        repository.updateGroupFunctions(groupId: group.id, functionIds: Array(selectedFunctionIds))
        showSnackbarMessage("Updated functions for \(group.code)")
        
        // Auto dismiss after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func showSnackbarMessage(_ message: String) {
        snackbarMessage = message
        showSnackbar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSnackbar = false
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
                    
                    Text(group.description)
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
                        Text(function.code)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(function.description)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
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
        MgmtGroup(id: 1, code: "ADMIN", description: "Administrator group"),
        MgmtGroup(id: 2, code: "USER", description: "Standard user group"),
        MgmtGroup(id: 3, code: "GUEST", description: "Guest user group"),
        MgmtGroup(id: 4, code: "MODERATOR", description: "Moderator group"),
        MgmtGroup(id: 5, code: "DEVELOPER", description: "Developer group")
    ]
    
    private var functions: [MgmtFunction] = [
        MgmtFunction(id: 1, code: "USER_READ", description: "View user information"),
        MgmtFunction(id: 2, code: "USER_WRITE", description: "Create and edit users"),
        MgmtFunction(id: 3, code: "USER_DELETE", description: "Delete users"),
        MgmtFunction(id: 4, code: "ROOM_READ", description: "View rooms"),
        MgmtFunction(id: 5, code: "ROOM_WRITE", description: "Create and edit rooms"),
        MgmtFunction(id: 6, code: "ROOM_DELETE", description: "Delete rooms"),
        MgmtFunction(id: 7, code: "DEVICE_READ", description: "View devices"),
        MgmtFunction(id: 8, code: "DEVICE_WRITE", description: "Create and edit devices"),
        MgmtFunction(id: 9, code: "DEVICE_DELETE", description: "Delete devices"),
        MgmtFunction(id: 10, code: "SETTINGS_MANAGE", description: "Manage system settings")
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
