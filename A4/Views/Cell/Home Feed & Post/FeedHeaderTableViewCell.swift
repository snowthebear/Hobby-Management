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


class FeedHeaderTableViewCell: UITableViewCell {


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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1.0
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    }

}
