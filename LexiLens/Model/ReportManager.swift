import Foundation

protocol ReportManagerDelegate: AnyObject {
    func didUpdateAnalysis(_ reportManager: ReportManager, report: ReportData)
    func didFailWithError(error: Error)
}


struct ReportManager {
    
    let claudeURL = "https://api.anthropic.com/v1/messages"
    weak var delegate: ReportManagerDelegate?
    
    func performRequest(with text: String) {
        guard let url = URL(string: claudeURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let systemPrompt = """
        You are LexiLens's senior contract analyst and attorney. Your task is to analyze the contract text sent by the user and identify hidden risks and important dates.

        CRITICAL RULES
        1. MASKED DATA: The user may have masked names, ID numbers, addresses, phone numbers, bank accounts, or company names in the contract with labels such as [PERSON], [EMAIL], [ORGANIZATION], [PHONE NUMBER], [BANK ACCOUNT], [ID NUMBER], [SECRET] or similar tags for data privacy and security purposes. NEVER treat these masks as a deficiency, error, or "Threat"! Assume that this data is complete in the original contract and focus ONLY on the "Legal Terms" and "Clauses" of the contract.
        2. STRICT FORMAT: Respond ONLY and EXCLUSIVELY in the JSON format below. Do NOT use markdown tags (```json), do NOT say 'Hello', do NOT add explanations. Start directly with the curly brace {.

        Template:
        {
            "riskLevel": "Low, Medium, High, or Critical",
            "summary": "Professional summary of the legal context and general purpose of the contract...",
            "threats": ["The unilateral termination authority in Clause X...", "Disproportionate penalty clause in case of confidentiality breach..."],
            "keyDates": ["[Meaning of Date/Period]: [Detected Date or Period]", "[e.g. Notice Period]: [30 Days]", "[e.g. Effective Date]: [January 1, 2026]"]
        }
        """
        
        let parameters: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.delegate?.didFailWithError(error: error)
                return
            }
            
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                self.delegate?.didFailWithError(error: self.serverError(for: http.statusCode))
                return
            }
            
            guard let safeData = data else {
                self.delegate?.didFailWithError(error: self.makeError("No data was received from the server."))
                return
            }
            
            if let report = self.parseJSON(with: safeData) {
                self.delegate?.didUpdateAnalysis(self, report: report)
            } else {
                self.delegate?.didFailWithError(error: self.makeError("Failed to analyze the contract."))
            }
        }
        task.resume()
    }
    
    
    func parseJSON(with apiData: Data) -> ReportData? {
        let decoder = JSONDecoder()
        do {
            let decodedAPIResponse = try decoder.decode(ClaudeAPIResponse.self, from: apiData)
            
            guard let firstContent = decodedAPIResponse.content.first else { return nil }
            var jsonString = firstContent.text
            
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if jsonString.hasPrefix("```") {
                if let firstNewline = jsonString.firstIndex(of: "\n") {
                    jsonString = String(jsonString[jsonString.index(after: firstNewline)...])
                }
                if jsonString.hasSuffix("```") {
                    jsonString = String(jsonString.dropLast(3))
                }
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            if let reportData = jsonString.data(using: .utf8) {
                let finalReport = try decoder.decode(ReportData.self, from: reportData)
                return finalReport
            }
            return nil
        } catch {
            #if DEBUG
            print("Error: \(error)")
            #endif
            return nil
        }
    }
    
    private func makeError(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "ReportManager", code: code,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    private func serverError(for statusCode: Int) -> NSError {
        let message: String
        switch statusCode {
        case 401: message = "Invalid API key. Please check your key."
        case 429: message = "Rate limit reached. Please wait a moment and try again."
        case 500: message = "The service is temporarily unavailable. Please try again."
        default: message = "The server returned an error (\(statusCode))"
        }
        return makeError(message, code: statusCode)
    }
}

