import SwiftUI

// MARK: - Setting Screen
struct SettingScreen: View {
    @StateObject private var viewModel = SettingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToUserManagement = false
    
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
                    
                    Text("Setting")
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Rectangle()
                        .frame(width: 30, height: 30)
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(AppColors.appBackground)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 8)
                        
                        // 1. Email Card
                        SettingItemCard(
                            title: "Email",
                            icon: "envelope.fill"
                        ) {
                            // Navigate to Email Edit
                            print("Email tapped")
                        }
                        
                        // 2. Username Card
                        SettingItemCard(
                            title: "Username",
                            icon: "person.circle.fill"
                        ) {
                            // Navigate to Username Edit
                            print("Username tapped")
                        }
                        
                        // 3. Management (Expandable) - Chỉ hiển thị nếu isAdmin
                        if viewModel.isAdmin {
                            ExpandableManagementCard(
                                title: "Management",
                                icon: "shield.lefthalf.filled",
                                isExpanded: $viewModel.isManagementExpanded
                            ) {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: UserManagementScreen(), isActive: $navigateToUserManagement) {
                                        EmptyView()
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Users",
                                        icon: "person.fill"
                                    ) {
                                        navigateToUserManagement = true
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Groups",
                                        icon: "person.3.fill"
                                    ) {
                                        print("Groups tapped")
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Roles",
                                        icon: "lock.shield.fill"
                                    ) {
                                        print("Roles tapped")
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Functions",
                                        icon: "puzzlepiece.extension.fill"
                                    ) {
                                        print("Functions tapped")
                                    }
                                }
                            }
                        }
                        
                        // 4. Premium Card
                        SettingItemCard(
                            title: "Get Premium Now",
                            icon: "crown.fill",
                            textColor: AppColors.primaryPurple
                        ) {
                            // Navigate to Premium
                            print("Premium tapped")
                        }
                        
                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Setting Item Card (Có mũi tên sang phải)
struct SettingItemCard: View {
    let title: String
    let icon: String
    var textColor: Color = AppColors.textPrimary
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surfaceWhite)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Management Sub Item (Item con trong menu Management)
struct ManagementSubItem: View {
    let title: String
    let icon: String
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20, height: 20)
                
                // Title
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceLight.opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

// MARK: - Expandable Management Card
struct ExpandableManagementCard: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: () -> AnyView
    
    init(title: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (Phần luôn hiển thị)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 24, height: 24)
                    
                    // Title
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Expand Arrow với animation
                    Image(systemName: "chevron.down")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Body (Phần xổ xuống)
            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Setting ViewModel
@MainActor
class SettingViewModel: ObservableObject {
    @Published var isAdmin: Bool = false
    @Published var isManagementExpanded: Bool = false
    
    init() {
        checkUserRole()
    }
    
    private func checkUserRole() {
        // TODO: Implement real user role check from UserPreferences/TokenManager
        // For now, set to true for demo
        isAdmin = true
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SettingScreen()
    }
}

