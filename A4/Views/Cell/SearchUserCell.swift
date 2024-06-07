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

class SearchUserCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(with imageUrl: URL?, userName: String) {
        nameLabel.text = userName
        if let imageUrl = imageUrl {
            profileImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "defaultProfile"), options: .continueInBackground, completed: nil)
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupProfileImageView()
    }

    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }
}
