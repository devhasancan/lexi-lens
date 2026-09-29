import UIKit
import VisionKit
import Vision

class DashboardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func scanDocumentTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToPreview", sender: self)
    }
    
}
//MARK: - VNDocumentCameraViewControllerDelegate Methods
extension DashboardViewController: VNDocumentCameraViewControllerDelegate {
    
}

//MARK: - UIImagePickerControllerDelegate Methods
extension DashboardViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
}
