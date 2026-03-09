// TokenManagerTestView.swift
import SwiftUI

struct TokenManagerTestView: View {
    @State private var testToken = "test_token_123456789"
    @State private var retrievedToken = ""
    @State private var testLog = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🧪 Token Manager Test")
                    .font(.title)
                    .bold()
                    .padding(.bottom)
                
                // Test 1: Save Token
                VStack(alignment: .leading) {
                    Text("1️⃣ Save Token")
                        .font(.headline)
                    TextField("Token to save", text: $testToken)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Token") {
                        TokenManager.shared.saveToken(testToken)
                        testLog += "✅ Saved token: \(testToken)\n"
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Divider()
                
                // Test 2: Get Token
                VStack(alignment: .leading) {
                    Text("2️⃣ Get Token")
                        .font(.headline)
                    Button("Retrieve Token") {
                        if let token = TokenManager.shared.getToken() {
                            retrievedToken = token
                            testLog += "✅ Retrieved token: \(token)\n"
                        } else {
                            retrievedToken = "No token found"
                            testLog += "❌ No token found\n"
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if !retrievedToken.isEmpty {
                        Text("Retrieved: \(retrievedToken)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Test 3: Clear Token
                VStack(alignment: .leading) {
                    Text("3️⃣ Clear Token")
                        .font(.headline)
                    Button("Clear Token", role: .destructive) {
                        TokenManager.shared.clearToken()
                        retrievedToken = ""
                        testLog += "🗑️ Cleared token\n"
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Test 4: Debug Info
                VStack(alignment: .leading) {
                    Text("4️⃣ Debug Info")
                        .font(.headline)
                    Button("Show Debug Info") {
                        TokenManager.shared.printDebugInfo()
                        testLog += "📊 Printed debug info to console\n"
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Log
                VStack(alignment: .leading) {
                    HStack {
                        Text("📝 Test Log")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            testLog = ""
                        }
                        .font(.caption)
                    }
                    
                    ScrollView {
                        Text(testLog.isEmpty ? "No logs yet" : testLog)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(testLog.isEmpty ? .gray : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Instructions")
                        .font(.headline)
                    Text("1. Click 'Save Token' to save a test token")
                    Text("2. KILL THE APP (swipe up)")
                    Text("3. Open app again")
                    Text("4. Click 'Retrieve Token' to see if it's still there")
                    Text("5. Check Console logs for detailed info")
                }
                .font(.caption)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

#Preview {
    TokenManagerTestView()
}
