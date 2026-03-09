import SwiftUI

// MARK: - Home Screen Content View (MVVM)
struct HomeScreenContent: View {
    let onLogout: () -> Void
    @StateObject private var viewModel = HomeViewModel()

    private var summaryText: String {
        "\(viewModel.floors.count) tầng • \(viewModel.allRooms.count) phòng"
    }
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    LazyVStack(spacing: 14) {
                        HeroWeatherCard()
                        .padding(.top, 8)
                        
                        SmartModesSection(activeMode: $viewModel.activeMode)
                        
                        SegmentedControlView(selectedTab: $viewModel.selectedTab)
                        
                        if viewModel.isLoading && viewModel.floors.isEmpty {
                            LoadingView()
                        } else if let error = viewModel.errorMessage {
                            ErrorView(message: error) {
                                viewModel.retry()
                            }
                        } else if viewModel.selectedTab == 0 {
                            VStack(spacing: 16) {
                                if viewModel.floors.isEmpty {
                                    EmptyFloorsView()
                                } else {
                                    ForEach(viewModel.floors) { floor in
                                        let roomsInFloor = viewModel.getRoomsForFloor(floor.id)
                                        FloorSectionView(
                                            floorName: "\(floor.name) • \(roomsInFloor.count) phòng",
                                            rooms: roomsInFloor,
                                            onRefresh: {
                                                viewModel.loadFloorsAndRooms()
                                            }
                                        )
                                    }
                                }
                            }
                        } else {
                            DevicesView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            viewModel.loadFloorsAndRooms()
        }
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            viewModel.onTabChanged()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("My Home")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text(summaryText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            NavigationLink(destination: SettingScreen(onLogout: onLogout)) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Hero Weather Card
struct HeroWeatherCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My location")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)

                    Text("Montreal")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                Text("-10°")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("Partly Cloudy")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.14), radius: 10, x: 0, y: 5)
    }
}

private struct HomeStatusChip: View {
    let icon: String
    let title: String
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

// MARK: - Smart Modes Section
struct SmartModesSection: View {
    @Binding var activeMode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Modes")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 10) {
                SmartModeCard(
                    title: "At Home",
                    subtitle: "All Active",
                    icon: "house.fill",
                    isActive: activeMode == "home"
                ) {
                    activeMode = "home"
                }
                
                SmartModeCard(
                    title: "Left Home",
                    subtitle: "Security On",
                    icon: "door.right.hand.open",
                    isActive: activeMode == "away"
                ) {
                    activeMode = "away"
                }
            }
        }
    }
}

struct SmartModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isActive ? Color.white.opacity(0.24) : AppColors.primaryPurple.opacity(0.14))
                            .frame(width: 34, height: 34)

                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isActive ? AppColors.surfaceWhite : AppColors.primaryPurple)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(isActive ? AppColors.surfaceWhite : AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(isActive ? AppColors.surfaceWhite.opacity(0.8) : AppColors.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isActive ? AppColors.primaryPurple : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.primaryPurple.opacity(isActive ? 0.2 : 0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Segmented Control
struct SegmentedControlView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 6) {
            SegmentButton(title: "Room", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            SegmentButton(title: "Devices", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? AppColors.primaryPurple : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppColors.primaryPurple.opacity(0.13) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                .scaleEffect(1.2)
            
            Text("Đang tải dữ liệu...")
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("❌ Lỗi")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.accentPink)
            
            Text(message)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Button("Thử lại") {
                retry()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.primaryPurple)
            .foregroundColor(AppColors.surfaceWhite)
            .cornerRadius(8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.accentPink.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty Floors View
struct EmptyFloorsView: View {
    var body: some View {
        Text("Không có tầng nào.")
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.88), lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Devices View
struct DevicesView: View {
    var body: some View {
        VStack {
            Text("Devices view coming soon...")
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Floor Section View
struct FloorSectionView: View {
    let floorName: String
    let rooms: [Room]
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(floorName)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button(action: {
                    onRefresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.primaryPurple)
                        .frame(width: 28, height: 28)
                        .background(AppColors.primaryPurple.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(rooms) { room in
                        NavigationLink(destination: RoomDetailScreen(room: room)) {
                            RoomCard(room: room)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    @State private var isOn: Bool = true

    private var cardWidth: CGFloat {
        // Keep card small enough so at least 2 cards are visible in each floor row.
        let outerHorizontalPadding: CGFloat = 16 * 2
        let floorContentPadding: CGFloat = 14 * 2
        let cardSpacing: CGFloat = 12
        let availableWidth = UIScreen.main.bounds.width - outerHorizontalPadding - floorContentPadding - cardSpacing
        let widthForTwoCards = availableWidth / 2
        return max(124, min(158, widthForTwoCards))
    }

    private var imageHeight: CGFloat {
        cardWidth * 0.6
    }
    
    private var roomImageURL: String {
        let imageId: Int
        switch room.name.lowercased() {
        case let name where name.contains("living") || name.contains("khách"):
            imageId = 1
        case let name where name.contains("bed") || name.contains("ngủ"):
            imageId = 2
        case let name where name.contains("kitchen") || name.contains("bếp"):
            imageId = 3
        default:
            imageId = room.id
        }
        return "https://picsum.photos/400/300?random=\(imageId)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: roomImageURL)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Rectangle()
                            .fill(AppColors.surfaceLight)
                        
                        VStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                            Text("Loading...")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(let error):
                    ZStack {
                        Rectangle()
                            .fill(AppColors.surfaceLight)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("No image")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                @unknown default:
                    Rectangle()
                        .fill(AppColors.surfaceLight)
                }
            }
            .frame(height: imageHeight)
            .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HomeStatusChip(
                        icon: "square.stack.3d.up.fill",
                        title: "\(room.deviceCount) \(room.deviceCount == 1 ? "device" : "devices")",
                        color: AppColors.primaryPurple
                    )
                }
                
                HStack {
                    Text(isOn ? "ON" : "OFF")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isOn ? AppColors.primaryPurple : AppColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((isOn ? AppColors.primaryPurple : AppColors.textSecondary).opacity(0.13))
                        .cornerRadius(999)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isOn)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryPurple))
                        .scaleEffect(0.8)
                }
            }
            .padding(16)
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.88), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.primaryPurple.opacity(0.12), radius: 8, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Preview
#Preview {
    HomeScreenContent(onLogout: {})
}
