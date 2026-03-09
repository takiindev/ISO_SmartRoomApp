import SwiftUI

// MARK: - Home ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeMode: String = "home"
    @Published var selectedTab: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var floors: [Floor] = []
    @Published var allRooms: [Room] = []
    
    private let apiService = SmartRoomAPIService.shared
    
    init() {}
    
    func loadFloorsAndRooms() {
        Task {
            await performDataLoad()
        }
    }
    
    func retry() {
        errorMessage = nil
        loadFloorsAndRooms()
    }
    
    func getRoomsForFloor(_ floorId: Int) -> [Room] {
        allRooms.filter { $0.floorId == floorId }
    }
    
    func onTabChanged() {
        loadFloorsAndRooms()
    }
    
    private func performDataLoad() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Load floors
            print("📊 Loading floors...")
            let loadedFloors = try await apiService.getFloors()
            floors = loadedFloors
            print("✅ Loaded \(loadedFloors.count) floors")
            
            // 2. Load rooms for all floors
            print("📊 Loading rooms for \(loadedFloors.count) floors...")
            let roomsArrays = try await withThrowingTaskGroup(of: [Room].self) { group in
                for floor in loadedFloors {
                    group.addTask {
                        try await self.apiService.getRoomsByFloor(floor.id)
                    }
                }
                
                var result: [[Room]] = []
                for try await rooms in group {
                    result.append(rooms)
                }
                return result
            }
            
            var loadedRooms = roomsArrays.flatMap { $0 }
            print("✅ Loaded \(loadedRooms.count) rooms")
            
            // 3. Load device count for each room
            print("📊 Loading device counts for \(loadedRooms.count) rooms...")
            loadedRooms = try await withThrowingTaskGroup(of: (Int, Int).self) { group in
                for room in loadedRooms {
                    group.addTask {
                        do {
                            let devices = try await self.apiService.getDevicesByRoom(room.id)
                            print("✅ Room '\(room.name)' has \(devices.count) devices")
                            return (room.id, devices.count)
                        } catch {
                            // Nếu lỗi, trả về 0 devices
                            print("⚠️  Failed to load devices for room \(room.id): \(error)")
                            return (room.id, 0)
                        }
                    }
                }
                
                // Collect device counts
                var deviceCounts: [Int: Int] = [:]
                for try await (roomId, count) in group {
                    deviceCounts[roomId] = count
                }
                
                // Update rooms with device counts
                return loadedRooms.map { room in
                    var updatedRoom = room
                    updatedRoom.deviceCount = deviceCounts[room.id] ?? 0
                    return updatedRoom
                }
            }
            
            allRooms = loadedRooms
            print("✅ Home data loaded successfully")
            print("   Total floors: \(floors.count)")
            print("   Total rooms: \(allRooms.count)")
            print("   Total devices: \(allRooms.reduce(0, { $0 + $1.deviceCount }))")
            isLoading = false
            
        } catch SmartRoomAPIError.tokenExpired {
            print("❌ Token expired")
            isLoading = false
        } catch {
            errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
            print("❌ Failed to load home data: \(error)")
            isLoading = false
        }
    }
}
