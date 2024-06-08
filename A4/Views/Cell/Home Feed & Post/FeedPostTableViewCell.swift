//
//  FeedPostTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import SDWebImage


/**
 FeedPostTableViewCell is a custom table view cell that displays a post with an image, date, and duration.
 */
class FeedPostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    /**
     Configures the cell with the post's photo URL, date, and duration.
     - Parameters:
       - photoURL: The URL of the post's photo.
       - date: The date of the post.
       - duration: The duration related to the post, in minutes.
     */
    func configure(with photoURL: URL, date: Date, duration: Int) {
        postImageView.image = nil
        dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        
        let hours = String(duration / 60)
        let minutes = String(duration % 60)
        durationLabel.text = "\(hours) hour \(minutes) minute"
        postImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "placeholder"))
    }
    
    /**
     Prepares the cell for reuse by resetting the image view and canceling any ongoing image download.
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.sd_cancelCurrentImageLoad()
        postImageView.image = nil  // Optionally set a placeholder image
    }

    /**
     Initializes the cell from a coder.
     - Parameters:
       - coder: The coder to initialize the cell from.
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
