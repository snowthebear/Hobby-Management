//
//  PhotoCollectionViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

/**
 PhotoCollectionViewCell is a custom collection view cell that displays a photo.
 */
class PhotoCollectionViewCell: UICollectionViewCell {
    static let identifier = "PhotoCollectionViewCell" // The identifier for the cell, used for dequeuing reusable cells.
    
    // Image view displaying the photo
    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    /**
     Initializes the cell with a frame.
     - Parameters:
       - frame: The frame rectangle for the cell, measured in points.
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(photoImageView)
        contentView.clipsToBounds = true
        accessibilityLabel = "User Post Image"
        accessibilityHint = "Double-tap to open post"
    }
    
    /**
     Initializes the cell from a coder.
     - Parameters:
       - coder: The coder to initialize the cell from.
     - Throws: `fatalError` if called, as this initializer is not implemented.
     */
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Lays out subviews and sets the frame for the photo image view.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        photoImageView.frame = contentView.bounds
        
    }
    
    /**
     Prepares the cell for reuse by resetting the image view.
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
    
    /**
    Configures the cell with a `UserPost` model.
    - Parameters:
      - model: The `UserPost` model containing the photo URL.
    */
    public func configure(with model: UserPost){
        let url = model.photoURL
        photoImageView.sd_setImage(with: url)
    
    }
    
    /**
     Configures the cell with an image name.
     - Parameters:
       - imageName: The name of the image to display.
     */
    public func configure(with imageName: String){
        photoImageView.image = UIImage(named: imageName)
    }
    
    /**
    Configures the cell with a photo URL.
    - Parameters:
      - url: The URL of the photo to display.
    */
    public func configure(with url: URL) {
        photoImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
    }
}
