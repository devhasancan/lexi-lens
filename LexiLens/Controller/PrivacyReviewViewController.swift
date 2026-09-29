import UIKit
import NaturalLanguage

class PrivacyReviewViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    var contractTextToProcess: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardToolBar()
        startMaskingProcess()
    }
    
    func startMaskingProcess() {
        guard let originalText = contractTextToProcess else { return }
        let maskingRules: [(pattern: String, maskWord: String)] = [
            (pattern: "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", maskWord: "[EMAIL]"),
            (pattern: "\\b(?:https?://|www\\.)[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9.-]*)*\\b|\\b[a-zA-Z0-9.-]+\\.(?:com|net|org|io|co\\.uk|gov|edu|app)(?:/[a-zA-Z0-9.-]*)*\\b", maskWord: "[WEBSITE]"),
            (pattern: "\\b[A-Z]{2}[0-9]{2}[ ]?[A-Z0-9]{4}[ ]?[0-9]{4}[ ]?[0-9]{4}(?:[ ]?[0-9]{4}){0,4}(?:[ ]?[0-9]{1,3})?\\b", maskWord: "[BANK ACCOUNT]"),
            (pattern: "(?<![\\d-])(?:(?:\\d{4}[\\s-]?){3}\\d{4}|\\d{4}[\\s-]?\\d{6}[\\s-]?\\d{5})(?![\\d-])", maskWord: "[PAYMENT CARD]"),
            (pattern: "\\b\\d{3}[\\s-]?\\d{2}[\\s-]?\\d{4}\\b", maskWord: "[ID NUMBER]"),
            (pattern: "(?<!\\d)(?:\\+?\\d{1,3}[\\s-]?)?\\(?\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4}(?!\\d)", maskWord: "[PHONE NUMBER]")
        ]
        var safeText = originalText
        for (pattern, maskWord) in maskingRules {
            safeText = applyRegexMask(to: safeText, pattern: pattern, maskWord: maskWord)
        }
        safeText = applyNLPMask(to: safeText)
        textView.text = safeText
    }
    
    func applyRegexMask(to text: String, pattern: String, maskWord: String) -> String {
        do {
            let regexEngine = try NSRegularExpression(pattern: pattern, options: [])
            let fullRange = NSRange(location: 0, length: text.utf16.count)
            let safeText = regexEngine.stringByReplacingMatches(in: text, options: [], range: fullRange, withTemplate: maskWord)
            return safeText
        } catch {
            print("RegEx Error: \(error.localizedDescription)")
            return text
        }
    }
    
    func applyNLPMask(to text: String) -> String {
        var maskedText = text
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)
        
        var rangesToReplace: [(Range<String.Index>, String)] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                if tag == .personalName {
                    rangesToReplace.append((tokenRange, "[PERSON]"))
                } else if tag == .organizationName {
                    rangesToReplace.append((tokenRange, "[ORGANIZATION]"))
                }
            }
            return true
        }
        
        for (range, mask) in rangesToReplace.reversed() {
            maskedText.replaceSubrange(range, with: mask)
        }
        
        return maskedText
    }

    @IBAction func analyzeSecurelyPressed(_ sender: UIButton) {
        guard let textToAnalyze = textView.text, !textToAnalyze.isEmpty else { return }
        performSegue(withIdentifier: "goToProcessing", sender: textToAnalyze)
    }
        
    
    func setupKeyboardToolBar() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        toolBar.tintColor = .systemBlue
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 80, height: 44))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -15),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        let buttonsInfo: [(title: String, mask: String)] = [
            ("[SECRET]", "[SECRET]"),
            ("[PERSON]", "[PERSON]"),
            ("[ORGANIZATION]", "[ORGANIZATION]"),
            ("[ID NUMBER]", "[ID NUMBER]")
        ]
        
        for info in buttonsInfo {
            let button = UIButton(type: .system)
            button.setTitle(info.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitleColor(.white, for: .normal)
            
            let action = UIAction { [weak self] _ in
                self?.replaceSelectedText(with: info.mask)
            }
            button.addAction(action, for: .touchUpInside)
            stackView.addArrangedSubview(button)
            
            let separator = UIView()
            separator.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
            separator.heightAnchor.constraint(equalToConstant: 20).isActive = true
            stackView.addArrangedSubview(separator)
        }
        
        let scrollItem = UIBarButtonItem(customView: scrollView)
        
        let doneAction = UIAction { [weak self] _ in
            self?.view.endEditing(true)
        }
        let doneButton = UIBarButtonItem(title: "Done", primaryAction: doneAction)
        doneButton.style = .prominent
        
        toolBar.items = [scrollItem, doneButton]
        textView.inputAccessoryView = toolBar
        
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
    }
    
    func replaceSelectedText(with maskWord: String) {
        if let selectedRange = textView.selectedTextRange {
            textView.replace(selectedRange, withText: maskWord)
        }
    }
}

//MARK: - Navigations

extension PrivacyReviewViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProcessing" {
            if let destinationVC = segue.destination as? ProcessingViewController {
                if let textToSend = sender as? String {
                    destinationVC.contractText = textToSend
                }
            }
        }
    }
}
