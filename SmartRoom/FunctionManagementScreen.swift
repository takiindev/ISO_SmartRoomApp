import SwiftUI

// MARK: - Main Screen
struct FunctionManagementScreen: View {
    @StateObject private var repository = FakeRoleRepository()
    @State private var functions: [MgmtFunction] = []
    @State private var searchQuery = ""
    @State private var isLoading = true
    @State private var showDeleteDialog = false
    @State private var functionToDelete: MgmtFunction?
    @Environment(\.presentationMode) var presentationMode
    
    var filteredFunctions: [MgmtFunction] {
        if searchQuery.isEmpty {
            return functions
        }
        return functions.filter { $0.code.localizedCaseInsensitiveContains(searchQuery) }
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
                    
                    Text("Function Management")
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
                    placeholder: "Search functions..."
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Functions List
                if isLoading {
                    ManagementLoadingView()
                } else if filteredFunctions.isEmpty {
                    ManagementEmptyStateView(
                        icon: "puzzlepiece.extension.fill",
                        message: searchQuery.isEmpty ? "No functions yet" : "No functions found"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(filteredFunctions) { function in
                                ModernFunctionItemView(
                                    function: function,
                                    onEdit: {
                                        // TODO: Add edit functionality
                                        print("Edit function: \(function.code)")
                                    },
                                    onDelete: {
                                        functionToDelete = function
                                        showDeleteDialog = true
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
                        // TODO: Add function functionality
                        print("Add new function")
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
        }
        .navigationBarHidden(true)
        .onAppear {
            loadFunctions()
        }
        .alert("Delete Function?", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {
                functionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let function = functionToDelete {
                    deleteFunction(function)
                }
            }
        } message: {
            if let function = functionToDelete {
                Text("This will permanently delete function '\(function.code)'.")
            }
        }
    }
    
    private func loadFunctions() {
        functions = repository.getFunctions()
        isLoading = false
    }
    
    private func deleteFunction(_ function: MgmtFunction) {
        repository.deleteFunction(functionId: function.id)
        loadFunctions()
        functionToDelete = nil
    }
}

// MARK: - Function Item View
struct ModernFunctionItemView: View {
    let function: MgmtFunction
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ManagementItemCard(onClick: {}) {
            HStack(spacing: 12) {
                // Icon - Blue color
                ManagementIconBox(
                    icon: "puzzlepiece.extension.fill",
                    color: Color(hex: 0x3498DB)
                )
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(function.code)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(function.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
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

// MARK: - Preview
struct FunctionManagementScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FunctionManagementScreen()
        }
    }
}
