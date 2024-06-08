//
//  SearchUserCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 07/06/24.
//

import Foundation
import UIKit
import SDWebImage
import FirebaseAuth

/**
 SearchUserCell is a custom table view cell that displays a user's profile image and name.
 */
class SearchUserCell: UITableViewCell {

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
     Called after the cell is loaded from the nib or storyboard.
     Sets up the profile image view's appearance.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        setupProfileImageView()
    }

    /**
     Sets up the profile image view to be circular with a border.
     */
    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }
}
