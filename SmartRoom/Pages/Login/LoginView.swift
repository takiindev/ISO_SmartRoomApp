import SwiftUI

// MARK: - Login View (MVVM)
struct LoginView: View {
    let onLoginSuccess: () -> Void
    @StateObject private var viewModel = LoginViewModel()
    
    // MARK: - Theme Colors
    let accentColor = Color(red: 0.749, green: 0.992, blue: 0.071) // #bffd12
    let inputBackgroundColor = Color(red: 0.094, green: 0.094, blue: 0.094) // #181818
    let secondaryTextColor = Color(red: 0.635, green: 0.631, blue: 0.651) // #a2a1a6
    let checkboxColor = Color(red: 0.631, green: 0.627, blue: 0.647) // #a1a0a5
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    Spacer()
                    
                    logoSection
                    
                    Spacer().frame(height: 30)
                    
                    inputFields
                    
                    rememberAndForgotSection
                    
                    loginButton
                    
                    createAccountSection
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                }
                .frame(maxWidth: 350)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .alert("Login Error", isPresented: $viewModel.showErrorAlert) {
                    Button("OK") { viewModel.showErrorAlert = false }
                } message: {
                    Text(viewModel.errorMessage)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundLayer: some View {
        ZStack {
            Image("BackgroundImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .offset(x: -80, y: 0)
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 10) {
            SmartRoomLogo()
                .padding(.bottom, 10)
            
            Text("Smart Room")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Future living experience")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }
    
    private var inputFields: some View {
        VStack(spacing: 20) {
            InputView(
                text: $viewModel.apiURL,
                placeholder: "API URL",
                iconName: "server.rack",
                accentColor: accentColor,
                inputBackgroundColor: inputBackgroundColor,
                secondaryTextColor: secondaryTextColor,
                isSecure: false
            )
            
            InputView(
                text: $viewModel.emailOrUsername,
                placeholder: "Username or Email",
                iconName: "envelope",
                accentColor: accentColor,
                inputBackgroundColor: inputBackgroundColor,
                secondaryTextColor: secondaryTextColor,
                isSecure: false
            )
            
            InputView(
                text: $viewModel.password,
                placeholder: "Password",
                iconName: "lock",
                accentColor: accentColor,
                inputBackgroundColor: inputBackgroundColor,
                secondaryTextColor: secondaryTextColor,
                isSecure: true,
                isPasswordVisible: $viewModel.isPasswordVisible
            )
        }
    }
    
    private var rememberAndForgotSection: some View {
        HStack {
            Toggle("Remember me", isOn: $viewModel.rememberMe)
                .toggleStyle(CheckboxToggleStyle(tint: accentColor, squareColor: checkboxColor))
                .labelsHidden()
            
            Text("Remember me")
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Forgot Password?") {
                print("Forgot tapped")
            }
            .foregroundColor(accentColor)
            .font(.subheadline)
        }
    }
    
    private var loginButton: some View {
        Button {
            viewModel.login(onSuccess: onLoginSuccess)
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                }
                Text(viewModel.isLoading ? "LOGGING IN..." : "LOGIN TO SYSTEM")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 15)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(accentColor)
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.7 : 1.0)
        .padding(.top, 20)
    }
    
    private var createAccountSection: some View {
        HStack {
            Text("New user?")
                .foregroundColor(.white)
            Button("Create Account") {
                print("Navigate to Create Account")
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
    }
}

// MARK: - InputView Component
struct InputView: View {
    @Binding var text: String
    var placeholder: String
    var iconName: String
    var accentColor: Color
    var inputBackgroundColor: Color
    var secondaryTextColor: Color
    var isSecure: Bool
    var isPasswordVisible: Binding<Bool>?
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, placeholder: String, iconName: String, accentColor: Color, inputBackgroundColor: Color, secondaryTextColor: Color, isSecure: Bool, isPasswordVisible: Binding<Bool>? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.iconName = iconName
        self.accentColor = accentColor
        self.inputBackgroundColor = inputBackgroundColor
        self.secondaryTextColor = secondaryTextColor
        self.isSecure = isSecure
        self.isPasswordVisible = isPasswordVisible
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(secondaryTextColor)
                .frame(width: 20)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder).foregroundColor(secondaryTextColor)
                }
                
                Group {
                    if isSecure {
                        if isPasswordVisible?.wrappedValue == true {
                            TextField("", text: $text).focused($isFocused)
                        } else {
                            SecureField("", text: $text).focused($isFocused)
                        }
                    } else {
                        TextField("", text: $text).focused($isFocused)
                    }
                }
                .foregroundColor(.white)
            }
            
            if isSecure, let isVisibleBinding = isPasswordVisible {
                Button { isVisibleBinding.wrappedValue.toggle() } label: {
                    Image(systemName: isVisibleBinding.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(secondaryTextColor)
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background(inputBackgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? accentColor : Color.gray.opacity(0.1), lineWidth: isFocused ? 2 : 1)
        )
    }
}

// MARK: - CheckboxToggleStyle
struct CheckboxToggleStyle: ToggleStyle {
    var tint: Color
    var squareColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? tint : squareColor)
                .font(.title2)
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(onLoginSuccess: { print("Login success") })
}
