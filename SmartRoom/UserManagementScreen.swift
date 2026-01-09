import SwiftUI

// MARK: - Models
struct MgmtUser: Identifiable {
    let id: Int
    let username: String
    let email: String
}

struct SelectionItem: Identifiable {
    let id: Int
    let name: String
}

// MARK: - User Management Screen
struct UserManagementScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var repository = FakeManagementRepository()
    
    @State private var searchQuery = ""
    @State private var users: [MgmtUser] = []
    @State private var isLoading = true
    
    // Dialog States
    @State private var showDeleteDialog = false
    @State private var userToDelete: MgmtUser?
    @State private var showResetDialog = false
    @State private var userToReset: MgmtUser?
    
    // Navigation State
    @State private var navigateToDetail = false
    @State private var selectedUser: MgmtUser?
    
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    
    var filteredUsers: [MgmtUser] {
        if searchQuery.isEmpty {
            return users
        }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(searchQuery) ||
            $0.email.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    query: $searchQuery,
                    placeholder: "Find user by name"
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
                                destination: selectedUser.map { UserDetailScreen(user: $0, repository: repository) },
                                isActive: $navigateToDetail
                            ) {
                                EmptyView()
                            }
                            
                            ForEach(filteredUsers) { user in
                                ModernUserItemView(
                                    user: user,
                                    onEdit: {
                                        // TODO: Add edit functionality
                                    },
                                    onDelete: {
                                        userToDelete = user
                                        showDeleteDialog = true
                                    },
                                    onReset: {
                                        userToReset = user
                                        showResetDialog = true
                                    },
                                    onPermission: {
                                        selectedUser = user
                                        navigateToDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80) // Space for FAB
                    }
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: Add user functionality
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(AppColors.primaryPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
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
                Text("Users")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .alert("Delete User?", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {
                showDeleteDialog = false
            }
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    deleteUser(user)
                }
            }
        } message: {
            if let user = userToDelete {
                Text("Are you sure you want to delete \(user.username)?")
            }
        }
        .alert("Reset Password", isPresented: $showResetDialog) {
            Button("Cancel", role: .cancel) {
                showResetDialog = false
            }
            Button("Reset") {
                if let user = userToReset {
                    resetPassword(user)
                }
            }
        } message: {
            if let user = userToReset {
                Text("Reset password for \(user.username) to default?")
            }
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            users = repository.getUsers()
            isLoading = false
        }
    }
    
    private func deleteUser(_ user: MgmtUser) {
        repository.deleteUser(userId: user.id)
        loadUsers()
        showDeleteDialog = false
        userToDelete = nil
    }
    
    private func resetPassword(_ user: MgmtUser) {
        repository.resetPassword(userId: user.id)
        showResetDialog = false
        userToReset = nil
        showSnackbarMessage("Password reset for \(user.username)")
    }
    
    private func showSnackbarMessage(_ message: String) {
        snackbarMessage = message
        showSnackbar = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSnackbar = false
        }
    }
}

// MARK: - User Detail Screen
struct UserDetailScreen: View {
    let user: MgmtUser
    let repository: FakeManagementRepository
    
