//
//  FeedGoalsTableViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

class FeedGoalsTableViewCell: UITableViewCell {

    
    @IBOutlet weak var goalLabel: UILabel!
    
    func configure(with goals: [String]) {
        goalLabel.text = goals.joined(separator: ", ")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
