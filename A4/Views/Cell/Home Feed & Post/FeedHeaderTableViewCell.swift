//
//  FeedHeaderTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import FirebaseAuth
import Firebase


class FeedHeaderTableViewCell: UITableViewCell {


    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(with userId: String, userName: String) {
            nameLabel.text = userName
            loadProfileImage(for: userId)
        }

        private func loadProfileImage(for userId: String) {
            let storageRef = Storage.storage().reference().child("\(userId)/profile/profile_picture.jpg")
            storageRef.downloadURL { [weak self] url, error in
                if let url = url {
                    self?.loadImage(from: url)
                } else {
                    print("Error loading profile image: \(error?.localizedDescription ?? "No error info")")
                    DispatchQueue.main.async {
                        self?.profileImageView.image = UIImage(named: "defaultProfile")
                    }
                }
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

}
