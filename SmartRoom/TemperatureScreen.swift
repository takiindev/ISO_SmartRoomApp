import SwiftUI

struct TemperatureScreen: View {
    let room: Room
    
    @StateObject private var viewModel = TemperatureViewModel()
    @State private var startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
    @State private var endDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header với back button giống RoomDetailScreen
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(room.name)
                        .font(AppTypography.headlineMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Empty space for balance
                    Rectangle()
                        .frame(width: 30, height: 30)
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(AppColors.appBackground)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        // Date Range Selector
                        GlassCard {
                            DateRangeSelector(
                                startDate: $startDate,
                                endDate: $endDate
                            )
                        }
                        .padding(.top, 20)
                        
                        // Temperature Chart
                        GlassCard(borderColor: AppColors.accentPink) {
                            TemperatureChart(
                                title: "Biểu đồ nhiệt độ",
                                sensors: viewModel.sensors,
                                selectedSensorIds: viewModel.selectedSensorIds,
                                isLoading: viewModel.isChartLoading
                            )
                        }
                        
                        // Sensors List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Cảm biến")
                                    .font(AppTypography.titleMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                                    Spacer()
                                }
                                .padding()
                            } else {
                                ForEach(Array(viewModel.sensors.enumerated()), id: \.element.id) { index, sensor in
                                    TemperatureSensorRow(
                                        sensor: sensor,
                                        colorIndex: index,
                                        isSelected: viewModel.selectedSensorIds.contains(sensor.id),
                                        onSelectionChanged: { sensorId, isSelected in
                                            viewModel.toggleSensorSelection(sensorId: sensorId, isSelected: isSelected)
                                        }
                                    )
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        
                        // Bottom padding
                        Rectangle()
                            .frame(height: 32)
                            .opacity(0)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadSensors(for: room.id)
        }
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let borderColor: Color?
    let content: Content
    
    init(borderColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.borderColor = borderColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceWhite)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 2 : 0)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 24)
    }
}

// MARK: - Date Range Selector
struct DateRangeSelector: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Chọn khoảng thời gian")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 16) {
                // Start Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Từ ngày")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button(action: { showingStartPicker = true }) {
                        Text(dateFormatter.string(from: startDate))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.surfaceLight)
                            )
                    }
                }
                
                Spacer()
                
                // End Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Đến ngày")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button(action: { showingEndPicker = true }) {
                        Text(dateFormatter.string(from: endDate))
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.surfaceLight)
                            )
                    }
                }
            }
        }
        .sheet(isPresented: $showingStartPicker) {
            DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingEndPicker) {
            DatePicker("Đến ngày", selection: $endDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Temperature Chart
struct TemperatureChart: View {
    let title: String
    let sensors: [TemperatureSensor]
    let selectedSensorIds: Set<Int>
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
                    Spacer()
                }
                .frame(height: 200)
            } else {
                // Simple placeholder chart
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.surfaceLight.opacity(0.3))
                        .frame(height: 200)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(AppColors.primaryPurple)
                        
                        Text("Biểu đồ nhiệt độ")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Temperature Sensor Row
struct TemperatureSensorRow: View {
    let sensor: TemperatureSensor
    let colorIndex: Int
    let isSelected: Bool
    let onSelectionChanged: (Int, Bool) -> Void
    
    private var sensorColor: Color {
        getChartColor(index: colorIndex)
    }
    
    var body: some View {
        Button(action: { onSelectionChanged(sensor.id, !isSelected) }) {
            HStack(spacing: 16) {
                // Icon with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [sensorColor, sensorColor.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "thermometer")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Sensor Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(sensor.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(sensor.currentValue ?? 0, specifier: "%.1f")°C")
                        .font(AppTypography.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? sensorColor : AppColors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.surfaceWhite)
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Functions
func getChartColor(index: Int) -> Color {
    let colors: [Color] = [
        Color(red: 0.9, green: 0.22, blue: 0.27), // #E63946
        Color(red: 0.27, green: 0.48, blue: 0.62), // #457B9D
        Color(red: 0.32, green: 0.71, blue: 0.60), // #52B69A
        Color(red: 0.99, green: 0.64, blue: 0.07), // #FCA311
        Color(red: 0.62, green: 0.31, blue: 0.87), // #9D4EDD
        Color(red: 0.96, green: 0.64, blue: 0.38)  // #F4A261
    ]
    return colors[index % colors.count]
}

// MARK: - Temperature Sensor Model
struct TemperatureSensor: Identifiable {
    let id: Int
    let name: String
    let currentValue: Double?
}

// MARK: - Temperature ViewModel
class TemperatureViewModel: ObservableObject {
    @Published var sensors: [TemperatureSensor] = []
    @Published var selectedSensorIds: Set<Int> = []
    @Published var isLoading: Bool = false
    @Published var isChartLoading: Bool = false
    
    func loadSensors(for roomId: Int) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sensors = [
                TemperatureSensor(id: 1, name: "Cảm biến phòng khách", currentValue: 24.5),
                TemperatureSensor(id: 2, name: "Cảm biến phòng ngủ", currentValue: 22.3),
                TemperatureSensor(id: 3, name: "Cảm biến ban công", currentValue: 26.8)
            ]
            self.selectedSensorIds = Set(self.sensors.map { $0.id })
            self.isLoading = false
        }
    }
    
    func toggleSensorSelection(sensorId: Int, isSelected: Bool) {
        if isSelected {
            selectedSensorIds.insert(sensorId)
        } else {
            selectedSensorIds.remove(sensorId)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        TemperatureScreen(
            room: Room(id: 1, name: "Phòng khách", floorId: 1, description: nil)
        )
    }
}