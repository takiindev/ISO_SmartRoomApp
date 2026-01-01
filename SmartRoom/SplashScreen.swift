import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Smart Room")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(tint: .green)
                    )
            }
        }
    }
}
