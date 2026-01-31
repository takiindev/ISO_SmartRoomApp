import SwiftUI

struct PropertiesScreen: View {
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack {
                Text("Properties")
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

#Preview {
    PropertiesScreen()
}
