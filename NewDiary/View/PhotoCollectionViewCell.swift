import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var diaryPhoto: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(diaryPhoto)
        contentView.addSubview(deleteButton)
        
        diaryPhoto.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        diaryPhoto.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        diaryPhoto.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        diaryPhoto.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        deleteButton.topAnchor.constraint(equalTo: diaryPhoto.topAnchor, constant: -10).isActive = true
        deleteButton.rightAnchor.constraint(equalTo: diaryPhoto.rightAnchor, constant: 10).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Fix for button action not triggering
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha >= 0.01, self.point(inside: point, with: event) else { return nil }

        if deleteButton.point(inside: convert(point, to: deleteButton), with: event) {
            return deleteButton
        }

        return super.hitTest(point, with: event)
    }
}
