import UIKit
import PDFKit

class PDFGenerator {
    
    static func generate(from report: ReportData, createdAt: Date = Date()) -> URL? {
        
        let htmlContent = makeHTML(from: report, createdAt: createdAt)
        
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842)
        let printableRect = pageSize.insetBy(dx: 40, dy: 40)
        renderer.setValue(NSValue(cgRect: pageSize), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageSize, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: renderer.numberOfPages))
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        
        let fileName = "LexiLens_Report_\(Int(Date().timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: url, options: .atomic)
            return url
        } catch {
            print("PDF yazma hatası: \(error)")
            return nil
        }
    }
    
    private static func makeHTML(from report: ReportData, createdAt: Date) -> String {
        let riskColor: String
        switch report.riskLevel.lowercased() {
        case "critical": riskColor = "#E8453C"
        case "high":     riskColor = "#D67B5C"
        case "medium":   riskColor = "#E8B04A"
        case "low":      riskColor = "#8FBF7C"
        default:         riskColor = "#8E867E"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: createdAt)
        
        let threatsHTML = report.threats
            .map { "<li>\($0)</li>" }
            .joined()
        
        let datesHTML = report.keyDates
            .map { "<li>\($0)</li>" }
            .joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
            body {
                font-family: -apple-system, sans-serif;
                color: #2C2C2C;
                margin: 0;
                padding: 0;
                line-height: 1.5;
            }
            .header {
                border-bottom: 3px solid \(riskColor);
                padding-bottom: 16px;
                margin-bottom: 24px;
            }
            .app-name {
                font-size: 14px;
                color: #888780;
                letter-spacing: 2px;
            }
            .title {
                font-size: 28px;
                font-weight: bold;
                color: #21150F;
                margin: 8px 0 4px 0;
            }
            .date {
                font-size: 12px;
                color: #888780;
            }
            .risk-badge {
                display: inline-block;
                background: \(riskColor);
                color: white;
                padding: 6px 14px;
                border-radius: 6px;
                font-weight: bold;
                font-size: 14px;
                letter-spacing: 1px;
                margin: 16px 0;
            }
            .section {
                margin: 24px 0;
            }
            .section-title {
                font-size: 16px;
                font-weight: bold;
                color: #21150F;
                border-left: 3px solid \(riskColor);
                padding-left: 10px;
                margin-bottom: 10px;
            }
            .section-content {
                font-size: 13px;
                color: #2C2C2C;
            }
            ul {
                padding-left: 20px;
                margin: 0;
            }
            li {
                margin: 6px 0;
                font-size: 13px;
            }
            .footer {
                margin-top: 40px;
                padding-top: 16px;
                border-top: 1px solid #DDD;
                font-size: 11px;
                color: #888780;
                text-align: center;
            }
        </style>
        </head>
        <body>
            <div class="header">
                <div class="app-name">LEXILENS</div>
                <div class="title">Legal Document Analysis</div>
                <div class="date">Generated on \(dateString)</div>
            </div>
            
            <div class="risk-badge">RISK LEVEL: \(report.riskLevel.uppercased())</div>
            
            <div class="section">
                <div class="section-title">Legal Summary</div>
                <div class="section-content">\(report.summary)</div>
            </div>
            
            <div class="section">
                <div class="section-title">Threats &amp; Concerns</div>
                <div class="section-content">
                    <ul>\(threatsHTML)</ul>
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">Key Dates &amp; Deadlines</div>
                <div class="section-content">
                    <ul>\(datesHTML)</ul>
                </div>
            </div>
            
            <div class="footer">
                Generated by LexiLens — AI-Powered Legal Analysis<br>
                This document is for informational purposes only and does not constitute legal advice.
            </div>
        </body>
        </html>
        """
    }
}
