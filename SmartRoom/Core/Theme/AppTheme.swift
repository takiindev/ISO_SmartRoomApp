import SwiftUI

// MARK: - Color Palette
struct AppColors {
    // --- PALETTE FROM IMAGE ---
    static let primaryDark = Color(red: 0x31/255.0, green: 0x37/255.0, blue: 0x4A/255.0)    // Dark Navy
    static let primaryPurple = Color(red: 0x98/255.0, green: 0x5E/255.0, blue: 0xE1/255.0)  // Purple Accent
    static let accentPink = Color(red: 0xF2/255.0, green: 0x56/255.0, blue: 0x56/255.0)     // Pink Accent
    static let softPeach = Color(red: 0xFF/255.0, green: 0xD0/255.0, blue: 0xD0/255.0)      // Light Pink/Peach
    
    // --- BACKGROUNDS ---
    static let appBackground = Color(red: 0xF5/255.0, green: 0xF5/255.0, blue: 0xF9/255.0)  // Light Grayish Blue
    static let surfaceWhite = Color(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0)   // Pure White
    static let surfaceLight = Color(red: 0xDA/255.0, green: 0xDF/255.0, blue: 0xE7/255.0)   // Light Grey
    
    // --- TEXT ---
    static let textPrimary = Color(red: 0x3C/255.0, green: 0x3C/255.0, blue: 0x43/255.0)    // Dark Grey
    static let textSecondary = Color(red: 0x3C/255.0, green: 0x3C/255.0, blue: 0x43/255.0).opacity(0.6) // Lighter Grey
    
    // --- GRADIENTS ---
    static let purplePinkGradient = [primaryPurple, accentPink]
}

// MARK: - Typography
struct AppTypography {
    // Số to (VD: 28°C)
    static let displayLarge = Font.system(size: 48, weight: .black, design: .default)
    
    // Tiêu đề màn hình (Living Room)
    static let headlineMedium = Font.system(size: 24, weight: .bold, design: .default)
    
    // Tiêu đề nhỏ hơn (Assign Groups)
    static let headlineSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Tên thiết bị (Smart Light)
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
    
    // Text cỡ lớn (ID user, nút)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    
    // Text phụ (Managed by...)
    static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
    
    // Text nhỏ trên nút hoặc tag
    static let labelLarge = Font.system(size: 14, weight: .bold, design: .default)
}