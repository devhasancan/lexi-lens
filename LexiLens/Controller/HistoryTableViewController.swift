import UIKit

class HistoryTableViewController: UITableViewController {
    
    var reports: [Report] = []
    
    var selectedReport: Report?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 33/255.0, green: 21/255.0, blue: 15/255.0, alpha: 1.0)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        navigationController?.navigationBar.tintColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reports = HistoryManager.shared.fetchAll()
        tableView.reloadData()
        
        updateEmptyState()
    }

    //MARK: - Empty State
    private func updateEmptyState() {
        if reports.isEmpty {
            tableView.backgroundView = makeEmptyStateView()
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView()
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        let iconView = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: iconConfig))
        iconView.tintColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 0.5)
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = "No Reports Yet"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your analyzed contracts will appear here.\nTap \"Scan New Document\" to start."
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 136/255.0, green: 135/255.0, blue: 128/255.0, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return container
    }
    
    //MARK: - TableView DataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reports.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        let report = reports[indexPath.row]
        cell.configure(with: report)
        return cell
    }
    
    //MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedReport = reports[indexPath.row]
        performSegue(withIdentifier: "goToResultsFromHistory", sender: self)
        //Seçimi temizle (görsel olarak gri kalmasın).
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Segue Hazırlığı
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResultsFromHistory" {
            if let destinationVC = segue.destination as? ResultsViewController,
               let selectedReport = selectedReport,
               let reportData = HistoryManager.shared.reportData(from: selectedReport) {
                destinationVC.report = reportData
            }
        }
    }
    
    //MARK: - Swipe to Delete
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let report = reports[indexPath.row]
            HistoryManager.shared.delete(report: report)
            reports.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
