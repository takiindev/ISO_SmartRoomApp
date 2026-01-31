import SwiftUI

// MARK: - Room AC List Screen
struct RoomACListScreen: View {
    let room: Room
    @State private var airConditioners: [ACDevice] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                // Content
                if isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                            .scaleEffect(1.5)
                        Text("Đang tải danh sách điều hòa...")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.accentPink)
                        
                        Text("Lỗi")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(error)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Thử lại") {
                            loadAirConditioners()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryPurple)
                        .foregroundColor(AppColors.surfaceWhite)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else if airConditioners.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "snowflake.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Phòng này chưa có điều hòa")
                            .font(AppTypography.titleMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Vui lòng thêm thiết bị điều hòa")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach($airConditioners) { $ac in
                                RoomACCard(device: $ac)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadAirConditioners()
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Air Conditioning")
                    .font(AppTypography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(room.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private func loadAirConditioners() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let acs = try await SmartRoomAPIService.shared.getAirConditionsByRoom(room.id)
                await MainActor.run {
                    airConditioners = acs.map { ACDevice(from: $0) }
                    isLoading = false
                }
            } catch SmartRoomAPIError.tokenExpired {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Phiên đăng nhập đã hết hạn"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Room AC Card
struct RoomACCard: View {
    @Binding var device: ACDevice
    @State private var isToggling: Bool = false
    @State private var navigateToDetail: Bool = false
    
    var body: some View {
        ZStack {
            // Hidden NavigationLink
            NavigationLink(destination: ACDetailScreen(device: device), isActive: $navigateToDetail) {
                EmptyView()
            }
            .hidden()
            
            HStack(spacing: 15) {
                // Icon + Info
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(AppColors.surfaceWhite)
                            .frame(width: 55, height: 55)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "snowflake")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 8) {
                            Text("\(device.temperature)°C")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primaryPurple)
                            
                            Text("•")
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            
                            Text(device.mode)
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        }
                        
                        Text(device.isOn ? "ON" : "OFF")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(device.isOn ? Color.green : AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Toggle Switch
                ZStack {
                    if isToggling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Toggle("", isOn: $device.isOn)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.0, green: 0.48, blue: 1.0)))
                            .disabled(isToggling)
                            .onChange(of: device.isOn) { oldValue, newValue in
                                if !isToggling && oldValue != newValue {
                                    sendToggleToServer(newValue: newValue, previousValue: oldValue)
                                }
                            }
                    }
                }
                .frame(width: 51, height: 31)
            }
            .padding(20)
            .background(AppColors.surfaceWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            .contentShape(Rectangle())
            .onTapGesture {
                navigateToDetail = true
            }
        }
    }
    
    private func sendToggleToServer(newValue: Bool, previousValue: Bool) {
        isToggling = true
        
        Task {
            let power = newValue ? "ON" : "OFF"
            do {
                _ = try await SmartRoomAPIService.shared.updateAirCondition(device.id, power: power)
            } catch {
                print("⚠️ Failed to send toggle to server: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isToggling = false
            }
        }
    }
}

#Preview {
    RoomACListScreen(room: Room(id: 1, name: "Living Room", floorId: 1, description: "Main room"))
}
