import Foundation
import CoreData
import UIKit

class HistoryManager {
    
    static let shared = HistoryManager()
    private init() {}
    
    private var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func save(reportData: ReportData) {
        let report = Report(context: context)
        report.id = UUID()
        report.riskLevel = reportData.riskLevel
        report.summary = reportData.summary
        report.createdAt = Date()
        
        let encoder = JSONEncoder()
        report.threatsData = try? encoder.encode(reportData.threats)
        report.keyDatesData = try? encoder.encode(reportData.keyDates)
        
        do {
            try context.save()
            print("Rapor başarıyla kaydedildi.")
        } catch {
            print("Kaydetme hatası: \(error)")
        }
    }
    
    func fetchAll() -> [Report] {
        let request: NSFetchRequest<Report> = Report.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Getirme hatası: \(error)")
            return []
        }
    }
    
    func delete(report: Report) {
        context.delete(report)
        do {
            try context.save()
        } catch {
            print("Silme hatası: \(error)")
        }
    }
    
    func reportData(from report: Report) -> ReportData? {
        guard let riskLevel = report.riskLevel,
              let summary = report.summary else { return nil }
        
        let decoder = JSONDecoder()
        let threats: [String] = (report.threatsData != nil)
        ? (try? decoder.decode([String].self, from: report.threatsData!)) ?? []
        : []
        let keyDates: [String] = (report.keyDatesData != nil)
        ? (try? decoder.decode([String].self, from: report.keyDatesData!)) ?? []
        : []
        
        return ReportData(
            riskLevel: riskLevel,
            summary: summary,
            threats: threats,
            keyDates: keyDates
        )
    }
}
