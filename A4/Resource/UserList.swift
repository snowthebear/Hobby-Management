//
//  UserList.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 13/05/24.
//

import Foundation
import FirebaseFirestoreSwift


/**
 UserList represents a user's list of hobbies.
 It includes an optional document ID, a name for the list, and an array of hobbies.
 */
class UserList: NSObject, Codable {
    @DocumentID var id: String? // The document ID of the user list in Firestore
    var name: String?
    var hobbies: [Hobby]
    
    /**
     Initializes a new UserList  instance with an empty list of hobbies.
     */
    override init() {
        self.hobbies = []
        super.init()
    }

}
