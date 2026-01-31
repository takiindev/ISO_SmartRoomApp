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
                
                ACControlScreen()
                    .tag(1)
                
                PropertiesScreen()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.clear)
            
            // Custom Bottom Navigation
            VStack {
                Spacer()
                BottomNavigationBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            NavigationItem(
                icon: "house.fill",
                title: "Home",
                isActive: selectedTab == 0
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0
                }
            }
            
            NavigationItem(
                icon: "snowflake",
                title: "AC Control",
                isActive: selectedTab == 1
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 1
                }
            }
            
            NavigationItem(
                icon: "gearshape.fill",
                title: "Properties",
                isActive: selectedTab == 2
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 2
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 8)
        .background(
            Color(red: 0.95, green: 0.94, blue: 1.0) // #f3f0ff
                .ignoresSafeArea(edges: .bottom)
        )
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
                // Icon with pill background when active
                Group {
                    if isActive {
                        HStack {
                            Image(systemName: icon)
                                .font(.system(size: 20))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.89, green: 0.86, blue: 1.0)) // #e2dbff
                        )
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .padding(.vertical, 6)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(isActive ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color(red: 0.56, green: 0.56, blue: 0.58)) // #8b5cf6 : #8e8e93
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView(onLogout: {
        print("Logout in preview")
    })
}
