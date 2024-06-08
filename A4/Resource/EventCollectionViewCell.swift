//
//  EventCollectionViewCell.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation
import UIKit


/**
 EventCollectionViewCell  represents a cell in a collection view that displays event information, including the day of the month and event details.
 */
class EventCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dayOfMoth: UILabel! // Label displaying the day of the month
    
    @IBOutlet weak var eventLabel: UILabel! // Label displaying the event details

}
