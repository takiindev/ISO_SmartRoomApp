import SwiftUI

// MARK: - Main Screen
struct GroupManagementScreen: View {
    @StateObject private var repository = FakeManagementRepository()
    @State private var groups: [MgmtGroup] = []
    @State private var searchQuery = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteDialog = false
    @State private var groupToDelete: MgmtGroup?
    @State private var isDeleting = false
    @State private var navigateToMembers = false
    @State private var selectedGroup: MgmtGroup?
    @State private var showAddGroupSheet = false
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
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Text("❌ Error")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
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
                    .padding(20)
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
                        showAddGroupSheet = true
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
        .sheet(isPresented: $showAddGroupSheet) {
            AddGroupSheet(onAdd: { groupCode, groupName, description in
                Task {
                    await createNewGroup(groupCode: groupCode, name: groupName, description: description)
                }
            })
        }
        .alert("Delete Group?", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {
                groupToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    Task {
                        await performDeleteGroup(group)
                    }
                }
            }
        } message: {
            if let group = groupToDelete {
                Text("This will permanently delete group '\(group.code)'.")
            }
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
            groups = apiGroups.map { MgmtGroup(from: $0) }
            isLoading = false
        } catch {
            errorMessage = "Failed to load groups: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func deleteGroup(_ group: MgmtGroup) {
        repository.deleteGroup(groupId: group.id)
        loadGroups()
        groupToDelete = nil
    }
    
    @MainActor
    private func performDeleteGroup(_ group: MgmtGroup) async {
        isDeleting = true
        
        do {
            try await SmartRoomAPIService.shared.deleteGroup(groupId: group.id)
            
            // Success - reload list
            groupToDelete = nil
            isDeleting = false
            loadGroups()
        } catch let error as SmartRoomAPIError {
            isDeleting = false
            groupToDelete = nil
            
            switch error {
            case .networkError(let message):
                // Parse error message from API
                errorMessage = message
            default:
                errorMessage = "Failed to delete group: \(error.localizedDescription)"
            }
        } catch {
            isDeleting = false
            groupToDelete = nil
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func createNewGroup(groupCode: String, name: String, description: String) async {
        do {
            let newGroup = try await SmartRoomAPIService.shared.createGroup(
                groupCode: groupCode,
                name: name,
                description: description.isEmpty ? nil : description
            )
            
            // Close sheet and reload
            showAddGroupSheet = false
            loadGroups()
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
        }
    }
}

// MARK: - Add Group Sheet
struct AddGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupCode: String = ""
    @State private var groupName: String = ""
    @State private var description: String = ""
    @State private var isSubmitting: Bool = false
    
    let onAdd: (String, String, String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 8)
                            
                            // Group Code Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Group Code")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Group Code", text: $groupCode)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                            }
                            
                            // Group Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Group Name")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Group Name", text: $groupName)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                            }
                            
                            // Description Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                TextField("Description", text: $description)
                                    .font(AppTypography.bodyMedium)
                                    .padding(16)
                                    .background(AppColors.surfaceWhite)
                                    .cornerRadius(12)
                            }
                            
                            Spacer().frame(height: 16)
                            
                            // Add Button
                            Button(action: {
                                if !groupCode.isEmpty && !groupName.isEmpty && !isSubmitting {
                                    isSubmitting = true
                                    onAdd(groupCode, groupName, description)
                                }
                            }) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isSubmitting ? "Creating..." : "Add Group")
                                        .font(AppTypography.titleMedium)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    (!groupCode.isEmpty && !groupName.isEmpty && !isSubmitting) 
                                        ? AppColors.primaryPurple 
                                        : AppColors.textSecondary.opacity(0.3)
                                )
                                .cornerRadius(12)
                            }
                            .disabled(groupCode.isEmpty || groupName.isEmpty || isSubmitting)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Add New Group")
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
                    Text(group.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(group.code)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(Color(hex: 0x2ECC71))
                    
                    if let desc = group.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
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
    @State private var clients: [GroupClient] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchQuery = ""
    @State private var showDeleteDialog = false
    @State private var clientToDelete: GroupClient?
    @State private var showSnackbar = false
    @State private var snackbarMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var filteredClients: [GroupClient] {
        if searchQuery.isEmpty {
            return clients
        }
        return clients.filter { $0.username.localizedCaseInsensitiveContains(searchQuery) }
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
                    
                    Text("\(group.code) Members")
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
                    placeholder: "Search members..."
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Members List
                if isLoading {
                    ManagementLoadingView()
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
                            loadClients()
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
                    ManagementEmptyStateView(
                        icon: "person.2.fill",
                        message: searchQuery.isEmpty ? "No members yet" : "No members found"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(filteredClients) { client in
                                GroupClientItemView(
                                    client: client,
                                    onRemove: {
                                        clientToDelete = client
                                        showDeleteDialog = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
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
            loadClients()
        }
        .alert("Remove Member?", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {
                clientToDelete = nil
            }
            Button("Remove", role: .destructive) {
                if let client = clientToDelete {
                    Task {
                        await performRemoveClient(client)
                    }
                }
            }
        } message: {
            if let client = clientToDelete {
                Text("Remove '\(client.username)' from group '\(group.code)'?")
            }
        }
    }
    
    private func loadClients() {
        Task {
            await performLoadClients()
        }
    }
    
    @MainActor
    private func performLoadClients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            clients = try await SmartRoomAPIService.shared.getGroupClients(groupId: group.id)
            isLoading = false
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    private func performRemoveClient(_ client: GroupClient) async {
        do {
            try await SmartRoomAPIService.shared.removeClientFromGroup(clientId: client.id, groupId: group.id)
            clientToDelete = nil
            loadClients()
            snackbarMessage = "Removed \(client.username) from group"
            showSnackbar = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSnackbar = false
            }
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }
    }
}

// MARK: - Group Client Item View
struct GroupClientItemView: View {
    let client: GroupClient
    let onRemove: () -> Void
    
    var body: some View {
        ManagementItemCard(onClick: {}) {
            HStack(spacing: 12) {
                // Avatar with initials
                ManagementInitialsAvatar(
                    name: client.username,
                    size: 48,
                    backgroundColor: AppColors.primaryPurple
                )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.username)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        // Client Type Badge
                        Text(client.clientType)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0x3498DB))
                            .cornerRadius(4)
                        
                        // Last Login
                        if let lastLogin = client.lastLoginAt {
                            Text(formatLastLogin(lastLogin))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    // IP Address
                    if let ipAddress = client.ipAddress {
                        HStack(spacing: 4) {
                            Image(systemName: "network")
                                .font(.caption)
                            Text(ipAddress)
                                .font(.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Remove Button
                ManagementActionButton(
                    icon: "xmark.circle.fill",
                    color: .red,
                    action: onRemove
                )
            }
        }
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

// MARK: - Preview
struct GroupManagementScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupManagementScreen()
        }
    }
}
