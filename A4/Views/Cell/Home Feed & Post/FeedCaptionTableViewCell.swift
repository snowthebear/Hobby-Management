//
//  FeedCaptionTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

class FeedCaptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var captionLabel: UILabel!
    
    func configure(with caption: String) {
        captionLabel.text = caption
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
