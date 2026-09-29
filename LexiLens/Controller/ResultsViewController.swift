import UIKit

class ResultsViewController: UIViewController {
    
    var report: ReportData?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let riskHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .black)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let summaryCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 58/255.0, green: 38/255.0, blue: 29/255.0, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        return view
    }()
    
    private let summaryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Legal Summary"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        return label
    }()
    
    private let summaryTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(red: 215/255.0, green: 204/255.0, blue: 200/255.0, alpha: 1.0)
        label.numberOfLines = 0
        return label
    }()
    
    private let threatsCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 58/255.0, green: 38/255.0, blue: 29/255.0, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        return view
    }()
    
    private let threatsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Threats"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        return label
    }()
    
    private let threatsListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private let datesCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 58/255.0, green: 38/255.0, blue: 29/255.0, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        return view
    }()
    
    private let datesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Key Dates and Deadlines"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        return label
    }()
    
    private let datesListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUIWithData()
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: UIAction { [weak self] _ in
                self?.shareButtonTapped()
            }
        )
        shareButton.tintColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
        navigationItem.rightBarButtonItem = shareButton
    }
    
    private func shareButtonTapped() {
        guard let report = report else {
            print("Paylaşılacak rapor yok.")
            return
        }
        
        guard let pdfURL = PDFGenerator.generate(from: report) else {
            let alert = UIAlertController(
                title: "Export Failed",
                message: "Could not generate the PDF. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(activityVC, animated: true)
    }
    
    private func updateUIWithData() {
        guard let report = report else { return }
        
        riskHeaderLabel.text = "Risk Level: \(report.riskLevel.uppercased())"
        switch report.riskLevel.lowercased() {
        case "critical":
            riskHeaderLabel.textColor = UIColor(red: 232/255.0, green: 69/255.0, blue: 60/255.0, alpha: 1.0)
        case "high":
            riskHeaderLabel.textColor = UIColor(red: 214/255.0, green: 123/255.0, blue: 92/255.0, alpha: 1.0)
        case "medium":
            riskHeaderLabel.textColor = UIColor(red: 232/255.0, green: 176/255.0, blue: 74/255.0, alpha: 1.0)
        case "low":
            riskHeaderLabel.textColor = UIColor(red: 143/255.0, green: 191/255.0, blue: 124/255.0, alpha: 1.0)
        default:
            riskHeaderLabel.textColor = UIColor(red: 142/255.0, green: 134/255.0, blue: 126/255.0, alpha: 1.0)
        }
        
        summaryTextLabel.text = report.summary
        
        threatsListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for threat in report.threats {
            
            let threatIconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let threatIconView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: threatIconConfig))
            threatIconView.tintColor = UIColor(red: 232/255.0, green: 69/255.0, blue: 60/255.0, alpha: 1.0)
            threatIconView.contentMode = .center
            threatIconView.translatesAutoresizingMaskIntoConstraints = false
            
            let threatBadgeView = UIView()
            threatBadgeView.backgroundColor = UIColor(red: 232/255.0, green: 69/255.0, blue: 60/255.0, alpha: 0.15)
            threatBadgeView.layer.cornerRadius = 14
            threatBadgeView.translatesAutoresizingMaskIntoConstraints = false
            threatBadgeView.addSubview(threatIconView)
            
            NSLayoutConstraint.activate([
                threatBadgeView.widthAnchor.constraint(equalToConstant: 28),
                threatBadgeView.heightAnchor.constraint(equalToConstant: 28),
                threatIconView.centerXAnchor.constraint(equalTo: threatBadgeView.centerXAnchor),
                threatIconView.centerYAnchor.constraint(equalTo: threatBadgeView.centerYAnchor)
            ])
            threatBadgeView.setContentHuggingPriority(.required, for: .horizontal)
            threatBadgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let threatLabel = UILabel()
            threatLabel.text = threat
            threatLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            threatLabel.textColor = UIColor(red: 215/255.0, green: 204/255.0, blue: 200/255.0, alpha: 1.0)
            threatLabel.numberOfLines = 0
            
            let threatRow = UIStackView(arrangedSubviews: [threatBadgeView, threatLabel])
            threatRow.axis = .horizontal
            threatRow.spacing = 12
            threatRow.alignment = .top
            
            threatsListStackView.addArrangedSubview(threatRow)
        }
        
        datesListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for date in report.keyDates {
            
            let dateIconConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let dateIconView = UIImageView(image: UIImage(systemName: "calendar", withConfiguration: dateIconConfig))
            dateIconView.tintColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 1.0)
            dateIconView.contentMode = .center
            dateIconView.translatesAutoresizingMaskIntoConstraints = false
            
            let dateBadgeView = UIView()
            dateBadgeView.backgroundColor = UIColor(red: 234/255.0, green: 224/255.0, blue: 207/255.0, alpha: 0.10)
            dateBadgeView.layer.cornerRadius = 14
            dateBadgeView.translatesAutoresizingMaskIntoConstraints = false
            dateBadgeView.addSubview(dateIconView)
            
            NSLayoutConstraint.activate([
                dateBadgeView.widthAnchor.constraint(equalToConstant: 28),
                dateBadgeView.heightAnchor.constraint(equalToConstant: 28),
                dateIconView.centerXAnchor.constraint(equalTo: dateBadgeView.centerXAnchor),
                dateIconView.centerYAnchor.constraint(equalTo: dateBadgeView.centerYAnchor)
            ])
            dateBadgeView.setContentHuggingPriority(.required, for: .horizontal)
            dateBadgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let dateLabel = UILabel()
            dateLabel.text = date
            dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            dateLabel.textColor = UIColor(red: 215/255.0, green: 204/255.0, blue: 200/255.0, alpha: 1.0)
            dateLabel.numberOfLines = 0
            
            let dateRow = UIStackView(arrangedSubviews: [dateBadgeView, dateLabel])
            dateRow.axis = .horizontal
            dateRow.spacing = 12
            dateRow.alignment = .top
            
            datesListStackView.addArrangedSubview(dateRow)
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 33/255.0, green: 21/255.0, blue: 16/255.0, alpha: 1.0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mainStackView)
        
        setupRiskHeader()
        setupSummaryCard()
        setupThreatsCard()
        setupDatesCard()
        setupConstraints()
    }
        
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupRiskHeader() {
        riskHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(riskHeaderLabel)
        mainStackView.setCustomSpacing(30, after: riskHeaderLabel)
    }

    private func setupSummaryCard() {
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        summaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(summaryCard)
        summaryCard.addSubview(summaryTitleLabel)
        summaryCard.addSubview(summaryTextLabel)
        
        NSLayoutConstraint.activate([
            summaryTitleLabel.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 16),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            
            summaryTextLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 12),
            summaryTextLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryTextLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            summaryTextLabel.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupThreatsCard() {
        threatsCardView.translatesAutoresizingMaskIntoConstraints = false
        threatsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        threatsListStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(threatsCardView)
        threatsCardView.addSubview(threatsTitleLabel)
        threatsCardView.addSubview(threatsListStackView)
        
        NSLayoutConstraint.activate([
            threatsTitleLabel.topAnchor.constraint(equalTo: threatsCardView.topAnchor, constant: 16),
            threatsTitleLabel.leadingAnchor.constraint(equalTo: threatsCardView.leadingAnchor, constant: 16),
            threatsTitleLabel.trailingAnchor.constraint(equalTo: threatsCardView.trailingAnchor, constant: -16),
            
            threatsListStackView.topAnchor.constraint(equalTo: threatsTitleLabel.bottomAnchor, constant: 12),
            threatsListStackView.leadingAnchor.constraint(equalTo: threatsCardView.leadingAnchor, constant: 16),
            threatsListStackView.trailingAnchor.constraint(equalTo: threatsCardView.trailingAnchor, constant: -16),
            threatsListStackView.bottomAnchor.constraint(equalTo: threatsCardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupDatesCard() {
        
        datesCardView.translatesAutoresizingMaskIntoConstraints = false
        datesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        datesListStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(datesCardView)
        datesCardView.addSubview(datesTitleLabel)
        datesCardView.addSubview(datesListStackView)
        
        NSLayoutConstraint.activate([
            datesTitleLabel.topAnchor.constraint(equalTo: datesCardView.topAnchor, constant: 16),
            datesTitleLabel.leadingAnchor.constraint(equalTo: datesCardView.leadingAnchor, constant: 16),
            datesTitleLabel.trailingAnchor.constraint(equalTo: datesCardView.trailingAnchor, constant: -16),
            
            datesListStackView.topAnchor.constraint(equalTo: datesTitleLabel.bottomAnchor, constant: 12),
            datesListStackView.leadingAnchor.constraint(equalTo: datesCardView.leadingAnchor, constant: 16),
            datesListStackView.trailingAnchor.constraint(equalTo: datesCardView.trailingAnchor, constant: -16),
            datesListStackView.bottomAnchor.constraint(equalTo: datesCardView.bottomAnchor, constant: -16)
        ])
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
