import SwiftUI
import Charts

struct PowerScreen: View {
    let room: Room
    
    @StateObject private var viewModel = PowerViewModel()
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
                        PowerGlassCard {
                            PowerDateRangeSelector(
                                startDate: $startDate,
                                endDate: $endDate
                            )
                        }
                        .padding(.top, 20)
                        
                        // Power Chart
                        PowerGlassCard(borderColor: AppColors.primaryPurple) {
                            PowerChart(
                                title: "Biểu đồ tiêu thụ điện",
                                sensors: viewModel.sensors,
                                selectedSensorIds: viewModel.selectedSensorIds,
                                isLoading: viewModel.isChartLoading,
                                chartData: viewModel.chartData
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
                            } else if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(AppColors.accentPink)
                                    
                                    Text(errorMessage)
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Thử lại") {
                                        viewModel.loadSensors(for: room.id)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primaryPurple)
                                    .foregroundColor(AppColors.surfaceWhite)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 32)
                            } else if viewModel.sensors.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bolt.slash")
                                        .font(.largeTitle)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text("Không có cảm biến nào")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 32)
                            } else {
                                ForEach(Array(viewModel.sensors.enumerated()), id: \.element.id) { index, sensor in
                                    PowerSensorRow(
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
        .onChange(of: startDate) { oldValue, newValue in
            viewModel.loadChartData(for: room.id, startDate: newValue, endDate: endDate)
        }
        .onChange(of: endDate) { oldValue, newValue in
            viewModel.loadChartData(for: room.id, startDate: startDate, endDate: newValue)
        }
        .onChange(of: viewModel.selectedSensorIds) { oldValue, newValue in
            viewModel.loadChartData(for: room.id, startDate: startDate, endDate: endDate)
        }
    }
}

// MARK: - Glass Card
struct PowerGlassCard<Content: View>: View {
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
                    .shadow(color: AppColors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 24)
    }
}

// MARK: - Date Range Selector
struct PowerDateRangeSelector: View {
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
        VStack(spacing: 20) {
            Text("Chọn khoảng thời gian")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 12) {
                // Start Date Button
                PowerDateButton(
                    label: "Từ ngày",
                    date: startDate,
                    formatter: dateFormatter,
                    isStart: true
                ) {
                    showingStartPicker = true
                }
                
                // Arrow Icon
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(AppColors.primaryPurple)
                    .frame(width: 30)
                
                // End Date Button
                PowerDateButton(
                    label: "Đến ngày",
                    date: endDate,
                    formatter: dateFormatter,
                    isStart: false
                ) {
                    showingEndPicker = true
                }
            }
        }
        .sheet(isPresented: $showingStartPicker) {
            VStack(spacing: 16) {
                Text("Chọn ngày bắt đầu")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                
                DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Xong") {
                    showingStartPicker = false
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(AppColors.primaryPurple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.bottom, 20)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingEndPicker) {
            VStack(spacing: 16) {
                Text("Chọn ngày kết thúc")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                
                DatePicker("Đến ngày", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Xong") {
                    showingEndPicker = false
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(AppColors.primaryPurple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.bottom, 20)
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Date Button Component
struct PowerDateButton: View {
    let label: String
    let date: Date
    let formatter: DateFormatter
    let isStart: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Label
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                
                // Date display with icon
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primaryPurple)
                    
                    Text(formatter.string(from: date))
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.surfaceLight,
                                    AppColors.surfaceLight.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primaryPurple.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: AppColors.textSecondary.opacity(0.08), radius: 4, x: 0, y: 2)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Power Chart
struct PowerChart: View {
    let title: String
    let sensors: [PowerSensor]
    let selectedSensorIds: Set<Int>
    let isLoading: Bool
    let chartData: [PowerChartDataPoint]
    
    private var selectedSensors: [PowerSensor] {
        sensors.filter { selectedSensorIds.contains($0.id) }
    }
    
    private var filteredChartData: [PowerChartDataPoint] {
        chartData.filter { selectedSensorIds.contains($0.sensorId) }
    }
    
    // Mặc định zoom in để chỉ hiển thị 10 mốc giờ ban đầu
    private var initialVisibleDomainLength: TimeInterval {
        // Hiển thị 10 giờ = 10 mốc (10 * 3600 seconds)
        return 10 * 3600
    }
    
    // Helper to create line mark for a data point
    @ChartContentBuilder
    private func chartContent() -> some ChartContent {
        ForEach(Array(selectedSensors.enumerated()), id: \.element.id) { index, sensor in
            sensorChartContent(sensor: sensor, index: index)
        }
    }
    
    @ChartContentBuilder
    private func sensorChartContent(sensor: PowerSensor, index: Int) -> some ChartContent {
        let sensorData = filteredChartData.filter { $0.sensorId == sensor.id }
        let color = getPowerChartColor(index: index)
        
        ForEach(sensorData) { dataPoint in
            LineMark(
                x: .value("Thời gian", dataPoint.timestamp),
                y: .value("Công suất", dataPoint.watt)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Thời gian", dataPoint.timestamp),
                y: .value("Công suất", dataPoint.watt)
            )
            .foregroundStyle(color)
            .symbol(.circle)
            .symbolSize(30)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            if isLoading {
                loadingView
            } else if filteredChartData.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryPurple))
            Spacer()
        }
        .frame(height: 250)
    }
    
    private var emptyStateView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surfaceLight.opacity(0.3))
                .frame(height: 250)
            
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Chưa có dữ liệu")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private var chartView: some View {
        Chart {
            chartContent()
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let watt = value.as(Double.self) {
                        Text("\(watt, specifier: "%.0f")W")
                            .font(.caption)
                    }
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: initialVisibleDomainLength)
        .chartXScale(domain: .automatic)
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 250)
        .padding(.vertical, 8)
    }
}

