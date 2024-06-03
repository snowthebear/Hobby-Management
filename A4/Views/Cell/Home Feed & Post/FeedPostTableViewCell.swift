//
//  FeedPostTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import SDWebImage


class FeedPostTableViewCell: UITableViewCell {
    

    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    func configure(with photoURL: URL, date: Date, duration: Int) {
        postImageView.image = nil
        dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        
        let hours = String(duration / 60)
        let minutes = String(duration % 60)
        durationLabel.text = "\(hours) hour \(minutes) minute"
        postImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "placeholder"))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.sd_cancelCurrentImageLoad()
        postImageView.image = nil  // Optionally set a placeholder image
    }

//    private func loadImage(from url: URL) {
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            guard let data = data, error == nil else {
//                print("Error downloading image: \(error?.localizedDescription ?? "No error info")")
//                return
//            }
//            DispatchQueue.main.async {
//                self?.postImageView.image = UIImage(data: data)
//            }
//        }.resume()
//    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
