//
//  DatabaseProtocol.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import Firebase
import FirebaseAuth

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case goals
    case hobbies
    case list
    case all
    
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby])
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby])
    func onGoalsChange(change: DatabaseChange, goals: [String])
}
 
protocol DatabaseProtocol: AnyObject {
    func cleanup()
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    func addHobby(name: String, interest: Interest) -> Hobby
    func deleteHobby(hobby: Hobby)
    
    var currentUserList: UserList? {get set}
    
    func addUserList(listName: String) -> UserList
    func deleteUserList(list: UserList)
    func addHobbyToUserList(hobby: Hobby, userList: UserList) -> Bool
    func removeHobbyFromUserList(hobby: Hobby, userList: UserList)
    
    func addGoals(goal: String)
    func deleteGoals(goalId: String)

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signUpWithEmail(email: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void)
    
    func fetchGoals(completion: @escaping ([String]) -> Void)
}