// MARK: - Power Sensor Row
struct PowerSensorRow: View {
    let sensor: PowerSensor
    let colorIndex: Int
    let isSelected: Bool
    let onSelectionChanged: (Int, Bool) -> Void
    
    private var sensorColor: Color {
        getPowerChartColor(index: colorIndex)
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
                    
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Sensor Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(sensor.name)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                        
                        // Status indicator
                        Circle()
                            .fill(sensor.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    }
                    
                    if let watt = sensor.currentWatt {
                        Text("\(watt, specifier: "%.1f")W")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text("—W")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if let wattHour = sensor.currentWattHour {
                        Text("\(wattHour, specifier: "%.1f")Wh")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
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
func getPowerChartColor(index: Int) -> Color {
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

// MARK: - Power Chart Data Point
struct PowerChartDataPoint: Identifiable, Codable {
    let id: UUID
    let sensorId: Int
    let sensorName: String
    let watt: Double
    let timestamp: Date
    
    init(id: UUID = UUID(), sensorId: Int, sensorName: String, watt: Double, timestamp: Date) {
        self.id = id
        self.sensorId = sensorId
        self.sensorName = sensorName
        self.watt = watt
        self.timestamp = timestamp
    }
}

// MARK: - Power ViewModel
class PowerViewModel: ObservableObject {
    @Published var sensors: [PowerSensor] = []
    @Published var selectedSensorIds: Set<Int> = []
    @Published var chartData: [PowerChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var isChartLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadSensors(for roomId: Int) {
        Task {
            await performLoadSensors(for: roomId)
        }
    }
    
    @MainActor
    private func performLoadSensors(for roomId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Gọi API thật để lấy danh sách cảm biến công suất
            let loadedSensors = try await SmartRoomAPIService.shared.getPowerSensorsByRoom(roomId)
            
            sensors = loadedSensors
            // Tự động chọn tất cả sensors khi load
            selectedSensorIds = Set(sensors.map { $0.id })
            isLoading = false
            
        } catch SmartRoomAPIError.tokenExpired {
            isLoading = false
            // Don't set error message, let logout flow handle it
            
        } catch {
            errorMessage = "Không thể tải danh sách cảm biến: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func toggleSensorSelection(sensorId: Int, isSelected: Bool) {
        if isSelected {
            selectedSensorIds.insert(sensorId)
        } else {
            selectedSensorIds.remove(sensorId)
        }
    }
    
    func loadChartData(for roomId: Int, startDate: Date, endDate: Date) {
        Task {
            await performLoadChartData(for: roomId, startDate: startDate, endDate: endDate)
        }
    }
    
    @MainActor
    private func performLoadChartData(for roomId: Int, startDate: Date, endDate: Date) async {
        // Chỉ load chart data nếu có sensors được chọn
        guard !selectedSensorIds.isEmpty else {
            chartData = []
            return
        }
        
        isChartLoading = true
        
        // Convert dates to ISO8601 format with UTC timezone (required by API)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Set start time to 00:00:00 UTC
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let startDateTime = calendar.date(from: startComponents) ?? startDate
        
        // Set end time to 23:59:59 UTC
        var endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        let endDateTime = calendar.date(from: endComponents) ?? endDate
        
        let startDateStr = isoFormatter.string(from: startDateTime)
        let endDateStr = isoFormatter.string(from: endDateTime)
        
        do {
            // Gọi API để lấy dữ liệu lịch sử công suất
            let historyData = try await SmartRoomAPIService.shared.getPowerConsumptionHistory(
                roomId: roomId,
                from: startDateStr,
                to: endDateStr
            )
            
            // Xử lý dữ liệu thành hourly data points
            chartData = processHourlyData(historyData: historyData)
            
            isChartLoading = false
            
        } catch SmartRoomAPIError.tokenExpired {
            isChartLoading = false
        } catch {
            isChartLoading = false
            chartData = []
        }
    }
    
    // Xử lý dữ liệu API thành hourly data points
    // Mỗi mốc giờ (7h, 8h, 9h...) đại diện cho công suất trung bình từ giờ đó đến trước giờ tiếp theo
    private func processHourlyData(historyData: [PowerHistoryPoint]) -> [PowerChartDataPoint] {
        guard !historyData.isEmpty else { return [] }
        
        // Parse timestamps từ API (ISO8601 format)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(identifier: "UTC")
        
        // Group data by hour
        var hourlyGroups: [Date: [Double]] = [:]
        
        for point in historyData {
            guard let timestamp = isoFormatter.date(from: point.timestamp) else {
                continue
            }
            
            // Round down to the hour
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: timestamp)
            guard let hourTimestamp = calendar.date(from: components) else {
                continue
            }
            
            // Add watt to this hour's group
            if hourlyGroups[hourTimestamp] == nil {
                hourlyGroups[hourTimestamp] = []
            }
            hourlyGroups[hourTimestamp]?.append(point.sumWatt)
        }
        
        // Calculate average for each hour and create chart data points
        var dataPoints: [PowerChartDataPoint] = []
        let selectedSensors = sensors.filter { selectedSensorIds.contains($0.id) }
        
        // Tạo data points cho mỗi sensor được chọn
        for sensor in selectedSensors {
            for (hourTimestamp, watts) in hourlyGroups {
                let avgWatt = watts.reduce(0.0, +) / Double(watts.count)
                
                dataPoints.append(PowerChartDataPoint(
                    sensorId: sensor.id,
                    sensorName: sensor.name,
                    watt: avgWatt,
                    timestamp: hourTimestamp
                ))
            }
        }
        
        return dataPoints.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PowerScreen(
            room: Room(id: 1, name: "Phòng khách", floorId: 1, description: nil)
        )
    }
}
