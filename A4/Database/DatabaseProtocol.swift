//
//  DatabaseProtocol.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import Firebase
import FirebaseAuth

enum DatabaseChange{
    case add
    case remove
    case update
}

enum ListenerType {
    case team
    case heroes
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
}
 

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
}

