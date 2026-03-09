import SwiftUI

// MARK: - Setting Screen
struct SettingScreen: View {
    @StateObject private var viewModel = SettingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToUserManagement = false
    @State private var navigateToRoleManagement = false
    @State private var navigateToGroupManagement = false
    @State private var navigateToFunctionManagement = false
    @State private var navigateToAutomation = false
    @State private var navigateToRules = false
    @State private var showLogoutAlert = false
    
    var onLogout: (() -> Void)?
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 0) {
                        // Hidden Navigation Links
                        NavigationLink(destination: AutomationScreen(), isActive: $navigateToAutomation) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        NavigationLink(destination: RulesScreen(), isActive: $navigateToRules) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        NavigationLink(destination: UserManagementScreen(), isActive: $navigateToUserManagement) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        NavigationLink(destination: GroupManagementScreen(), isActive: $navigateToGroupManagement) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        NavigationLink(destination: RoleManagementScreen(), isActive: $navigateToRoleManagement) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        NavigationLink(destination: FunctionManagementScreen(), isActive: $navigateToFunctionManagement) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                    }

                    VStack(spacing: 14) {
                        spotlightCard

                        // 1. Email Card
                        SettingItemCard(
                            title: "Email",
                            icon: "envelope.fill",
                            subtitle: "Cập nhật email đăng nhập",
                            accentColor: Color(hex: 0x3B82F6)
                        ) {
                            // Navigate to Email Edit
                            print("Email tapped")
                        }
                        
                        // 2. Username Card
                        SettingItemCard(
                            title: "Username",
                            icon: "person.circle.fill",
                            subtitle: "Thay đổi tên hiển thị",
                            accentColor: Color(hex: 0x0EA5A7)
                        ) {
                            // Navigate to Username Edit
                            print("Username tapped")
                        }
                        
                        // 3. Automation Card - Chỉ hiển thị nếu isAdmin
                        if viewModel.isAdmin {
                            SettingItemCard(
                                title: "Automation",
                                icon: "wand.and.stars",
                                subtitle: "Quản lý lịch tự động",
                                accentColor: AppColors.primaryPurple
                            ) {
                                navigateToAutomation = true
                            }
                        }
                        
                        // 3.5. Rules Card - Chỉ hiển thị nếu isAdmin
                        if viewModel.isAdmin {
                            SettingItemCard(
                                title: "Rules",
                                icon: "list.bullet.rectangle",
                                subtitle: "Thiết lập rule theo điều kiện",
                                accentColor: Color(hex: 0x14B8A6)
                            ) {
                                navigateToRules = true
                            }
                        }
                        
                        // 4. Management (Expandable) - Chỉ hiển thị nếu isAdmin
                        if viewModel.isAdmin {
                            ExpandableManagementCard(
                                title: "Management",
                                icon: "shield.lefthalf.filled",
                                isExpanded: $viewModel.isManagementExpanded
                            ) {
                                VStack(spacing: 0) {
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
                                        navigateToGroupManagement = true
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Roles",
                                        icon: "lock.shield.fill"
                                    ) {
                                        navigateToRoleManagement = true
                                    }
                                    
                                    ManagementSubItem(
                                        title: "Functions",
                                        icon: "puzzlepiece.extension.fill"
                                    ) {
                                        navigateToFunctionManagement = true
                                    }
                                }
                            }
                        }
                        
                        // 5. Premium Card
                        SettingItemCard(
                            title: "Get Premium Now",
                            icon: "crown.fill",
                            subtitle: "Mở khoá thêm tính năng nâng cao",
                            textColor: AppColors.primaryPurple,
                            accentColor: Color(hex: 0xF59E0B)
                        ) {
                            // Navigate to Premium
                            print("Premium tapped")
                        }
                        
                        // 6. Logout Card (Màu đỏ)
                        SettingItemCard(
                            title: "Logout",
                            icon: "rectangle.portrait.and.arrow.right",
                            subtitle: "Đăng xuất khỏi thiết bị hiện tại",
                            textColor: Color(hex: 0xDC2626),
                            accentColor: Color(hex: 0xDC2626),
                            cardTint: Color(hex: 0xFEF2F2).opacity(0.88)
                        ) {
                            showLogoutAlert = true
                        }

                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }

            Spacer()

            Text("Setting")
                .font(AppTypography.headlineMedium)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var spotlightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SmartRoom Preferences")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(viewModel.isAdmin
                 ? "Admin mode đang bật, bạn có thể quản lý Automation, Rules và phân quyền hệ thống."
                 : "Tinh chỉnh hồ sơ cá nhân và bảo mật tài khoản của bạn trong một nơi duy nhất.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(2)

            HStack(spacing: 8) {
                SettingStatusChip(
                    title: viewModel.isAdmin ? "ADMIN" : "USER",
                    icon: "person.badge.shield.checkmark",
                    color: viewModel.isAdmin ? AppColors.primaryPurple : Color(hex: 0x0EA5A7)
                )
                SettingStatusChip(
                    title: "Secure",
                    icon: "lock.shield",
                    color: Color(hex: 0x2563EB)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Logout Handler
    private func handleLogout() {
        print("User initiated logout from Settings")
        
        // Logout sẽ xóa token nhưng giữ lại API URL và Remember Me (nếu có)
        TokenManager.shared.logout()
        
        // Dismiss về màn hình trước (thoát khỏi Settings)
        dismiss()
        
        // Gọi callback để HomeScreen/AuthenticationWrapper handle logout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onLogout?()
        }
    }
}

// MARK: - Setting Item Card (Có mũi tên sang phải)
struct SettingItemCard: View {
    let title: String
    let icon: String
    var subtitle: String? = nil
    var textColor: Color = AppColors.textPrimary
    var accentColor: Color = AppColors.primaryPurple
    var cardTint: Color = Color.white.opacity(0.92)
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.72))
                    .clipShape(Circle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(cardTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.primaryPurple.opacity(0.14), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct SettingStatusChip: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14))
        .cornerRadius(999)
    }
}

// MARK: - Management Sub Item (Item con trong menu Management)
struct ManagementSubItem: View {
    let title: String
    let icon: String
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.surfaceLight.opacity(0.6))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryPurple)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.82), lineWidth: 1)
                    )
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
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.primaryPurple.opacity(0.14))
                            .frame(width: 36, height: 36)

                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryPurple)
                    }

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.72))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.14), radius: 10, x: 0, y: 5)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24))
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
        // Lấy groups từ TokenManager và kiểm tra quyền admin
        if let groups = TokenManager.shared.getGroups() {
            isAdmin = groups.contains("G_ADMIN")
        } else {
            isAdmin = false
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SettingScreen()
    }
}

