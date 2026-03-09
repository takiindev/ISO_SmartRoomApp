# 📦 SmartRoom App - MVVM Architecture

## 🏗️ Cấu trúc dự án

```
SmartRoom/
├── 📁 Pages/                    # Tất cả màn hình UI (Presentation Layer)
│   ├── Login/                   # Đăng nhập (MVVM)
│   │   ├── LoginView.swift      # UI View
│   │   ├── LoginViewModel.swift # Business Logic
│   │   └── LoginScreen.swift    # Wrapper
│   ├── Authentication/          # Auth components (Wrapper, Guards)
│   │   ├── AuthenticationWrapper.swift
│   │   └── AuthRequiredView.swift
│   ├── Home/                    # Màn hình trang chủ (MVVM)
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── HomeScreen.swift
│   ├── AC/                      # Điều hòa không khí
│   ├── Room/                    # Chi tiết phòng
│   ├── Automation/              # Tự động hóa
│   ├── Management/              # Quản lý user, role, group
│   ├── Monitoring/              # Giám sát thiết bị
│   └── Settings/                # Cài đặt
│
├── 📁 Core/                     # Business Logic & Infrastructure
│   ├── Services/                # API & Network services
│   │   └── SmartRoomAPIService.swift
│   ├── Managers/                # State & Data managers
│   │   └── TokenManager.swift
│   ├── Theme/                   # UI Theme & Styling
│   │   ├── AppTheme.swift
│   │   └── SmartRoomLogo.swift
│   └── Components/              # Shared components
│       ├── SmartRoomApp.swift   # App entry point
│       └── SplashScreen.swift
│
└── 📁 Assets.xcassets/          # Images, colors, icons
```

## 🎯 MVVM Pattern

### Model
- Các struct dữ liệu (Floor, Room, Light, ACDevice, User...)
- Được định nghĩa trong `SmartRoomAPIService.swift`

### View
- SwiftUI Views (chỉ chứa UI code)
- Binding với ViewModel qua `@StateObject` hoặc `@ObservedObject`
- Ví dụ: `LoginView.swift`, `HomeView.swift`

### ViewModel
- `@MainActor class ... : ObservableObject`
- Chứa `@Published` properties cho UI binding
- Xử lý business logic, API calls, validation
- Ví dụ: `LoginViewModel.swift`, `HomeViewModel.swift`

## 📝 Quy tắc đặt tên

### Screens/Pages
- **View**: `[Feature]View.swift` (ví dụ: `LoginView.swift`)
- **ViewModel**: `[Feature]ViewModel.swift` (ví dụ: `LoginViewModel.swift`)
- **Legacy Screen**: `[Feature]Screen.swift` (wrapper cho tương thích)

### Services & Managers
- **Services**: `[Name]Service.swift` (ví dụ: `SmartRoomAPIService.swift`)
- **Managers**: `[Name]Manager.swift` (ví dụ: `TokenManager.swift`)

## 🔄 Data Flow

```
User Action → View → ViewModel → Service/Manager → API
                ↑                                     ↓
                └────── @Published properties ────────┘
```

## 📚 Ví dụ tạo màn hình mới

### 1. Tạo ViewModel
```swift
// Pages/NewFeature/NewFeatureViewModel.swift
@MainActor
class NewFeatureViewModel: ObservableObject {
    @Published var data: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = SmartRoomAPIService.shared
    
    func loadData() {
        Task {
            isLoading = true
            do {
                data = try await apiService.getData()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
```

### 2. Tạo View
```swift
// Pages/NewFeature/NewFeatureView.swift
struct NewFeatureView: View {
    @StateObject private var viewModel = NewFeatureViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.data) { item in
                    Text(item.name)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}
```

## ✅ Best Practices

1. **Separation of Concerns**: View chỉ chứa UI, ViewModel chứa logic
2. **Single Responsibility**: Mỗi file một responsibility rõ ràng
3. **Dependency Injection**: Inject dependencies qua initializer
4. **Async/Await**: Sử dụng async/await cho API calls
5. **Error Handling**: Xử lý errors ở ViewModel, hiển thị ở View
6. **Testing**: ViewModel dễ test vì tách biệt khỏi UI

## 🚀 Next Steps

- [ ] Tách thêm các screen còn lại theo MVVM
- [ ] Tạo Repository layer nếu cần
- [ ] Thêm Unit Tests cho ViewModels
- [ ] Implement dependency injection container
- [ ] Thêm logging và analytics
