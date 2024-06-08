//
//  FeedHeaderTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import FirebaseAuth
import Firebase
import SDWebImage

/**
 FeedHeaderTableViewCell is a custom table view cell that displays a user's profile image and name.
 */
class FeedHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    /**
     Configures the cell with the user's profile image URL and name.
     - Parameters:
       - imageUrl: The URL of the user's profile image.
       - userName: The name of the user.
     */
    func configure(with imageUrl: URL?, userName: String) {
        nameLabel.text = userName
        if let imageUrl = imageUrl {
            profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "defaultProfile"), options: .continueInBackground, completed: nil)
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

    /**
     Loads an image from a URL and sets it to the profile image view.
     - Parameters:
       - url: The URL of the image to load.
     */
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "No error info")")
                return
            }
            DispatchQueue.main.async {
                self?.profileImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    /**
     Called after the cell is loaded from the nib or storyboard.
     Sets up the profile image view's appearance.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }

}
