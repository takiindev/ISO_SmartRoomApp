import SwiftUI

// MARK: - Alert UI State
struct AlertUiState {
    var isLoading: Bool = true
    var alerts: [Alert] = []
    var errorMessage: String? = nil
}

// MARK: - Alert Model
struct Alert: Identifiable {
    let id: Int
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    let isRead: Bool
    
    enum AlertSeverity: String {
        case critical = "Critical"
        case warning = "Warning"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .critical:
                return Color.red
            case .warning:
                return Color.orange
            case .info:
                return Color.blue
            }
        }
        
        var icon: String {
            switch self {
            case .critical:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
}

// MARK: - Alert ViewModel
@MainActor
class AlertViewModel: ObservableObject {
    @Published var uiState = AlertUiState()
    
    func loadAlerts() async {
        uiState.isLoading = true
        uiState.errorMessage = nil
        
        // Simulate loading with mock data
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Mock alerts data
        let mockAlerts = [
            Alert(
                id: 1,
                title: "High Temperature Alert",
                message: "Room 101 temperature exceeds 28°C",
                severity: .critical,
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            Alert(
                id: 2,
                title: "AC Maintenance Required",
                message: "AC Unit #5 requires scheduled maintenance",
                severity: .warning,
                timestamp: Date().addingTimeInterval(-7200),
                isRead: false
            ),
            Alert(
                id: 3,
                title: "System Update",
                message: "Smart room system updated to version 2.1.0",
                severity: .info,
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true
            ),
            Alert(
                id: 4,
                title: "Power Consumption Warning",
                message: "Floor 3 power usage above normal threshold",
                severity: .warning,
                timestamp: Date().addingTimeInterval(-10800),
                isRead: true
            )
        ]
        
        uiState.alerts = mockAlerts
        uiState.isLoading = false
    }
    
    func markAsRead(_ alertId: Int) {
        if let index = uiState.alerts.firstIndex(where: { $0.id == alertId }) {
            var alert = uiState.alerts[index]
            uiState.alerts[index] = Alert(
                id: alert.id,
                title: alert.title,
                message: alert.message,
                severity: alert.severity,
                timestamp: alert.timestamp,
                isRead: true
            )
        }
    }
}

// MARK: - Alert Screen
struct AlertScreen: View {
    @StateObject private var viewModel = AlertViewModel()
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Alerts")
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                if viewModel.uiState.isLoading {
                    Spacer()
                    AlertLoadingView()
                    Spacer()
                } else if let errorMessage = viewModel.uiState.errorMessage {
                    Spacer()
                    AlertErrorView(message: errorMessage, onRetry: {
                        Task {
                            await viewModel.loadAlerts()
                        }
                    })
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Stats
                            AlertStatsView(alerts: viewModel.uiState.alerts)
                            
                            // Alerts List
                            VStack(spacing: 12) {
                                ForEach(viewModel.uiState.alerts) { alert in
                                    AlertCard(alert: alert) {
                                        viewModel.markAsRead(alert.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task {
            await viewModel.loadAlerts()
        }
    }
}

// MARK: - Alert Stats View
struct AlertStatsView: View {
    let alerts: [Alert]
    
    var unreadCount: Int {
        alerts.filter { !$0.isRead }.count
    }
    
    var criticalCount: Int {
        alerts.filter { $0.severity == .critical }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "bell.badge.fill",
                title: "Unread",
                value: "\(unreadCount)",
                color: AppColors.primaryPurple
            )
            
            StatCard(
                icon: "exclamationmark.triangle.fill",
                title: "Critical",
                value: "\(criticalCount)",
                color: Color.red
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                title: "Total",
                value: "\(alerts.count)",
                color: Color.green
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surfaceWhite)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Alert Card
struct AlertCard: View {
    let alert: Alert
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Severity Icon
            ZStack {
                Circle()
                    .fill(alert.severity.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: alert.severity.icon)
                    .font(.system(size: 22))
                    .foregroundColor(alert.severity.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if !alert.isRead {
                        Circle()
                            .fill(AppColors.primaryPurple)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(alert.message)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text(alert.severity.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(alert.severity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(alert.severity.color.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    Text(timeAgo(from: alert.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(alert.isRead ? AppColors.surfaceWhite : AppColors.surfaceLight)
                .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}

// MARK: - Loading View
struct AlertLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading alerts...")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Error View
struct AlertErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.red)
            
            Text("Error")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AlertScreen()
}
