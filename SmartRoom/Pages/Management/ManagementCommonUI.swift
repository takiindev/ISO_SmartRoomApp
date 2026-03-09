import SwiftUI

// MARK: - Selection Item Model
struct ManagementSelectionItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    
    init(id: Int, title: String, subtitle: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - 1. Management Search Bar
struct ManagementSearchBar: View {
    @Binding var query: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField(placeholder, text: $query)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 2. Initials Avatar (For Users)
struct ManagementInitialsAvatar: View {
    let name: String
    let size: CGFloat
    let backgroundColor: Color
    
    init(name: String, size: CGFloat = 48, backgroundColor: Color = AppColors.primaryPurple) {
        self.name = name
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
    
    var body: some View {
        Text(initials.uppercased())
            .font(.system(size: size * 0.33, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [backgroundColor, backgroundColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

// MARK: - 3. Icon Box (For Groups/Functions)
struct ManagementIconBox: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    init(icon: String, color: Color, size: CGFloat = 48) {
        self.icon = icon
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - 4. Action Button (Small Action Button)
struct ManagementActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 5. Base Item Card (Container Frame)
struct ManagementItemCard<Content: View>: View {
    let onClick: () -> Void
    let content: Content
    
    init(onClick: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.onClick = onClick
        self.content = content()
    }
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 16) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 0.5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 6. Checkbox Item (For Selection)
struct ManagementCheckboxItem: View {
    let item: ManagementSelectionItem
    let isChecked: Bool
    let onCheckedChange: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onCheckedChange(!isChecked)
        }) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? AppColors.primaryPurple : AppColors.textSecondary.opacity(0.3))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isChecked ? AppColors.primaryPurple.opacity(0.05) : AppColors.surfaceWhite
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isChecked ? AppColors.primaryPurple.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 7. Member Item Row (For Group Members)
struct ManagementMemberItemRow: View {
    let userName: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Small Avatar
            ManagementInitialsAvatar(
                name: userName,
                size: 40,
                backgroundColor: AppColors.primaryPurple
            )
            
            // Name
            Text(userName)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "person.badge.minus")
                    .font(.system(size: 16))
                    .foregroundColor(Color.red.opacity(0.7))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: 0xF5F5F5))
        .cornerRadius(12)
    }
}

// MARK: - 8. Management Snackbar
struct ManagementSnackbar: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(AppTypography.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.primaryDark.opacity(0.95))
            .cornerRadius(8)
            .padding(.bottom, 20)
    }
}

// MARK: - 9. Empty State View
struct ManagementEmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text(message)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 10. Loading View
struct ManagementLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color Extension Helper
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double((hex >> 0) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Preview
struct ManagementCommonUI_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ManagementSearchBar(
                query: .constant(""),
                placeholder: "Search..."
            )
            
            ManagementInitialsAvatar(name: "John Doe")
            
            ManagementIconBox(
                icon: "person.3.fill",
                color: Color(hex: 0x2ECC71)
            )
            
            ManagementItemCard {
                Text("Example Item")
            }
        }
        .padding()
        .background(AppColors.appBackground)
    }
}
