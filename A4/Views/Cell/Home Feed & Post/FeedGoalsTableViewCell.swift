//
//  FeedGoalsTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

/**
 FeedGoalsTableViewCell is a custom table view cell that displays the goals for a feed post.
 */
class FeedGoalsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var goalLabel: UILabel!
    
    /**
     Configures the cell with the provided goals.
     - Parameters:
       - goals: The goals text to display in the cell.
     */
    func configure(with goals: String) {
        goalLabel.text = goals
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
