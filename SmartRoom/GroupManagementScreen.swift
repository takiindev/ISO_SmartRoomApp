import SwiftUI

// MARK: - Main Screen
struct GroupManagementScreen: View {
    @StateObject private var repository = FakeManagementRepository()
    @State private var groups: [MgmtGroup] = []
    @State private var searchQuery = ""
    @State private var isLoading = true
    @State private var showDeleteDialog = false
    @State private var groupToDelete: MgmtGroup?
    @State private var navigateToMembers = false
    @State private var selectedGroup: MgmtGroup?
    @Environment(\.presentationMode) var presentationMode
    
    var filteredGroups: [MgmtGroup] {
        if searchQuery.isEmpty {
            return groups
        }
        return groups.filter { $0.code.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Group Management")
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.appBackground)
                
                // Search Bar
                ManagementSearchBar(
                    query: $searchQuery,
                    placeholder: "Search groups..."
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Groups List
                if isLoading {
                    ManagementLoadingView()
                } else if filteredGroups.isEmpty {
                    ManagementEmptyStateView(
                        icon: "person.3.fill",
                        message: searchQuery.isEmpty ? "No groups yet" : "No groups found"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(filteredGroups) { group in
                                ModernGroupItemView(
                                    group: group,
                                    onEdit: {
                                        // TODO: Add edit functionality
                                        print("Edit group: \(group.code)")
                                    },
                                    onDelete: {
                                        groupToDelete = group
                                        showDeleteDialog = true
                                    },
                                    onMembers: {
                                        selectedGroup = group
                                        navigateToMembers = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: Add group functionality
                        print("Add new group")
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppColors.primaryPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Navigation Link
            NavigationLink(
                destination: selectedGroup.map { GroupMembersScreen(group: $0, repository: repository) },
                isActive: $navigateToMembers
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .onAppear {
            loadGroups()
        }
        .alert("Delete Group?", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {
                groupToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    deleteGroup(group)
                }
            }
        } message: {
            if let group = groupToDelete {
                Text("This will permanently delete group '\(group.code)'.")
            }
        }
    }
    
    private func loadGroups() {
        groups = repository.getGroups()
        isLoading = false
    }
    
    private func deleteGroup(_ group: MgmtGroup) {
        repository.deleteGroup(groupId: group.id)
        loadGroups()
        groupToDelete = nil
    }
}

// MARK: - Group Item View
struct ModernGroupItemView: View {
    let group: MgmtGroup
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMembers: () -> Void
    
    var body: some View {
        ManagementItemCard(onClick: onMembers) {
            HStack(spacing: 12) {
                // Icon
                ManagementIconBox(
                    icon: "person.3.fill",
                    color: Color(hex: 0x2ECC71)
                )
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.code)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    ManagementActionButton(
                        icon: "pencil",
                        color: AppColors.primaryPurple,
                        action: onEdit
                    )
                    
                    ManagementActionButton(
                        icon: "trash",
                        color: .red,
                        action: onDelete
                    )
                }
            }
        }
    }
}

// MARK: - Group Members Screen
struct GroupMembersScreen: View {
    let group: MgmtGroup
    @ObservedObject var repository: FakeManagementRepository
    @State private var users: [MgmtUser] = []
    @State private var groupUsers: [MgmtUser] = []
    @State private var selectedUserIds: Set<Int> = []
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Group Members")
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: saveChanges) {
                        Text("Save")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.primaryPurple)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.appBackground)
                
                // Group Info Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ManagementIconBox(
                            icon: "person.3.fill",
                            color: Color(hex: 0x2ECC71)
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.code)
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("\(selectedUserIds.count) members selected")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Members List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(users) { user in
                            ManagementCheckboxItem(
                                item: ManagementSelectionItem(
                                    id: user.id,
                                    title: user.username,
                                    subtitle: user.email
                                ),
                                isChecked: selectedUserIds.contains(user.id),
                                onCheckedChange: { isChecked in
                                    if isChecked {
                                        selectedUserIds.insert(user.id)
                                    } else {
                                        selectedUserIds.remove(user.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Snackbar
            if showSnackbar {
                VStack {
                    Spacer()
                    ManagementSnackbar(message: snackbarMessage)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        users = repository.getUsers()
        groupUsers = repository.getUsersByGroup(groupId: group.id)
        selectedUserIds = Set(groupUsers.map { $0.id })
    }
    
    private func saveChanges() {
        repository.updateGroupUsers(groupId: group.id, userIds: Array(selectedUserIds))
        snackbarMessage = "Group members updated successfully"
        showSnackbar = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct GroupManagementScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupManagementScreen()
        }
    }
}
