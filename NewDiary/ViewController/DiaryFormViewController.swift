import UIKit
import RxSwift
import RxCocoa

class DiaryFormViewController: UIViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var addPhotoButton: UIButton!
    @IBOutlet private weak var includePhotoButton: UIButton!
    @IBOutlet private weak var commentsTextField: UITextField!
    @IBOutlet private weak var dateTextField: UITextField!
    @IBOutlet private weak var areaTextField: UITextField!
    @IBOutlet private weak var categoryTextField: UITextField!
    @IBOutlet private weak var tagsTextField: UITextField!
    @IBOutlet private weak var linkEventButton: UIButton!
    @IBOutlet private weak var eventTextField: UITextField!
    @IBOutlet private weak var nextButton: UIButton!
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker(frame: .zero)
        datePicker.datePickerMode = .date
        datePicker.timeZone = TimeZone.current
        return datePicker
    }()
    
    var viewModel: DiaryFormViewModel!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = DiaryFormViewModel(presentationController: self, delegate: self, contentDelegate: self)
        configureNavBar()
        setUpObservables()
        setupCollectionView()
        registerForKeyboardNotifications()
        formatTextField()
    }
}

// MARK: Setup
extension DiaryFormViewController {
    private func configureNavBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                                                 target: self,
                                                                                 action: #selector(close))
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
    
    private func formatTextField() {
        viewModel.addDropdownToTextField(dateTextField)
        viewModel.addDropdownToTextField(areaTextField)
        viewModel.addDropdownToTextField(categoryTextField)
        viewModel.addDropdownToTextField(eventTextField)
        
        dateTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
                    target: self,
                    action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
}

// MARK: Rx
extension DiaryFormViewController {
    func setUpObservables() {
        disposeBag.insert([
            includePhotoButton
                .rx
                .tap
                .bind { [unowned self] in
                    viewModel.toggleButton(includePhotoButton)
                },
            linkEventButton
                .rx
                .tap
                .bind { [unowned self] in
                    viewModel.toggleButton(linkEventButton)
                },
            addPhotoButton
                .rx
                .tap
                .bind { [unowned self] in
                    viewModel.present(from: addPhotoButton)
                },
            nextButton
                .rx
                .tap
                .bind { [unowned self] in
                    dismissKeyboard()
                    viewModel.postDiaryData()
                },
            commentsTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(commentsTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.comments = text
                }),
            dateTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(dateTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.date = text
                }),
            areaTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(areaTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.area = text
                }),
            categoryTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(categoryTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.category = text
                }),
            tagsTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(tagsTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.tags = text
                }),
            eventTextField
                .rx
                .controlEvent(.editingChanged)
                .withLatestFrom(eventTextField.rx.text.orEmpty)
                .subscribe(onNext: { [unowned self] text in
                    self.viewModel.event = text
                }),
            ])
    }
}

// MARK: Button Action
extension DiaryFormViewController {
    @objc private func close() {
        // close button on click
    }
    
    @objc func deleteButtonTapped(sender: UIButton) {
        viewModel.localPhotos.remove(at: sender.tag)
        collectionView.reloadData()
    }
}

// MARK: Keyboard Notification
extension DiaryFormViewController {
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo
        let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: Collection View
extension DiaryFormViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.localPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoCollectionViewCell
        cell.diaryPhoto.image = viewModel.localPhotos[indexPath.item]
        cell.deleteButton.tag = indexPath.item
        cell.deleteButton.addTarget(self, action: #selector(deleteButtonTapped(sender:)), for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}

// MARK: Date Picker
extension DiaryFormViewController {
    @objc func handleDatePicker(sender: UIDatePicker) {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          dateTextField.text = dateFormatter.string(from: sender.date)
     }
}

// MARK: Image Picker
extension DiaryFormViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        viewModel.localPhotos.append(image)
        collectionView.reloadData()
    }
}

// MARK: Content Fields
extension DiaryFormViewController: ContentFieldsDelegate {
     func clearContents() {
         viewModel.localPhotos.removeAll()
         viewModel.imageStrings.removeAll()
         collectionView.reloadData()
         commentsTextField.text = ""
         dateTextField.text = ""
         areaTextField.text = ""
         categoryTextField.text = ""
         tagsTextField.text = ""
         eventTextField.text = ""
     }
}
