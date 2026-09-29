import UIKit
import VisionKit
import Vision
import UniformTypeIdentifiers
import PDFKit

class ScannerViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIButton) {
        guard VNDocumentCameraViewController.isSupported else {
            print("Document scanning is not supported on this device")
            return
        }
        
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    @IBAction func galleryButtonPressed(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @IBAction func filesButtonPressed(_ sender: UIButton) {
        let supportedTypes: [UTType] = [.pdf, .text, .plainText]
        let documenntPickerController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documenntPickerController.delegate = self
        documenntPickerController.allowsMultipleSelection = false
        present(documenntPickerController, animated: true)
    }
    
    func recognizeText(from pages: [UIImage]) {
        var allText = ""
        
        for page in pages {
            guard let cgImage = page.cgImage else { continue }
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["tr-TR", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results ?? []
                let pageText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                allText += pageText + "\n"
            } catch {
                print("OCR failed for a page: \(error.localizedDescription)")
            }
        }
        
        let finalText = allText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        DispatchQueue.main.async {
            guard !finalText.isEmpty else {
                self.showMessage("No text could be read from the document.")
                return
            }
            self.performSegue(withIdentifier: "goToPrivacy", sender: finalText)
        }
    }
    
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func extractTextFromFile(at url: URL) {
        let fileExtension = url.pathExtension.lowercased()
        var finalExtractedText = ""
        
        if fileExtension == "pdf" {
            if let pdfDocument = PDFDocument(url: url) {
                let pageCount = pdfDocument.pageCount
                print("PDF has \(pageCount) page(s).")
                
                for i in 0..<pageCount {
                    if let page = pdfDocument.page(at: i), let pageText = page.string {
                        finalExtractedText += pageText + "\n"
                    }
                }
            }
        } else if fileExtension == "txt" || fileExtension == "rtf" {
            do {
                finalExtractedText = try String(contentsOf: url, encoding: .utf8)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("This file type is not supported.")
            return
        }
        
        if !finalExtractedText.isEmpty {
            performSegue(withIdentifier: "goToPrivacy", sender: finalExtractedText)
        } else {
            print("Not running...")
        }
    }
//MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let textVC = segue.destination as? TextViewController {
            textVC.onTextReady = { finalString in
                self.performSegue(withIdentifier: "goToPrivacy", sender: finalString)
            }
        }
        
        if let privacyVC = segue.destination as? PrivacyReviewViewController {
            if let incomingText = sender as? String {
                privacyVC.contractTextToProcess = incomingText
            }
        }
            
        
    }
}
//MARK: - VNDocumentCameraViewControllerDelegate Methods
extension ScannerViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var pages: [UIImage] = []
        for index in 0..<scan.pageCount {
            pages.append(scan.imageOfPage(at: index))
        }
        
        controller.dismiss(animated: true) { [weak self] in
            guard !pages.isEmpty else {
                self?.showMessage("No pages were scanned.")
                return
            }
            self?.recognizeText(from: pages)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        print("User cancelled the scanning process.")
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
        print("Failed to scan document: \(error.localizedDescription)")
        controller.dismiss(animated: true)
    }
}


//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate Methods
extension ScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true) { [weak self] in
                self?.recognizeText(from: [selectedImage])
            }
        } else {
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

//MARK: - UIDocumentPickerDelegate Methods
extension ScannerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        let canAccess = selectedFileURL.startAccessingSecurityScopedResource()
        extractTextFromFile(at: selectedFileURL)
        if canAccess {
            selectedFileURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
