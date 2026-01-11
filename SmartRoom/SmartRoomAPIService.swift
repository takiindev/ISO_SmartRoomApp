import Foundation
import Combine

// MARK: - API Error Types
enum SmartRoomAPIError: Error, Equatable {
    case tokenExpired
    case networkError(String)
    case invalidResponse
    case unauthorized

    static func == (lhs: SmartRoomAPIError, rhs: SmartRoomAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.tokenExpired, .tokenExpired),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized):
            return true
        case (.networkError(let l), .networkError(let r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Models
struct Floor: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
}

struct Room: Codable, Identifiable {
    let id: Int
    let name: String
    let floorId: Int
    let description: String?
}

struct Light: Codable, Identifiable {
    let id: Int
    let name: String
    let roomId: Int
    var isActive: Bool
    var level: Int
    let description: String?
}

// MARK: - Auth Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginAPIResponse: Codable {
    let status: Int
    let message: String
    let data: LoginTokenData
    let timestamp: String
}

struct LoginTokenData: Codable {
    let token: String
    let type: String
    let username: String
    let groups: [String]
}

// MARK: - Common API Response
struct APIResponse<T: Codable>: Codable {
    let status: Int
    let message: String
    let data: T
    let timestamp: String
}

struct PaginatedData<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
}

struct LightToggleResponse: Codable {
    let status: String
    let message: String
    let error: String?
}

// MARK: - SmartRoomAPIService
final class SmartRoomAPIService {

    static let shared = SmartRoomAPIService()
    private init() {}

    private var baseURL: String = "http://192.168.2.29:8080/api/v1"

    var onTokenExpired: (() -> Void)?

    func setBaseURL(_ url: String) {
        self.baseURL = url
        print("🌐 Base URL set to: \(url)")
    }

