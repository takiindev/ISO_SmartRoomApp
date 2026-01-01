import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        NavigationView {
            List {
                // Email
                SettingsRow(icon: Image(systemName: "envelope"), title: "Email")
                
                // Username
                SettingsRow(icon: Image(systemName: "person"), title: "Username")
                
                // Management - dropdown với 1 icon xoay duy nhất
                Section {
                    DisclosureGroup {
                        SubSettingsRow(title: "Floors")
                        SubSettingsRow(title: "Rooms")
                        SubSettingsRow(title: "Devices")
                        SubSettingsRow(title: "Users")
                        SubSettingsRow(title: "Groups")
                        SubSettingsRow(title: "Roles")
                    } label: {
                        ManagementRow()
                    }
                }
                
                // Nút Get Premium
                Button(action: {
                    print("Get Premium tapped")
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                        
                        Text("Get Premium Now")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue.opacity(0.7))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Setting")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Row chính (Email, Username)
struct SettingsRow: View {
    let icon: Image
    let title: String
    
    var body: some View {
        HStack {
            icon
                .frame(width: 24, height: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: 17))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.7))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Row Management: chỉ 1 icon chevron, xoay khi mở/đóng
struct ManagementRow: View {
    @State private var isExpanded = false  // <-- ĐÃ THÊM DÒNG NÀY (nguyên nhân lỗi trước)
    
    var body: some View {
        HStack {
            Image(systemName: "building.2.crop.circle")
                .frame(width: 24, height: 24)
                .foregroundColor(.secondary)
            
            Text("Management")
                .font(.system(size: 17))
            
            Spacer()
            
            // Chỉ 1 icon duy nhất
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.7))
                .font(.system(size: 14, weight: .bold))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Row con (thụt lề)
struct SubSettingsRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Spacer().frame(width: 48)
            
            Text(title)
                .font(.system(size: 17))
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.7))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
    }
}

// MARK: - Preview (sẽ hiện ngay và đẹp)
#Preview {
    NavigationView {
        SettingsScreen()
    }
}
