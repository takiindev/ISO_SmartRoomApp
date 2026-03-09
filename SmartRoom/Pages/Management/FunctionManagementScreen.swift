import SwiftUI

// MARK: - Main Screen
struct FunctionManagementScreen: View {
    @StateObject private var repository = FakeRoleRepository()
    @State private var functions: [MgmtFunction] = []
    @State private var searchQuery = ""
    @State private var isLoading = true
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
                                    onEdit: {},
                                    onDelete: {}
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadFunctions()
        }
    }
    
    private func loadFunctions() {
        Task {
            await performLoadFunctions()
        }
    }
    
    @MainActor
    private func performLoadFunctions() async {
        isLoading = true
        
        do {
            let apiFunctions = try await SmartRoomAPIService.shared.getAllFunctions()
            functions = apiFunctions.map { MgmtFunction(from: $0) }
            isLoading = false
        } catch {
            print("Failed to load functions: \(error.localizedDescription)")
            isLoading = false
        }
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
                    Text(function.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(function.code)
                        .font(.caption)
                        .foregroundColor(Color(hex: 0x3498DB))
                    
                    if let desc = function.description, !desc.isEmpty {
                        Text(desc)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
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
