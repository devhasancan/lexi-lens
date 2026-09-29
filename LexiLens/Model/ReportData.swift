import Foundation

struct ReportData: Codable {
    let riskLevel: String
    let summary: String
    let threats: [String]
    let keyDates: [String]
}

struct ClaudeAPIResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let text: String
}

