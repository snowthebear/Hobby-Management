//
//  DatabaseProtocol.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import Firebase
import FirebaseAuth


/**
 Represents the type of changes that can occur in the database.
 */
enum DatabaseChange {
    case add
    case remove
    case update
}

/**
 Represents the different types of listeners that can be registered.
 */
enum ListenerType {
    case goals
    case hobbies
    case list
    case all
}

/**
 Protocol for listening to database changes.
 */
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set} // the thype of listener.
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) // Called when there is a change in the user's list of hobbies.
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) // Called when there is a change in all hobbies in the database.
    func onGoalsChange(change: DatabaseChange, goals: [Goal]) // Called when there is a change in the user's goals in the database.
}
 
/**
 Protocol for database operations.
 */
protocol DatabaseProtocol: AnyObject {
    func cleanup() // Cleans up the database, removing any temporary data or listeners.
    
    func addListener(listener: DatabaseListener) // Adds a listener to the database.
    func removeListener(listener: DatabaseListener) // Removes a listener from the database.
    
    func addHobby(name: String, interest: Interest) -> Hobby // Adds a new hobby to the database.
    func deleteHobby(hobby: Hobby) // Deletes a hobby to the database.
    
    var currentUserList: UserList? {get set} // current user's list of hobbies
    
    func addUserList(listName: String) -> UserList // Adds a new user list to the database.
    func deleteUserList(list: UserList) // Deletes a user list from the database.
    func addHobbyToUserList(hobby: Hobby, userList: UserList) -> Bool // Adds a hobby to a user's list in the database.
    func removeHobbyFromUserList(hobby: Hobby, userList: UserList) // Removes a hobby from a user's list in the database.
    
    func addGoals(goal: String) // Adds a new goal to the database.
    func deleteGoals(goalId: String) // Deletes a goal from the database.

    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) // Signs in a user with email and password.
    func signUpWithEmail(email: String, password: String, displayName: String, completion: @escaping (Result<User, Error>) -> Void) // Signs up a new user with email, password, and display name.
    
    func fetchGoals(completion: @escaping ([Goal]) -> Void) // Fetches the user's goals from the database.
}

