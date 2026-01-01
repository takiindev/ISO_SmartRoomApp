// AuthRequiredView.swift
import SwiftUI

struct AuthRequiredView<Content: View>: View {
    let content: () -> Content
    
    @State private var isTokenValid = false
    @State private var isChecking = true
    @State private var showLogin = false
    
    var body: some View {
        Group {
            if isChecking {
                ProgressView("Đang kiểm tra đăng nhập...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.appBackground.ignoresSafeArea())
            } else if isTokenValid {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            // ⭐️ QUAN TRỌNG: Trong Preview → bỏ qua check API, luôn cho vào content
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                isTokenValid = true
                isChecking = false
                return
            }
            #endif
            
            // Gắn callback token expired (chỉ chạy khi app thật)
            SmartRoomAPIService.shared.onTokenExpired = {
                DispatchQueue.main.async {
                    self.isTokenValid = false
                    self.showLogin = true
                }
            }
            
            Task {
                await checkTokenAndHandle()
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(onLoginSuccess: {
                showLogin = false
                isTokenValid = true
            })
        }
    }
    
    private func checkTokenAndHandle() async {
        await MainActor.run { isChecking = true }
        
        // Nếu không có token → đi thẳng login
        if TokenManager.shared.getToken() == nil {
            await MainActor.run {
                isTokenValid = false
                showLogin = true
                isChecking = false
            }
            return
        }
        
        // Chỉ gọi API nếu có token (và không phải preview)
        do {
            _ = try await SmartRoomAPIService.shared.getFloors()
            await MainActor.run {
                isTokenValid = true
                isChecking = false
            }
        } catch {
            await MainActor.run {
                isTokenValid = false
                showLogin = true
                isChecking = false
            }
        }
    }
}
