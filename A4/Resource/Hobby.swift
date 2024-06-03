//
//  Hobby.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 13/05/24.
//

import Foundation
import FirebaseFirestoreSwift

enum Interest: Int {
    case sports = 0
    case arts = 1
    case others = 2
}

class Hobby: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var interest: Int?
    var duration: Int?
}

extension Hobby {
    var interesthobby: Interest {
        get {
            return Interest(rawValue: self.interest!)!
        }
        
        set {
            self.interest = newValue.rawValue
        }
    }
}

enum CodingKeys: String, CodingKey {
    case id
    case name
    case interest
}
