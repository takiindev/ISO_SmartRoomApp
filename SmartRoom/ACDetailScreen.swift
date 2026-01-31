import SwiftUI

struct ACDetailScreen: View {
    let device: ACDevice
    
    @State private var temperature: Int = 25
    @State private var selectedMode: String = "COOL"
    @State private var fanSpeed: Int = 3
    @State private var swingOn: Bool = false
    @State private var isPowerOn: Bool = true
    @State private var isTogglingPower: Bool = false
    @State private var isLoadingDetails: Bool = false
    @State private var isUpdatingTemperature: Bool = false
    @State private var isUpdatingMode: Bool = false
    @State private var isUpdatingFanSpeed: Bool = false
    @State private var isUpdatingSwing: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    let modes = ["COOL", "HEAT", "DRY", "FAN", "AUTO"]
    
    // Mode colors
    var modeColor: Color {
        // If power is OFF, use gray color
        if !isPowerOn {
            return Color(red: 0.7, green: 0.7, blue: 0.7) // Gray
        }
        
        switch selectedMode {
        case "COOL":
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
        case "HEAT":
            return Color(red: 1.0, green: 0.38, blue: 0.0) // Orange/Red
        case "DRY":
            return Color(red: 1.0, green: 0.75, blue: 0.0) // Yellow
        case "FAN":
            return Color(red: 0.2, green: 0.78, blue: 0.35) // Green
        case "AUTO":
            return Color(red: 0.61, green: 0.35, blue: 0.71) // Purple
        default:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Default Blue
        }
    }
    
