//
//  UserList.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 13/05/24.
//

import Foundation
import FirebaseFirestoreSwift

class UserList: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var hobbies: [Hobby]
    
    
    override init() {
        self.hobbies = []
        super.init()
    }

}
