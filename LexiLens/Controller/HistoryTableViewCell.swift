import UIKit

class HistoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var riskBadgeView: UIView!
    @IBOutlet weak var riskLevelLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    func configure(with report: Report) {
        let risk = report.riskLevel ?? "?"
        riskLevelLabel.text = risk.uppercased()
        summaryLabel.text = report.summary ?? ""
        
        let color: UIColor
        switch risk.lowercased() {
        case "critical":
            color = UIColor(red: 232/255.0, green: 69/255.0, blue: 60/255.0, alpha: 1.0)
        case "high":
            color = UIColor(red: 214/255.0, green: 123/255.0, blue: 92/255.0, alpha: 1.0)
        case "medium":
            color = UIColor(red: 232/255.0, green: 176/255.0, blue: 74/255.0, alpha: 1.0)
        case "low":
            color = UIColor(red: 143/255.0, green: 191/255.0, blue: 124/255.0, alpha: 1.0)
        default:
            color = UIColor(red: 142/255.0, green: 134/255.0, blue: 126/255.0, alpha: 1.0)
        }
        riskLevelLabel.textColor = color
        riskBadgeView.backgroundColor = color
        
        if let date = report.createdAt {
            dateLabel.text = formatDate(date)
        } else {
            dateLabel.text = ""
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let time = timeFormatter.string(from: date)
        
        if calendar.isDateInToday(date) {
            return "Today, \(time)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(time)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: date)), \(time)"
        }
    }
}
