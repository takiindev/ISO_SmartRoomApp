import SwiftUI
import Charts

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
                                    Image(systemName: "thermometer.slash")
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
                        
                        // Debug Section
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    viewModel.showDebugInfo.toggle()
                                }
                            }) {
                                HStack {
                                    Text("🐛 Debug API Response")
                                        .font(AppTypography.titleMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: viewModel.showDebugInfo ? "chevron.up" : "chevron.down")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            if viewModel.showDebugInfo {
                                ScrollView(.horizontal, showsIndicators: true) {
                                    Text(viewModel.debugAPIResponse)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(AppColors.textPrimary)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 300)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.05))
                                )
                                .padding(.horizontal, 24)
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
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chọn khoảng thời gian")
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: 12) {
                // Start Date Button
                DateButton(
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
                DateButton(
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
struct DateButton: View {
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

// MARK: - Temperature Chart
struct TemperatureChart: View {
    let title: String
    let sensors: [TemperatureSensor]
    let selectedSensorIds: Set<Int>
    let isLoading: Bool
    let chartData: [TemperatureChartDataPoint]
    
    private var selectedSensors: [TemperatureSensor] {
        sensors.filter { selectedSensorIds.contains($0.id) }
    }
    
    private var filteredChartData: [TemperatureChartDataPoint] {
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
    private func sensorChartContent(sensor: TemperatureSensor, index: Int) -> some ChartContent {
        let sensorData = filteredChartData.filter { $0.sensorId == sensor.id }
        let color = getChartColor(index: index)
        
        ForEach(sensorData) { dataPoint in
            LineMark(
                x: .value("Thời gian", dataPoint.timestamp),
                y: .value("Nhiệt độ", dataPoint.temperature)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Thời gian", dataPoint.timestamp),
                y: .value("Nhiệt độ", dataPoint.temperature)
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
                    if let temp = value.as(Double.self) {
                        Text("\(temp, specifier: "%.0f")°C")
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
                    
                    if let temp = sensor.currentValue {
                        Text("\(temp, specifier: "%.1f")°C")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text("—°C")
                            .font(AppTypography.titleMedium)
                            .fontWeight(.bold)
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
struct TemperatureSensor: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let isActive: Bool
    let currentValue: Double?
    let naturalId: String
    let roomId: Int
}

// MARK: - Temperature Chart Data Point
struct TemperatureChartDataPoint: Identifiable, Codable {
    let id: UUID
    let sensorId: Int
    let sensorName: String
    let temperature: Double
    let timestamp: Date
    
    init(id: UUID = UUID(), sensorId: Int, sensorName: String, temperature: Double, timestamp: Date) {
        self.id = id
        self.sensorId = sensorId
        self.sensorName = sensorName
        self.temperature = temperature
        self.timestamp = timestamp
    }
}

// MARK: - Temperature ViewModel
class TemperatureViewModel: ObservableObject {
    @Published var sensors: [TemperatureSensor] = []
    @Published var selectedSensorIds: Set<Int> = []
    @Published var chartData: [TemperatureChartDataPoint] = []
    @Published var isLoading: Bool = false
    @Published var isChartLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var debugAPIResponse: String = "Chưa có dữ liệu"
    @Published var showDebugInfo: Bool = false
    
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
            // Gọi API thật để lấy danh sách cảm biến nhiệt độ
            let loadedSensors = try await SmartRoomAPIService.shared.getTemperatureSensorsByRoom(roomId)
            
            sensors = loadedSensors
            // Tự động chọn tất cả sensors khi load
            selectedSensorIds = Set(sensors.map { $0.id })
            isLoading = false
            
            print("✅ Loaded \(sensors.count) temperature sensors for room \(roomId)")
            
        } catch SmartRoomAPIError.tokenExpired {
            isLoading = false
            print("🚨 Token expired while loading sensors - auto logout will trigger")
            // Don't set error message, let logout flow handle it
            
        } catch {
            print("❌ API error when loading sensors: \(error.localizedDescription)")
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
            print("⏭️ No sensors selected, clearing chart data")
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
        
        print("📊 Loading chart data for room \(roomId)")
        print("📊 From: \(startDateStr) To: \(endDateStr)")
        print("📊 Selected sensor IDs: \(selectedSensorIds)")
        
        do {
            // Gọi API để lấy dữ liệu lịch sử nhiệt độ
            let historyData = try await SmartRoomAPIService.shared.getTemperatureHistory(
                roomId: roomId,
                startedAt: startDateStr,
                endedAt: endDateStr
            )
            
            // Lưu debug info
            let debugInfo = "Total: \(historyData.count) data points\n\n" +
                historyData.prefix(20).enumerated().map { index, point in
                    "[\(index + 1)] \(point.timestamp) -> \(String(format: "%.2f", point.avgTempC))°C"
                }.joined(separator: "\n") +
                (historyData.count > 20 ? "\n\n... và \(historyData.count - 20) điểm nữa" : "")
            debugAPIResponse = debugInfo
            
            // Xử lý dữ liệu thành hourly data points
            chartData = processHourlyData(historyData: historyData)
            
            isChartLoading = false
            print("✅ Chart data loaded: \(chartData.count) hourly data points")
            
        } catch SmartRoomAPIError.tokenExpired {
            isChartLoading = false
            print("🚨 Token expired while loading chart data")
        } catch {
            isChartLoading = false
            print("❌ Error loading chart data: \(error.localizedDescription)")
            chartData = []
        }
    }
    
    // Xử lý dữ liệu API thành hourly data points
    // Mỗi mốc giờ (7h, 8h, 9h...) đại diện cho nhiệt độ trung bình từ giờ đó đến trước giờ tiếp theo
    private func processHourlyData(historyData: [TemperatureHistoryPoint]) -> [TemperatureChartDataPoint] {
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
            
            // Add temperature to this hour's group
            if hourlyGroups[hourTimestamp] == nil {
                hourlyGroups[hourTimestamp] = []
            }
            hourlyGroups[hourTimestamp]?.append(point.avgTempC)
        }
        
        // Calculate average for each hour and create chart data points
        var dataPoints: [TemperatureChartDataPoint] = []
        let selectedSensors = sensors.filter { selectedSensorIds.contains($0.id) }
        
        // Tạo data points cho mỗi sensor được chọn
        for sensor in selectedSensors {
            for (hourTimestamp, temps) in hourlyGroups {
                let avgTemp = temps.reduce(0.0, +) / Double(temps.count)
                
                dataPoints.append(TemperatureChartDataPoint(
                    sensorId: sensor.id,
                    sensorName: sensor.name,
                    temperature: avgTemp,
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
        TemperatureScreen(
            room: Room(id: 1, name: "Phòng khách", floorId: 1, description: nil)
        )
    }
}