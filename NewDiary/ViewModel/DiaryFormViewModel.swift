import Foundation
import UIKit
import RxSwift

public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
}

public protocol ContentFieldsDelegate: AnyObject {
    func clearContents()
}

class DiaryFormViewModel: NSObject {
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    private weak var contentDelegate: ContentFieldsDelegate?
    
    var localPhotos = [UIImage?]()
    var imageStrings = [String]()
    var comments = ""
    var date = ""
    var area = ""
    var category = ""
    var tags = ""
    var event = ""
    
    public init(presentationController: UIViewController, delegate: ImagePickerDelegate, contentDelegate: ContentFieldsDelegate) {
        self.pickerController = UIImagePickerController()
        
        super.init()

        self.presentationController = presentationController
        self.delegate = delegate
        self.contentDelegate = contentDelegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }
}

extension DiaryFormViewModel {
    func toggleButton(_ button: UIButton) {
        guard let buttonImage = button.imageView?.image else { return }
        button.setImage(UIImage(systemName: buttonImage.isEqual(UIImage(systemName: "checkmark.square.fill")) ? "squareshape" : "checkmark.square.fill"), for: .normal)
    }
    
    func addDropdownToTextField(_ textField: UITextField) {
        textField.rightViewMode = UITextField.ViewMode.always
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let image = UIImage(systemName: "chevron.down")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        imageView.image = image
        textField.rightView = imageView
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    func present(from sourceView: UIView) {
        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "alert_action_camera".localize()) {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "alert_action_saved_photos".localize()) {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "alert_action_photo_library".localize()) {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "alert_action_cancel".localize(),
                                                style: .cancel,
                                                handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        self.delegate?.didSelect(image: image)
        
        if let base64String = convertToBase64(image) {
            imageStrings.append(base64String)
        }
    }
    
    private func convertToBase64(_ image: UIImage?) -> String? {
        guard let image = image, let imageData = image.pngData() else { return nil }
        return imageData.base64EncodedString(options: .lineLength64Characters)
    }
    
    func postDiaryData() {
        guard !imageStrings.isEmpty else {
            showAlert(title: "alert_add_diary_title_failed".localize(), message: "alert_add_diary_message_failed".localize())
            return
        }
        
        showLoadingView()
        
        let parameters: [String : Any] = ["comments": "\(comments)",
                                          "date": "\(date)",
                                          "area": "\(area)",
                                          "category": "\(category)",
                                          "tags": "\(tags)",
                                          "event": "\(event)",
                                          "imageData": imageStrings]
        
        WebService.shared.postDiaryData(parameters: parameters) { [unowned self] callback in
            self.hideLoadingView()
            
            switch callback {
                case .success(let user):
                    if let id = user.id {
                        self.showAlert(title: "alert_add_diary_title_success".localize(), message: String(format: "alert_add_diary_message_success".localize(), id))
                    }
                case .failure(let error):
                self.showAlert(title: "alert_add_diary_title_failed".localize(), message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        let action = UIAlertAction(title: "alert_confirm_button_title".localize(), style: UIAlertAction.Style.default) { _ in
            if title == "alert_add_diary_title_success".localize() {
                self.contentDelegate?.clearContents()
            }
        }
        
        alertController.addAction(action)
        self.presentationController?.present(alertController, animated: true)
    }
    
    private func showLoadingView() {
        let alert = UIAlertController(title: nil, message: "alert_loading_message".localize(), preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
        self.presentationController?.present(alert, animated: true, completion: nil)
    }
    
    private func hideLoadingView() {
        self.presentationController?.dismiss(animated: false, completion: nil)
    }
}

extension DiaryFormViewModel: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension DiaryFormViewModel: UINavigationControllerDelegate { }
