import UIKit

class TextViewController: UIViewController {

    @IBOutlet weak var inputTextView: UITextView!
    let placeHolderText = "Paste or enter your contract text here..."
    var onTextReady: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
    }
    
    func setupTextView() {
        inputTextView.delegate = self
        inputTextView.layer.cornerRadius = 15
        inputTextView.clipsToBounds = true
        inputTextView.text = placeHolderText
        inputTextView.textColor = UIColor(named: "LexiCream")?.withAlphaComponent(0.5)
    }
    
    @IBAction func analyzeTextButtonPressed(_ sender: UIButton) {
        if inputTextView.text == placeHolderText || inputTextView.text.isEmpty == true {
            return
        }
        let finalString = inputTextView.text!
        dismiss(animated: true) {
            self.onTextReady?(finalString)
        }
    }
    
}

//MARK: - UITextViewDelegate Methods
extension TextViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if inputTextView.text == placeHolderText {
            textView.text = ""
            textView.textColor = UIColor(named: "LexiCream")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeHolderText
            textView.textColor = UIColor(named: "LexiCream")?.withAlphaComponent(0.5)
        }
    }
}
