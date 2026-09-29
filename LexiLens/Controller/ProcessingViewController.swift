import UIKit

class ProcessingViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var contractText: String?
    var reportManager = ReportManager()
    private var timer: Timer?
    private var stepCounter = 0
    private let statusMessages = [
        "Preparing contract data...",
        "Connecting to AI engine...",
        "Performing analysis (may take a few seconds)...",
        "Detailing the report..."
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reportManager.delegate = self
        activityIndicator.startAnimating()
        startStatusTimer()
        
        if let text = contractText {
            reportManager.performRequest(with: text)
        }
    }
    
    private func startStatusTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.stepCounter < self.statusMessages.count - 1 {
                self.stepCounter += 1
                self.statusLabel.text = self.statusMessages[self.stepCounter]
            }
        }
    }
}
//MARK: - ReportManagerDelegate Methods

extension ProcessingViewController: ReportManagerDelegate {
    func didUpdateAnalysis(_ reportManager: ReportManager, report: ReportData) {
        timer?.invalidate()
        
        DispatchQueue.main.async {
            HistoryManager.shared.save(reportData: report)
            self.performSegue(withIdentifier: "goToResults", sender: report)
        }
    }
    
    func didFailWithError(error: any Error) {
        timer?.invalidate()
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.showErrorAlert()
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Connection Error",
            message: "An error occurred during the analysis. Please check your internet connection and try again.",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            if let nav = self?.navigationController {
                nav.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        }
        
        let retryAction = UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            guard let self = self, let text = self.contractText else { return }
            self.activityIndicator.startAnimating()
            self.stepCounter = 0
            self.statusLabel.text = self.statusMessages[0]
            self.startStatusTimer()
            self.reportManager.performRequest(with: text)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(retryAction)
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Navigation

extension ProcessingViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResults" {
            let destinationVC = segue.destination as! ResultsViewController
            if let reportData = sender as? ReportData {
                destinationVC.report = reportData
            }
        }
    }
}