    @Environment(\.presentationMode) var presentationMode
    @State private var allGroups: [SelectionItem] = []
    @State private var selectedGroupIds: Set<Int> = []
    @State private var isLoading = true
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // User Info Section
                VStack(spacing: 16) {
                    // Avatar
                    InitialsAvatarView(name: user.username)
                        .frame(width: 80, height: 80)
                    
                    // User Info
                    VStack(spacing: 4) {
                        Text(user.username)
                            .font(AppTypography.headlineMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(user.email)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("ID: \(user.id)")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(AppColors.surfaceWhite)
                
                // Groups Section Header
                HStack {
                    Text("Assigned Groups")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                // Groups List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(allGroups) { group in
                                GroupSelectionRow(
                                    group: group,
                                    isSelected: selectedGroupIds.contains(group.id),
                                    onToggle: {
                                        if selectedGroupIds.contains(group.id) {
                                            selectedGroupIds.remove(group.id)
                                        } else {
                                            selectedGroupIds.insert(group.id)
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
                Text("User Details")
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
        let (groups, groupIds) = repository.fetchGroupsForUser(userId: user.id)
        allGroups = groups
        selectedGroupIds = groupIds
        isLoading = false
    }
    
    private func saveChanges() {
        repository.updateUserGroups(userId: user.id, groupIds: Array(selectedGroupIds))
        showSnackbarMessage("Updated groups for \(user.username)")
        
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

// MARK: - Modern User Item View
struct ModernUserItemView: View {
    let user: MgmtUser
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    let onPermission: () -> Void
    
    var body: some View {
        Button(action: onPermission) {
            HStack(spacing: 12) {
                // Avatar
                InitialsAvatarView(name: user.username)
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("ID: \(user.id)")
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(user.username)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 10) {
                    ActionButton(
                        icon: "lock.rotation",
                        color: Color.orange,
                        action: onReset
                    )
                    
                    ActionButton(
                        icon: "pencil",
                        color: AppColors.primaryPurple,
                        action: onEdit
                    )
                    
                    ActionButton(
                        icon: "trash",
                        color: Color.red,
                        action: onDelete
                    )
                }
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

// MARK: - Initials Avatar View
struct InitialsAvatarView: View {
    let name: String
    
    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
    
    var body: some View {
        Text(initials.uppercased())
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: [AppColors.primaryPurple, AppColors.accentPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var query: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: $query)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Group Selection Row
struct GroupSelectionRow: View {
    let group: SelectionItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(group.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3))
                    .font(.system(size: 24))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Snackbar View
struct SnackbarView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(AppTypography.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.primaryDark.opacity(0.95))
            .cornerRadius(8)
            .padding(.bottom, 20)
    }
}

// MARK: - Fake Repository
class FakeManagementRepository: ObservableObject {
    private var users: [MgmtUser] = [
        MgmtUser(id: 1, username: "john_doe", email: "john@example.com"),
        MgmtUser(id: 2, username: "jane_smith", email: "jane@example.com"),
        MgmtUser(id: 3, username: "bob_wilson", email: "bob@example.com"),
        MgmtUser(id: 4, username: "alice_brown", email: "alice@example.com"),
        MgmtUser(id: 5, username: "charlie_davis", email: "charlie@example.com")
    ]
    
    private var groups: [SelectionItem] = [
        SelectionItem(id: 1, name: "Administrators"),
        SelectionItem(id: 2, name: "Users"),
        SelectionItem(id: 3, name: "Guests"),
        SelectionItem(id: 4, name: "Moderators"),
        SelectionItem(id: 5, name: "Developers")
    ]
    
    private var userGroups: [Int: [Int]] = [
        1: [1, 2],
        2: [2],
        3: [2, 3],
        4: [2, 4],
        5: [1, 5]
    ]
    
    func getUsers() -> [MgmtUser] {
        return users
    }
    
    func getGroups() -> [SelectionItem] {
        return groups
    }
    
    func getUserGroups(userId: Int) -> Set<Int> {
        return Set(userGroups[userId] ?? [])
    }
    
    func fetchGroupsForUser(userId: Int) -> ([SelectionItem], Set<Int>) {
        let allGroups = getGroups()
        let userGroupIds = getUserGroups(userId: userId)
        return (allGroups, userGroupIds)
    }
    
    func deleteUser(userId: Int) {
        users.removeAll { $0.id == userId }
        userGroups.removeValue(forKey: userId)
    }
    
    func resetPassword(userId: Int) {
        // Simulate password reset
        print("Password reset for user ID: \(userId)")
    }
    
    func updateUserGroups(userId: Int, groupIds: [Int]) {
        userGroups[userId] = groupIds
        print("Updated groups for user \(userId): \(groupIds)")
    }
}

// MARK: - Preview
struct UserManagementScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserManagementScreen()
        }
    }
}
