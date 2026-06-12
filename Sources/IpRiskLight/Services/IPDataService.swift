import Foundation

struct IPDataService: Sendable {
    enum ServiceError: LocalizedError {
        case invalidAPIKey
        case quotaExceeded
        case badResponse(Int)
        case decoding

        var errorDescription: String? {
            switch self {
            case .invalidAPIKey: "API key 无效,请检查设置"
            case .quotaExceeded: "今日免费额度已用完,明日自动恢复"
            case .badResponse(let code): "请求失败 (HTTP \(code))"
            case .decoding: "响应解析失败"
            }
        }
    }

    func fetch(apiKey: String) async throws -> IPDataResponse {
        var components = URLComponents(string: "https://api.ipdata.co/")!
        components.queryItems = [URLQueryItem(name: "api-key", value: apiKey)]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.badResponse(-1)
        }
        switch http.statusCode {
        case 200:
            return try Self.decode(data)
        case 401, 403:
            throw ServiceError.invalidAPIKey
        case 429:
            throw ServiceError.quotaExceeded
        default:
            throw ServiceError.badResponse(http.statusCode)
        }
    }

    static func decode(_ data: Data) throws -> IPDataResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(IPDataResponse.self, from: data)
        } catch {
            throw ServiceError.decoding
        }
    }
}
