import SwiftUI

struct MainTabView: View {
    let onLogout: () -> Void
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            // Content
            TabView(selection: $selectedTab) {
                HomeScreenContent(onLogout: onLogout)
                    .tag(0)
                
                AlertScreen()
                    .tag(1)
                
                PropertiesScreen()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.clear)
        }
        .safeAreaInset(edge: .bottom) {
            BottomNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 8) {
            NavigationItem(
                icon: "house.fill",
                title: "Home",
                isActive: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    selectedTab = 0
                }
            }
            
            NavigationItem(
                icon: "bell.badge.fill",
                title: "Alerts",
                isActive: selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    selectedTab = 1
                }
            }
            
            NavigationItem(
                icon: "slider.horizontal.3",
                title: "Properties",
                isActive: selectedTab == 2
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    selectedTab = 2
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.16), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Navigation Item
struct NavigationItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? AppColors.primaryPurple.opacity(0.18) : Color.clear)
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 11, weight: isActive ? .bold : .semibold))
            }
            .foregroundColor(isActive ? AppColors.primaryPurple : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? AppColors.primaryPurple.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
    }
}

#Preview {
    MainTabView(onLogout: {
        print("Logout in preview")
    })
}
