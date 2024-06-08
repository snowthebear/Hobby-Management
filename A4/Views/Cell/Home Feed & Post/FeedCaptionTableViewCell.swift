//
//  FeedCaptionTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

/**
 FeedCaptionTableViewCell is a custom table view cell that displays a caption for a feed post.
 */
class FeedCaptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var captionLabel: UILabel!
    
    /**
     Configures the cell with the provided caption.
     - Parameters:
       - caption: The caption text to display in the cell.
     */
    func configure(with caption: String) {
        captionLabel.text = caption
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
