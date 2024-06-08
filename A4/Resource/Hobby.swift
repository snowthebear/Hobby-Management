//
//  Hobby.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 13/05/24.
//

import Foundation
import FirebaseFirestoreSwift


/**
 Represents different types of interests for a hobby.
 */
enum Interest: Int {
    case sports = 0
    case arts = 1
    case others = 2
}

/**
Hobby represents a user's hobby with properties such as name, interest, and duration.
*/
class Hobby: NSObject, Codable {
    @DocumentID var id: String? // the document ID of the hobby in Firestore.
    var name: String?
    var interest: Int?
    var duration: Int?
}

/**
 Extension to Hobby to provide computed property for interest type.
 */
extension Hobby {
    // The interest type of the hobby as an `Interest` enum.
    var interesthobby: Interest {
        get {
            return Interest(rawValue: self.interest!)!
        }
        
        set {
            self.interest = newValue.rawValue
        }
    }
}

/**
 Coding keys used for encoding and decoding the Hobby properties.
 */
enum CodingKeys: String, CodingKey {
    case id
    case name
    case interest
}
