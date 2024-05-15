//
//  UserManager.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import FirebaseAuth

class UserManager {
    static let shared = UserManager()
    var currentUser: FirebaseAuth.User?
    var userData: [String: Any]?
    var currentUserList: UserList?

    private init() {}
}