    var modeBackgroundColor: Color {
        modeColor.opacity(0.1)
    }
    
    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(device.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear.frame(width: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 4)
                .frame(height: 44)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Temperature Control Section
                        HStack(spacing: 15) {
                            // Plus/Minus Buttons
                            VStack(spacing: 25) {
                                Button(action: {
                                    if temperature < 30 && !isUpdatingTemperature {
                                        updateTemperature(newValue: temperature + 1)
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(modeColor)
                                        .frame(width: 45, height: 45)
                                }
                                .disabled(!isPowerOn || isUpdatingTemperature)
                                
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 2)
                                
                                Button(action: {
                                    if temperature > 16 && !isUpdatingTemperature {
                                        updateTemperature(newValue: temperature - 1)
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(modeColor)
                                        .frame(width: 45, height: 45)
                                }
                                .disabled(!isPowerOn || isUpdatingTemperature)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 18)
                            .background(modeBackgroundColor)
                            .cornerRadius(35)
                            
                            Spacer()
                            
                            // Temperature Circle
                            ZStack {
                                TemperatureGaugeView(temperature: temperature, maxTemp: 30, modeColor: modeColor)
                                
                                VStack(spacing: 4) {
                                    Text("\(temperature)°")
                                        .font(.system(size: 48, weight: .regular))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(selectedMode)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(modeColor)
                                        .tracking(1)
                                }
                            }
                            .frame(width: 180, height: 180)
                            
                            Spacer()
                            
                            // Swing Button
                            VStack(spacing: 5) {
                                Button(action: {
                                    if !isUpdatingSwing {
                                        updateSwing(newState: !swingOn)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(swingOn ? modeColor : Color(red: 0.94, green: 0.94, blue: 0.94))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "wind")
                                            .font(.system(size: 20))
                                            .foregroundColor(swingOn ? .white : AppColors.textSecondary)
                                    }
                                }
                                .disabled(!isPowerOn || isUpdatingSwing)
                                
                                Text("Swing")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Turn Off Button
                        Button(action: {
                            togglePower()
                        }) {
                            if isTogglingPower {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(modeColor)
                                    .cornerRadius(12)
                            } else {
                                Text(isPowerOn ? "TURN OFF" : "TURN ON")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(modeColor)
                                    .cornerRadius(12)
                                    .shadow(color: modeColor.opacity(0.3), radius: 15, x: 0, y: 4)
                            }
                        }
                        .disabled(isTogglingPower)
                        .padding(.horizontal, 24)
                        
                        // Mode Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("MODE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 24)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                                ForEach(modes, id: \.self) { mode in
                                    Button(action: {
                                        if !isUpdatingMode {
                                            updateMode(newMode: mode)
                                        }
                                    }) {
                                        Text(mode)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(selectedMode == mode ? modeColor : AppColors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedMode == mode ? modeBackgroundColor : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedMode == mode ? modeColor : Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                            )
                                            .cornerRadius(8)
                                    }
                                    .disabled(!isPowerOn || isUpdatingMode)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Fan Speed Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("FAN SPEED")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Spacer()
                                
                                Text("Level \(fanSpeed)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(modeColor)
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 15) {
                                // Custom Slider
                                GeometryReader { geometry in
                                    let thumbSize: CGFloat = 20
                                    let trackWidth = geometry.size.width
                                    // Thumb position: 0 at start (0%), 5 at end (100%)
                                    let thumbPosition = trackWidth * CGFloat(fanSpeed) / 5.0
                                    
                                    ZStack(alignment: .leading) {
                                        // Track
                                        Rectangle()
                                            .fill(Color(red: 0.9, green: 0.9, blue: 0.92))
                                            .frame(height: 4)
                                            .cornerRadius(2)
                                        
                                        // Progress
                                        Rectangle()
                                            .fill(modeColor)
                                            .frame(width: thumbPosition, height: 4)
                                            .cornerRadius(2)
                                        
                                        // Thumb - centered at exact position
                                        Circle()
                                            .fill(modeColor)
                                            .frame(width: thumbSize, height: thumbSize)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 3)
                                            )
                                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                            .position(x: thumbPosition, y: 10)
                                    }
                                    .gesture(
                                        isPowerOn && !isUpdatingFanSpeed ? DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let clampedX = max(0, min(value.location.x, trackWidth))
                                                let percent = clampedX / trackWidth
                                                // Snap to nearest level
                                                let newSpeed = Int(round(percent * 5))
                                                fanSpeed = max(0, min(5, newSpeed))
                                            }
                                            .onEnded { _ in
                                                // Call API when drag ends
                                                updateFanSpeed(newSpeed: fanSpeed)
                                            } : nil
                                    )
                                }
                                .frame(height: 20)
                                
                                // Labels aligned exactly with snap points
                                GeometryReader { geometry in
                                    let trackWidth = geometry.size.width
                                    ZStack(alignment: .leading) {
                                        ForEach(0...5, id: \.self) { level in
                                            Text("\(level)")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                                .position(x: trackWidth * CGFloat(level) / 5.0, y: 8)
                                        }
                                    }
                                }
                                .frame(height: 16)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            temperature = device.temperature
            selectedMode = device.mode
            isPowerOn = device.isOn
            loadDeviceDetails()
        }
    }
    
    private func loadDeviceDetails() {
        isLoadingDetails = true
        Task {
            do {
                let acDetails = try await SmartRoomAPIService.shared.getAirConditionById(device.id)
                
                await MainActor.run {
                    isPowerOn = acDetails.power == "ON"
                    temperature = acDetails.temperature
                    selectedMode = acDetails.mode
                    fanSpeed = acDetails.fanSpeed
                    swingOn = acDetails.swing == "ON"
                    isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    isLoadingDetails = false
                }
                print("❌ Failed to load AC details \(device.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateTemperature(newValue: Int) {
        let previousValue = temperature
        temperature = newValue
        isUpdatingTemperature = true
        
        Task {
            do {
                let updatedAC = try await SmartRoomAPIService.shared.updateTemperature(device.id, temperature: newValue)
                
                await MainActor.run {
                    temperature = updatedAC.temperature
                    isPowerOn = updatedAC.power == "ON"
                    selectedMode = updatedAC.mode
                    isUpdatingTemperature = false
                }
            } catch {
                // Revert to previous value on error
                await MainActor.run {
                    temperature = previousValue
                    isUpdatingTemperature = false
                }
                print("❌ Failed to update temperature \(device.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateMode(newMode: String) {
        let previousMode = selectedMode
        selectedMode = newMode
        isUpdatingMode = true
        
        Task {
            do {
                let updatedAC = try await SmartRoomAPIService.shared.updateMode(device.id, mode: newMode)
                
                await MainActor.run {
                    selectedMode = updatedAC.mode
                    isPowerOn = updatedAC.power == "ON"
                    temperature = updatedAC.temperature
                    isUpdatingMode = false
                }
            } catch {
                // Revert to previous mode on error
                await MainActor.run {
                    selectedMode = previousMode
                    isUpdatingMode = false
                }
                print("❌ Failed to update mode \(device.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFanSpeed(newSpeed: Int) {
        isUpdatingFanSpeed = true
        
        Task {
            do {
                // Fan speed: 0 means AUTO, API accepts 0-5
                let updatedAC = try await SmartRoomAPIService.shared.updateFanSpeed(device.id, speed: newSpeed)
                
                await MainActor.run {
                    fanSpeed = updatedAC.fanSpeed
                    isPowerOn = updatedAC.power == "ON"
                    isUpdatingFanSpeed = false
                }
            } catch {
                // Revert to default speed (3) on error
                await MainActor.run {
                    fanSpeed = 3
                    isUpdatingFanSpeed = false
                }
                print("❌ Failed to update fan speed \(device.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSwing(newState: Bool) {
        let previousState = swingOn
        swingOn = newState
        isUpdatingSwing = true
        
        Task {
            do {
                let state = newState ? "ON" : "OFF"
                let updatedAC = try await SmartRoomAPIService.shared.updateSwing(device.id, state: state)
                
                await MainActor.run {
                    swingOn = updatedAC.swing == "ON"
                    isPowerOn = updatedAC.power == "ON"
                    isUpdatingSwing = false
                }
            } catch {
                // Revert to previous state on error
                await MainActor.run {
                    swingOn = previousState
                    isUpdatingSwing = false
                }
                print("❌ Failed to update swing \(device.id): \(error.localizedDescription)")
            }
        }
    }
    
    private func togglePower() {
        let previousState = isPowerOn
        isPowerOn.toggle()
        isTogglingPower = true
        
        Task {
            do {
                let power = isPowerOn ? "ON" : "OFF"
                let updatedAC = try await SmartRoomAPIService.shared.updateAirCondition(device.id, power: power)
                
                // Update state with response from server
                await MainActor.run {
                    isPowerOn = updatedAC.power == "ON"
                    temperature = updatedAC.temperature
                    selectedMode = updatedAC.mode
                    isTogglingPower = false
                }
            } catch {
                // Revert to previous state on error
                await MainActor.run {
                    isPowerOn = previousState
                    isTogglingPower = false
                }
                print("❌ Failed to toggle AC power \(device.id): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Temperature Gauge View
struct TemperatureGaugeView: View {
    let temperature: Int
    let maxTemp: Int
    let modeColor: Color
    
    var progress: Double {
        Double(temperature - 16) / Double(maxTemp - 16)
    }
    
    var body: some View {
        ZStack {
            // Background Arc
            Circle()
                .trim(from: 0.125, to: 0.875)
                .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(90))
            
            // Progress Arc
            Circle()
                .trim(from: 0.125, to: 0.125 + (0.75 * progress))
                .stroke(modeColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(90))
            
            // Thumb at end of progress
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(modeColor, lineWidth: 3)
                )
                .offset(x: thumbPosition().x, y: thumbPosition().y)
        }
    }
    
    func thumbPosition() -> CGPoint {
        // Arc starts at 0.125 and goes to 0.875 (total 0.75 range)
        // With 90 degree rotation applied to the circle
        let progressPosition = 0.125 + (0.75 * progress)
        // Convert to angle (in radians) and add 90 degree rotation
        let angle = progressPosition * 2 * .pi + (.pi / 2)
        let radius: CGFloat = 80
        return CGPoint(
            x: radius * cos(CGFloat(angle)),
            y: radius * sin(CGFloat(angle))
        )
    }
}

#Preview {
    ACDetailScreen(device: ACDevice(
        from: AirCondition(
            id: 1,
            naturalId: "AC-PREVIEW-001",
            name: "Điều hòa phòng server",
            description: "Preview AC",
            isActive: true,
            roomId: 1,
            power: "ON",
            temperature: 25,
            mode: "COOL",
            fanSpeed: 3,
            swing: "OFF"
        )
    ))
}