    private func makeURL(_ path: String) -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            fatalError("Invalid URL: \(baseURL)\(path)")
        }
        return url
    }

    // MARK: - Private Authenticated Request
    private func makeAuthenticatedRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SmartRoomAPIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return data
        case 401:
            onTokenExpired?()
            throw SmartRoomAPIError.tokenExpired
        default:
            throw SmartRoomAPIError.networkError(
                "HTTP \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    // MARK: - Login
    func login(username: String, password: String) async throws -> LoginTokenData {
        let url = makeURL("/auth/signin")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SmartRoomAPIError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(LoginAPIResponse.self, from: data)
            return decoded.data
        case 401:
            throw SmartRoomAPIError.unauthorized
        default:
            throw SmartRoomAPIError.networkError(
                "HTTP \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    // MARK: - Floors
    func getFloors(page: Int = 0, size: Int = 50) async throws -> [Floor] {
        let url = makeURL("/floors?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<Floor>>.self, from: data)
        return response.data.content
    }

    // MARK: - Rooms
    func getRoomsByFloor(_ floorId: Int, page: Int = 0, size: Int = 50) async throws -> [Room] {
        let url = makeURL("/floors/\(floorId)/rooms?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<Room>>.self, from: data)
        return response.data.content
    }

    // MARK: - Lights
    func getLightsByRoom(_ roomId: Int) async throws -> [Light] {
        let url = makeURL("/lights/room/\(roomId)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<Light>>.self, from: data)
        return response.data.content
    }

    func getLightById(_ lightId: Int) async throws -> Light {
        let url = makeURL("/lights/\(lightId)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<Light>.self, from: data)
        return response.data
    }

    // MARK: - Light Actions
    func updateLightState(_ lightId: Int) async throws -> Bool {
        let url = makeURL("/lights/\(lightId)/toggle-state")
        let body = try JSONSerialization.data(withJSONObject: [:])
        let data = try await makeAuthenticatedRequest(url: url, method: "PUT", body: body)
        let response = try JSONDecoder().decode(APIResponse<LightToggleResponse>.self, from: data)
        return response.data.error == nil
    }

    func updateLightLevel(_ lightId: Int, level: Int) async throws -> Bool {
        let url = makeURL("/lights/\(lightId)/level")
        let body = try JSONSerialization.data(withJSONObject: ["level": level])
        _ = try await makeAuthenticatedRequest(url: url, method: "PUT", body: body)
        return true
    }
    
    func getRawLightsByRoom(_ roomId: Int) async throws -> String {
        let url = makeURL("/lights/room/\(roomId)")
        let data = try await makeAuthenticatedRequest(url: url)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    func toggleLightAndGetResponse(_ lightId: Int) async throws -> String {
        let url = makeURL("/lights/\(lightId)/toggle-state")
        let body = try JSONSerialization.data(withJSONObject: [:])
        let data = try await makeAuthenticatedRequest(url: url, method: "PUT", body: body)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    func updateLightState(_ lightId: Int, isActive: Bool) async throws -> Bool {
            let url = makeURL("/lights/\(lightId)/toggle-state") // giả sử API không có set trực tiếp
            if isActive {
                // nếu light cần bật và đang tắt → toggle
                let _ = try await updateLightState(lightId)
            }
            // hoặc nếu API có endpoint set on/off trực tiếp, thay URL & body
            return true
        }
    func getRawLightById(_ lightId: Int) async throws -> String {
        let url = makeURL("/lights/\(lightId)")
        let data = try await makeAuthenticatedRequest(url: url)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    // MARK: - Temperature Sensors
    func getTemperatureSensorsByRoom(_ roomId: Int, page: Int = 0, size: Int = 50) async throws -> [TemperatureSensor] {
        let url = makeURL("/rooms/\(roomId)/temperatures?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<TemperatureSensor>>.self, from: data)
        return response.data.content
    }
    
    // MARK: - Temperature History
    func getTemperatureHistory(roomId: Int, startedAt: String, endedAt: String) async throws -> [TemperatureHistoryPoint] {
        let url = makeURL("/rooms/\(roomId)/temperatures/average-history?startedAt=\(startedAt)&endedAt=\(endedAt)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[TemperatureHistoryPoint]>.self, from: data)
        return response.data
    }
    
    // MARK: - Power Consumption Sensors
    func getPowerSensorsByRoom(_ roomId: Int, page: Int = 0, size: Int = 50) async throws -> [PowerSensor] {
        let url = makeURL("/rooms/\(roomId)/power-consumptions?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<PowerSensor>>.self, from: data)
        return response.data.content
    }
    
    func getRawPowerSensorsByRoom(_ roomId: Int, page: Int = 0, size: Int = 50) async throws -> String {
        let url = makeURL("/rooms/\(roomId)/power-consumptions?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    // MARK: - Power Consumption History
    func getPowerConsumptionHistory(roomId: Int, from: String, to: String) async throws -> [PowerHistoryPoint] {
        let url = makeURL("/rooms/\(roomId)/power-consumption-values/sum?from=\(from)&to=\(to)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[PowerHistoryPoint]>.self, from: data)
        return response.data
    }
    
    // MARK: - Groups
    func getAllGroups() async throws -> [APIGroup] {
        let url = makeURL("/groups/all")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[APIGroup]>.self, from: data)
        return response.data
    }
    
    func createGroup(groupCode: String, name: String, description: String?, langCode: String? = "vi") async throws -> APIGroup {
        let url = makeURL("/groups")
        let requestBody = CreateGroupRequest(
            groupCode: groupCode,
            name: name,
            description: description,
            langCode: langCode
        )
        let body = try JSONEncoder().encode(requestBody)
        let data = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let response = try JSONDecoder().decode(APIResponse<APIGroup>.self, from: data)
        return response.data
    }
    
    func deleteGroup(groupId: Int) async throws {
        let url = makeURL("/groups/\(groupId)")
        _ = try await makeAuthenticatedRequest(url: url, method: "DELETE")
    }
    
    func getGroupClients(groupId: Int) async throws -> [GroupClient] {
        let url = makeURL("/groups/\(groupId)/clients/all")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[GroupClient]>.self, from: data)
        return response.data
    }
    
    func getAllClients(page: Int = 0, size: Int = 50) async throws -> [GroupClient] {
        let url = makeURL("/clients?page=\(page)&size=\(size)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<PaginatedData<GroupClient>>.self, from: data)
        return response.data.content
    }
    
    func createClient(
        username: String,
        password: String,
        clientType: String,
        ipAddress: String?,
        macAddress: String?,
        avatarUrl: String?
    ) async throws -> GroupClient {
        let url = makeURL("/clients")
        let requestBody = CreateClientRequest(
            username: username,
            password: password,
            clientType: clientType,
            ipAddress: ipAddress,
            macAddress: macAddress,
            avatarUrl: avatarUrl
        )
        let body = try JSONEncoder().encode(requestBody)
        let data = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let response = try JSONDecoder().decode(APIResponse<GroupClient>.self, from: data)
        return response.data
    }
    
    func removeClientFromGroup(clientId: Int, groupId: Int) async throws {
        let url = makeURL("/roles/clients/\(clientId)/groups/\(groupId)")
        _ = try await makeAuthenticatedRequest(url: url, method: "DELETE")
    }
    
    func getClientGroups(clientId: Int) async throws -> [APIGroup] {
        let url = makeURL("/clients/\(clientId)/groups/all")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[APIGroup]>.self, from: data)
        return response.data
    }
    
    func getGroupsWithClientStatus(clientId: Int) async throws -> [GroupWithStatus] {
        let url = makeURL("/groups/with-client-status/\(clientId)")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[GroupWithStatus]>.self, from: data)
        return response.data
    }
    
    func assignGroupsToClient(clientId: Int, groupIds: [Int]) async throws -> AssignGroupsResponse {
        let url = makeURL("/roles/clients/groups/assign")
        let requestBody = AssignGroupsRequest(clientId: clientId, groupIds: groupIds)
        let body = try JSONEncoder().encode(requestBody)
        let data = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let response = try JSONDecoder().decode(APIResponse<AssignGroupsResponse>.self, from: data)
        return response.data
    }
    
    func unassignGroupsFromClient(clientId: Int, groupIds: [Int]) async throws {
        let url = makeURL("/roles/clients/groups/unassign")
        let requestBody = AssignGroupsRequest(clientId: clientId, groupIds: groupIds)
        let body = try JSONEncoder().encode(requestBody)
        _ = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
    }
    
    // MARK: - Function APIs
    func getAllFunctions() async throws -> [APIFunction] {
        let url = makeURL("/functions/all")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[APIFunction]>.self, from: data)
        return response.data
    }
    
    func getGroupFunctions(groupId: Int) async throws -> [APIFunction] {
        let url = makeURL("/groups/\(groupId)/functions/all")
        let data = try await makeAuthenticatedRequest(url: url)
        let response = try JSONDecoder().decode(APIResponse<[APIFunction]>.self, from: data)
        return response.data
    }
    
    func batchAddFunctionsToGroup(groupId: Int, functionCodes: [String]) async throws -> BatchFunctionsResponse {
        let url = makeURL("/roles/groups/functions/batch-add")
        let requestBody = BatchFunctionsRequest(groupId: groupId, functionCodes: functionCodes)
        let body = try JSONEncoder().encode(requestBody)
        let data = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let response = try JSONDecoder().decode(APIResponse<BatchFunctionsResponse>.self, from: data)
        return response.data
    }
    
    func batchRemoveFunctionsFromGroup(groupId: Int, functionCodes: [String]) async throws -> BatchFunctionsResponse {
        let url = makeURL("/roles/groups/functions/batch-remove")
        let requestBody = BatchFunctionsRequest(groupId: groupId, functionCodes: functionCodes)
        let body = try JSONEncoder().encode(requestBody)
        let data = try await makeAuthenticatedRequest(url: url, method: "POST", body: body)
        let response = try JSONDecoder().decode(APIResponse<BatchFunctionsResponse>.self, from: data)
        return response.data
    }
}

// MARK: - Temperature History Model
struct TemperatureHistoryPoint: Codable {
    let timestamp: String  // ISO8601 format from API
    let avgTempC: Double
}

// MARK: - Power Consumption Models
struct PowerSensor: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isActive: Bool
    let currentWatt: Double?
    let currentWattHour: Double?
    let naturalId: String
    let roomId: Int
}

struct PowerHistoryPoint: Codable {
    let timestamp: String  // ISO8601 format from API
    let sumWatt: Double
}
// MARK: - Group Models
struct APIGroup: Codable, Identifiable {
    let id: Int
    let groupCode: String
    let name: String
    let description: String?
}

struct CreateGroupRequest: Codable {
    let groupCode: String
    let name: String
    let description: String?
    let langCode: String?
}

// MARK: - Client Models
struct GroupClient: Codable, Identifiable {
    let id: Int
    let username: String
    let clientType: String
    let ipAddress: String?
    let macAddress: String?
    let avatarUrl: String?
    let lastLoginAt: String?
}

// MARK: - Create Client Models
struct CreateClientRequest: Codable {
    let username: String
    let password: String
    let clientType: String
    let ipAddress: String?
    let macAddress: String?
    let avatarUrl: String?
}

// MARK: - Group with Client Status Model
struct GroupWithStatus: Codable, Identifiable {
    let id: Int
    let groupCode: String
    let name: String
    let description: String?
    var isAssignedToClient: Bool
}

// MARK: - Assign/Unassign Groups Models
struct AssignGroupsRequest: Codable {
    let clientId: Int
    let groupIds: [Int]
}

struct AssignGroupsResponse: Codable {
    let successCount: Int
    let skippedCount: Int
    let failedCount: Int
    let message: String
}

// MARK: - Batch Add/Remove Functions Models
struct BatchFunctionsRequest: Codable {
    let groupId: Int
    let functionCodes: [String]
}

struct BatchFunctionsResponse: Codable {
    let successCount: Int
    let skippedCount: Int
    let failedCount: Int
    let message: String
}

// MARK: - Function Models
struct APIFunction: Codable, Identifiable {
    let id: Int
    let functionCode: String
    let name: String
    let description: String?
}