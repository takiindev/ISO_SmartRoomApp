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
    @State private var clients: [GroupClient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Dialog States
    @State private var showDeleteDialog = false
    @State private var userToDelete: MgmtUser?
    @State private var showResetDialog = false
    @State private var userToReset: MgmtUser?
    
    // Navigation State
    @State private var navigateToDetail = false
    @State private var selectedClient: GroupClient?
    @State private var showAddUserSheet = false
    
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    
    var filteredClients: [GroupClient] {
        if searchQuery.isEmpty {
            return clients
        }
        return clients.filter {
            $0.username.localizedCaseInsensitiveContains(searchQuery)
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
                            loadUsers()
                        }
                        .font(AppTypography.titleMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryPurple)
                        .cornerRadius(8)
                    }
                    .padding(20)
                } else if filteredClients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary)
                        Text(searchQuery.isEmpty ? "No users yet" : "No users found")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            NavigationLink(
                                destination: selectedClient.map { UserDetailScreen(client: $0).id($0.id) },
                                isActive: $navigateToDetail
                            ) {
                                EmptyView()
                            }
                            
                            ForEach(filteredClients) { client in
                                ClientItemView(
                                    client: client,
                                    onEdit: {
                                        // TODO: Add edit functionality
                                    },
                                    onDelete: {
                                        // TODO: Implement delete
                                    },
                                    onReset: {
                                        // TODO: Implement reset password
                                    },
                                    onPermission: {
                                        selectedClient = client
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
                        showAddUserSheet = true
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
        .sheet(isPresented: $showAddUserSheet) {
            AddUserSheet(onAdd: { username, password, clientType, ipAddress, macAddress, avatarUrl in
                Task {
                    await createNewUser(
                        username: username,
                        password: password,
                        clientType: clientType,
                        ipAddress: ipAddress,
                        macAddress: macAddress,
                        avatarUrl: avatarUrl
                    )
                }
            })
        }
    }
    
    private func loadUsers() {
        Task {
            await performLoadUsers()
        }
    }
    
    @MainActor
    private func performLoadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            clients = try await SmartRoomAPIService.shared.getAllClients()
            isLoading = false
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
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
    
    @MainActor
    private func createNewUser(
        username: String,
        password: String,
        clientType: String,
        ipAddress: String?,
        macAddress: String?,
        avatarUrl: String?
    ) async {
        do {
            _ = try await SmartRoomAPIService.shared.createClient(
                username: username,
                password: password,
                clientType: clientType,
                ipAddress: ipAddress,
                macAddress: macAddress,
                avatarUrl: avatarUrl
            )
            
            // Close sheet and reload
            showAddUserSheet = false
            loadUsers()
            showSnackbarMessage("User \(username) created successfully")
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
        }
    }
}

// MARK: - User Detail Screen
struct UserDetailScreen: View {
    let client: GroupClient
    
    @Environment(\.presentationMode) var presentationMode
    @State private var groupsWithStatus: [GroupWithStatus] = []
    @State private var originalGroupsWithStatus: [GroupWithStatus] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // User Info Section
                VStack(spacing: 16) {
                    // Avatar
                    InitialsAvatarView(name: client.username)
                        .frame(width: 80, height: 80)
                    
                    // User Info
                    VStack(spacing: 4) {
                        Text(client.username)
                            .font(AppTypography.headlineMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("ID: \(client.id)")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(client.clientType)
                            .font(.caption)
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
                    .padding(20)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(groupsWithStatus.indices, id: \.self) { index in
                                GroupCheckboxRowWithStatus(
                                    group: groupsWithStatus[index],
                                    onToggle: {
                                        groupsWithStatus[index].isAssignedToClient.toggle()
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
                Text("Assign Groups")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .onAppear {
            // Reset state first to clear previous user's data
            groupsWithStatus = []
            originalGroupsWithStatus = []
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
            // Fetch all groups with client assignment status
            groupsWithStatus = try await SmartRoomAPIService.shared.getGroupsWithClientStatus(clientId: client.id)
            // Store original state for comparison
            originalGroupsWithStatus = groupsWithStatus
            isLoading = false
        } catch {
            errorMessage = "Failed to load groups: \(error.localizedDescription)"
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
        let currentAssigned = Set(groupsWithStatus.filter { $0.isAssignedToClient }.map { $0.id })
        let originalAssigned = Set(originalGroupsWithStatus.filter { $0.isAssignedToClient }.map { $0.id })
        
        // Groups to assign (newly checked)
        let toAssign = currentAssigned.subtracting(originalAssigned)
        // Groups to unassign (newly unchecked)
        let toUnassign = originalAssigned.subtracting(currentAssigned)
        
        do {
            // Assign new groups
            if !toAssign.isEmpty {
                _ = try await SmartRoomAPIService.shared.assignGroupsToClient(
                    clientId: client.id,
                    groupIds: Array(toAssign)
                )
            }
            
            // Unassign removed groups
            if !toUnassign.isEmpty {
                try await SmartRoomAPIService.shared.unassignGroupsFromClient(
                    clientId: client.id,
                    groupIds: Array(toUnassign)
                )
            }
            
            // Dismiss after successful save
            presentationMode.wrappedValue.dismiss()
            
        } catch {
            // Handle error silently or show error in UI if needed
            isSaving = false
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - Add User Sheet
struct AddUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var clientType: String = "USER"
    @State private var ipAddress: String = ""
    @State private var macAddress: String = ""
    @State private var avatarUrl: String = ""
    @State private var isSubmitting: Bool = false
    
    let onAdd: (String, String, String, String?, String?, String?) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 8)
                            
                            // Username Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Username (3-100 chars)", text: $username)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                                    .autocapitalization(.none)
                            }
                            
                            // Password Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                SecureField("Password (6-100 chars)", text: $password)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                            }
                            
                            // Client Type Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client Type")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Picker("Client Type", selection: $clientType) {
                                    Text("USER").tag("USER")
                                    Text("HARDWARE_GATEWAY").tag("HARDWARE_GATEWAY")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .background(AppColors.surfaceWhite)
                                .cornerRadius(12)
                            }
                            
                            // IP Address Input (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("IP Address (Optional)")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("192.168.1.x", text: $ipAddress)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                                    .keyboardType(.numbersAndPunctuation)
                                    .autocapitalization(.none)
                            }
                            
                            // MAC Address Input (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MAC Address (Optional)")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("AA:BB:CC:DD:EE:FF", text: $macAddress)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                                    .autocapitalization(.none)
                            }
                            
                            // Avatar URL Input (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Avatar URL (Optional)")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                TextField("https://example.com/avatar.png", text: $avatarUrl)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                            }
                            
                            Spacer().frame(height: 16)
                            
                            // Add Button
                            Button(action: {
                                if isValidForm() && !isSubmitting {
                                    isSubmitting = true
                                    onAdd(
                                        username,
                                        password,
                                        clientType,
                                        ipAddress.isEmpty ? nil : ipAddress,
                                        macAddress.isEmpty ? nil : macAddress,
                                        avatarUrl.isEmpty ? nil : avatarUrl
                                    )
                                }
                            }) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isSubmitting ? "Creating..." : "Add User")
                                        .font(AppTypography.titleMedium)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    (isValidForm() && !isSubmitting)
                                        ? AppColors.primaryPurple
                                        : AppColors.textSecondary.opacity(0.3)
                                )
                                .cornerRadius(12)
                            }
                            .disabled(!isValidForm() || isSubmitting)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Add New User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func isValidForm() -> Bool {
        return username.count >= 3 && username.count <= 100 &&
               password.count >= 6 && password.count <= 100
    }
}

// MARK: - Client Item View
struct ClientItemView: View {
    let client: GroupClient
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    let onPermission: () -> Void
    
    var body: some View {
        Button(action: onPermission) {
            HStack(spacing: 12) {
                // Avatar
                InitialsAvatarView(name: client.username)
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.username)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("ID: \(client.id)")
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
    
    private func formatLastLogin(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Modern User Item View (Legacy - kept for compatibility)
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

// MARK: - Group Checkbox Row with Status (Using GroupWithStatus model)
struct GroupCheckboxRowWithStatus: View {
    let group: GroupWithStatus
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: group.isAssignedToClient ? "checkmark.square.fill" : "square")
                    .foregroundColor(group.isAssignedToClient ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3))
                    .font(.system(size: 24))
                
                // Group Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.groupCode)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Group Checkbox Row (Multiple Selection)
struct GroupCheckboxRow: View {
    let group: MgmtGroup
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3))
                    .font(.system(size: 24))
                
                // Group Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.code)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Group Radio Row (Legacy - Single Selection)
struct GroupRadioRow: View {
    let group: MgmtGroup
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primaryPurple)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Group Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.code)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.surfaceWhite)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Group Selection Row (Legacy - Multiple Selection)
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
    
    private var mgmtGroups: [MgmtGroup] = [
        MgmtGroup(id: 1, code: "Administrators", name: "Administrators", description: "System administrators"),
        MgmtGroup(id: 2, code: "Users", name: "Users", description: "Regular users"),
        MgmtGroup(id: 3, code: "Guests", name: "Guests", description: "Guest users"),
        MgmtGroup(id: 4, code: "Moderators", name: "Moderators", description: "Content moderators"),
        MgmtGroup(id: 5, code: "Developers", name: "Developers", description: "Development team")
    ]
    
    private var userGroups: [Int: [Int]] = [
        1: [1, 2],
        2: [2],
        3: [2, 3],
        4: [2, 4],
        5: [1, 5]
    ]
    
    private var groupUsers: [Int: [Int]] = [
        1: [1, 5],
        2: [1, 2, 3, 4],
        3: [3],
        4: [4],
        5: [5]
    ]
    
    func getUsers() -> [MgmtUser] {
        return users
    }
    
    func getGroupsAsSelectionItems() -> [SelectionItem] {
        return groups
    }
    
    func getUserGroups(userId: Int) -> Set<Int> {
        return Set(userGroups[userId] ?? [])
    }
    
    func fetchGroupsForUser(userId: Int) -> ([SelectionItem], Set<Int>) {
        let allGroups = getGroupsAsSelectionItems()
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
    
    // MARK: - Group Management Methods
    func getGroups() -> [MgmtGroup] {
        return mgmtGroups
    }
    
    func deleteGroup(groupId: Int) {
        mgmtGroups.removeAll { $0.id == groupId }
        groupUsers.removeValue(forKey: groupId)
    }
    
    func getUsersByGroup(groupId: Int) -> [MgmtUser] {
        let userIds = groupUsers[groupId] ?? []
        return users.filter { userIds.contains($0.id) }
    }
    
    func updateGroupUsers(groupId: Int, userIds: [Int]) {
        groupUsers[groupId] = userIds
        print("Updated users for group \(groupId): \(userIds)")
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
