//
//  FirebaseController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseAuth


/**
FirebaseController manages interactions with Firebase Firestore and Firebase Authentication to handle user data and actions such as adding, updating, and deleting goals, hobbies, and user lists.

It implements the DatabaseProtocol interface to provide structured ways to interact with database operations.
*/
class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>() // Holds multiple listeners for database changes.
    var authController: Auth // Firebase Authentication controller
    var database: Firestore // Firestore database instance.
    
    var currentUser: FirebaseAuth.User? // authenticated Firebase user.
    var currentUserList: UserList? // user hobbies list
    var hobbyList: [Hobby] // hobby list
    
    var hobbiesRef: CollectionReference? // Reference to the hobbies collection in Firestore.
    var userListRef: CollectionReference? // Reference to the user lists collection in Firestore.

    
    /**
     Initializes the FirebaseController, sets up Firebase, and configures listeners for hobbies and user lists.
    */
    override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        authController = Auth.auth()
        database = Firestore.firestore()
        hobbyList = [Hobby]()
        
        super.init()

        hobbiesRef = database.collection("hobbies")
        userListRef = database.collection("userlists")
        self.setupHobbyListener()
        self.setupUserListListener()

    }

    /**
     Adds a goal to the current user's document in Firestore.
     
     - Parameter goal: The title of the goal to be added.
    */
    func addGoals(goal: String) {
        // Check if a user is logged in before attempting to add a goal.
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        // Create a new goal dictionary
        let newGoal: [String: Any] = [
            "title": goal,
            "completed": false
        ]

        // Update the user's document by appending the new goal to the goals array
        let userRef = database.collection("users").document(userID)  // Reference to the current user's document in the Firestore 'users' collection.
        userRef.updateData([
            "goals": FieldValue.arrayUnion([newGoal])
        ]) { error in
            if let error = error {
                print("Error adding goal to user document: \(error)")
            } else {
                print("Goal successfully added to user document")
            }
        }
    }
    
    /**
         Deletes a specified goal from the current user's document in Firestore.
         
         - Parameter goalId: The identifier of the goal to be removed.
        */
    func deleteGoals(goalId: String) {
        // Ensure there is a logged-in user before attempting to delete a goal.
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        let userDocRef = database.collection("users").document(userID) // Reference to the current user's document.
        
        // Retrieve the current document to access its goals.
        userDocRef.getDocument { (document, error) in
            if let document = document, let data = document.data(), let goals = data["goals"] as? [[String: Any]] {
                // Identify the goal to delete by its title.
                if let goalToDelete = goals.first(where: { $0["title"] as? String == goalId }) {
                    // try to remove the goal from the Firestore document.
                    userDocRef.updateData([
                        "goals": FieldValue.arrayRemove([goalToDelete])
                    ]) { error in
                        if let error = error {
                            print("Error removing goal: \(error)")
                        } else {
                            print("Goal successfully removed")
                        }
                    }
                }
            }
        }
    }
    
    /**
     Adds a new hobby to the Firestore database.

     - Parameters:
        - name: The name of the hobby to be added.
        - interest: The interest type associated with the hobby.

     - Returns: The newly created Hobby object with its name and interest set.
    */
    func addHobby(name: String, interest: Interest) -> Hobby {
        let hobby = Hobby() //create an object first then set the name, abilities, and universe.
        hobby.name = name
        hobby.interest = interest.rawValue
        
        
        // must be done in do/catch statement because it uses the codable protocol to serialize the data.
        // attempt to add it to Firestore
        do {
            if let hobbyRef = try hobbiesRef?.addDocument(from: hobby) { // heroRef holds a reference to the Heroes collection in Firestore.
                hobby.id = hobbyRef.documentID
            }
        }
        catch {
            print("Failed to serialize hero")
        }
        
        return hobby
    }
    
    /**
     Deletes a hobby from the Firestore database.

     - Parameter hobby: The hobby object to be deleted.
    */
    func deleteHobby(hobby: Hobby) {
        if let hobbyId = hobby.id { // check if they have a valid ID
            hobbiesRef?.document(hobbyId).delete() // combined with the database references to delete them.
        }
    }
    
    /**
     Adds a new user list to the Firestore database.

     - Parameter listName: The name of the list to be added.

     - Returns: The newly created UserList object.
    */
    func addUserList(listName: String) -> UserList {
        let userList = UserList()
        userList.name = listName
        userList.id = UUID().uuidString

        do {
            try userListRef?.document(userList.id!).setData(from: userList)
            currentUserList = userList
        } catch {
           print("Failed to serialize user list")
        }

        return userList
    }
    
    /**
     Deletes a user list from the Firestore database.

     - Parameter list: The UserList object to be deleted.
    */
    func deleteUserList(list: UserList) {
        if let listId = list.id {
            userListRef?.document(listId).delete()
        }
    }
    
    /**
     Adds a hobby to a specific user list in Firestore.

     - Parameters:
        - hobby: The hobby to be added to the list.
        - userList: The user list to which the hobby will be added.

     - Returns: Boolean indicating if the operation was successful.
    */
    func addHobbyToUserList(hobby: Hobby, userList: UserList) -> Bool {
        // Validate necessary IDs and references.
        guard let hobbyId = hobby.id, let hobbiesRef = self.hobbiesRef else {
            print("Invalid hobby or hobby list ID.")
            return false
        }
        
        guard let userListId = userList.id else {
            print("No current user.")
            return false
        }
        
        let userHobbyRef = userListRef?.document(userListId) // Reference to the specific user list document.
        let hobbyRef = hobbiesRef.document(hobbyId)
        
        // // Attempt to add the hobby ID to the user list's hobbies array.
        userHobbyRef?.updateData([
            "hobbies": FieldValue.arrayUnion([hobbyId])
        ]) { error in
            if let error = error {
                print("Error adding hobby to user list: \(error)")
                return
            }
            print("Hobby added successfully to user list.")
        }
        
        return true
    }
    
    /**
     Removes a hobby from a specific user list in Firestore.

     - Parameters:
        - hobby: The hobby to be removed from the list.
        - userList: The user list from which the hobby will be removed.
    */
    func removeHobbyFromUserList(hobby: Hobby, userList: UserList) {
        // Ensure both hobby and user list IDs are valid.
        guard let hobbyId = hobby.id, let userListId = userList.id else {
            print("Invalid hobby ID or user list ID.")
            return
        }
        let userHobbyRef = database.collection("userlists").document(userListId)  // Reference to the specific user list document.

        // Using Firestore arrayRemove to remove the hobby
        userHobbyRef.updateData([
            "hobbies": FieldValue.arrayRemove([hobbyId])
        ]) { error in
            if let error = error {
                print("Error removing hobby from user list: \(error)")
            } else {
                print("Hobby removed successfully from user list.")
                
            }
        }
    }
    
    /**
     Sets up a listener for changes to the hobbies collection in Firestore. This method initializes the listener and updates the local hobby list based on changes in the database.

     The listener will update the local hobby list whenever a document in the "hobbies" collection is added, modified, or removed.
    */
    func setupHobbyListener(){
        hobbiesRef = database.collection("hobbies") // get a Firestore reference to the SUperheroes collection
        
        hobbiesRef?.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self, let snapshot = querySnapshot else {
                print("Error listening for hero updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            self.parseHobbiesSnapshot(snapshot: snapshot)
        }
    }
    
    /**
     Sets up a listener for changes to a specific user list document in Firestore based on the currentUserList ID.

     This method is responsible for attaching a snapshot listener to the user's current list document, enabling real-time updates within the app when changes occur in Firestore.
    */
    func setupUserListListener(){
        guard let listId = currentUserList?.id else {
            print("No current user list found")
            return
        }
        
        let listRef = userListRef?.document(listId)
        listRef?.addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self, let snapshot = documentSnapshot else {
                print("Error listening for team updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            self.parseUserListSnapshot(snapshot: snapshot)
        }
    }
    
    /**
     Parses a snapshot of Firestore document changes for hobbies, updating the local cache of hobbies and notifying all registered listeners of the changes.

     - Parameter snapshot: The snapshot containing changes to hobby documents.
    */
    func parseHobbiesSnapshot(snapshot: QuerySnapshot) {
        // parse the snapshot and make any changes as required to our local properties and call local listeners.
        
        snapshot.documentChanges.forEach { (change) in
            var hobby: Hobby
            
            do {
                hobby = try change.document.data(as: Hobby.self) // decode the document's data as a Superhero object.
            }
            catch {
                fatalError("Unable to decode hero: \(error.localizedDescription)")
            }
            
            if change.type == .added { // insert it into the array at the appropriate place.
                hobbyList.insert(hobby, at: Int(change.newIndex))
            }
            
            else if change.type == .modified {
                // we remove and readd the newly modified hero at the new location.
                hobbyList.remove(at: Int(change.oldIndex))
                hobbyList.insert(hobby, at: Int(change.newIndex))
            }
            
            else if change.type == .removed {
                hobbyList.remove(at: Int(change.oldIndex)) // delete the element at the given location.
            }
            
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.hobbies || listener.listenerType == ListenerType.all {
                    // use the multicast delegate's invoke method to call onAllHeroesChange on each listener.
                    listener.onAllHobbyChange(change: .update, hobbies: hobbyList)
                }
            }
        }
    }
    
    /**
     Parses the snapshot of a specific user list document, updating the local user list model and notifying all registered listeners of the changes.

     - Parameter snapshot: The document snapshot of the user list containing its current state and data.
    */
    func parseUserListSnapshot(snapshot: DocumentSnapshot) {
        guard let userListData = snapshot.data(), snapshot.exists else {
            print("Document does not exist or data could not be retrieved")
            return
        }
            
        let userList = UserList()
        userList.name = userListData["name"] as? String
        userList.id = snapshot.documentID
        print ("\(userList.hobbies)")
        
        userList.hobbies = []

        if let hobbyReferences = userListData["hobbies"] as? [String] {
            for hobbyId in hobbyReferences {
                if let hobby = getHobbyByID(hobbyId) {
                    userList.hobbies.append(hobby)
                } else {
                    // Fetch hobby from Firestore if not found in local cache
                    hobbiesRef?.document(hobbyId).getDocument { documentSnapshot, error in
                        if let error = error {
                            print("Error fetching hobby: \(error)")
                        } else if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                            do {
                                let hobby = try documentSnapshot.data(as: Hobby.self)
                                userList.hobbies.append(hobby)
                                // Update the local cache
                                self.hobbyList.append(hobby)
                            } catch {
                                print("Error decoding hobby: \(error)")
                            }
                        }
                        // Notify listeners after fetching all hobbies
                        self.listeners.invoke { listener in
                            if listener.listenerType == .list || listener.listenerType == .all {
                                listener.onUserListChange(change: .update, userHobbies: userList.hobbies)
                            }
                        }
                    }
                }
            }
        }
     
        currentUserList = userList
        UserManager.shared.currentUserList = userList
        
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.list || listener.listenerType == ListenerType.all {
                // call the MulticastDelegate's invoke method to update all listeners.
                listener.onUserListChange(change: .update, userHobbies: userList.hobbies)
            }
        }
    }
    
    /**
     Cleans up the current user and user list references when a user logs out or their session is terminated.
    */
    func cleanup() {
        currentUser = nil
        currentUserList = nil
        
    }
    
    /**
     Adds a listener to the list of active listeners and immediately updates it with the latest data.

     - Parameter listener: The listener object that conforms to the DatabaseListener protocol.
    */
    func addListener(listener: any DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .hobbies || listener.listenerType == .all {
            listener.onAllHobbyChange(change: .update, hobbies: hobbyList)
        }
        
        // This ensures the listeners get a team of heroes when added to the Multicast Delegate.
        if listener.listenerType == .list || listener.listenerType == .all {
            setupUserListListener()
        }

    }
    
    /**
     Removes a listener from the list of active listeners.

     - Parameter listener: The listener object that needs to be removed.
    */
    func removeListener(listener: any DatabaseListener) {
        listeners.removeDelegate(listener)

    }
    
    /**
     Signs in a user using their email and password, handling authentication and setup of user-specific data.

     - Parameter email: The user's email address.
     - Parameter password: The user's password.
     - Parameter completion: A completion handler that returns either the authenticated user or an error.
    */
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else {
                completion(.failure(AuthError.userNotFound))
                return
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(AuthError.userNotFound))
                return
            }

            self.currentUser = user
            UserManager.shared.currentUser = user // set the user to the user manager's current user
            
            let userRef = self.database.collection("users").document(user.uid)
            
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    // User document exists, check if user list exists
                    if let userData = document.data(), let userListId = userData["userListId"] as? String {
                        self.userListRef?.document(userListId).getDocument { doc, err in
                            if let doc = doc, doc.exists {
                                // User list exists
                                self.parseUserListSnapshot(snapshot: doc)
                                UserManager.shared.currentUserList = self.currentUserList
                                completion(.success(user))
                            } else {
                                // User list does not exist, create it
                                let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List") // set the list name
                                userRef.updateData(["userListId": userList.id!]) { error in
                                    if let error = error {
                                        completion(.failure(error))
                                    } else {
                                        UserManager.shared.currentUserList = userList
                                        completion(.success(user))
                                    }
                                }
                            }
                        }
                    } else {
                        // User document does not contain userListId, create user list
                        let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List")
                        userRef.updateData(["userListId": userList.id!]) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                UserManager.shared.currentUserList = userList // set the user list to the user manager's currentUserList
                                completion(.success(user))
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     Signs up a new user with email and password, creates a new user list for them, and saves their information to Firestore.

     - Parameter email: The user's email address.
     - Parameter password: The user's password.
     - Parameter displayName: The display name of the user.
     - Parameter completion: A completion handler that returns either the authenticated user or an error.
    */
    func signUpWithEmail(email: String, password: String, displayName:String, completion: @escaping (Result<User, Error>) -> Void) {
        authController.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else {
                completion(.failure(AuthError.userNotFound))
                return
            }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(AuthError.userCreationFailed))
                return
            }

            // Create user data in Firestore
            let userList = self.addUserList(listName: "My List")
            let userData: [String: Any] = [
                "email": email,
                "displayName": displayName,
                "userListId": userList.id!,
                "following": 0,
                "followers": 0,
                "total posts": 0,
            ]
            
            self.database.collection("users").document(user.uid).setData(userData) { error in // add the user data to the document id
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.currentUser = user
                    self.currentUserList = userList
                    UserManager.shared.currentUser = user
                    UserManager.shared.currentUserList = userList
                    
                    self.setupUserListListener()
                    completion(.success(user))
                }
            }
        }
    }
    
    /**
     Signs in a user via Google OAuth2, handling authentication and setup of user-specific data.

     - Parameter idToken: The ID token obtained from Google Sign-In.
     - Parameter accessToken: The access token obtained from Google Sign-In.
     - Parameter completion: A completion handler that returns either the authenticated user or an error.
    */
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        authController.signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else {
                completion(.failure(AuthError.userNotFound))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(AuthError.userNotFound))
                return
            }
            
            self.currentUser = user
            let userRef = self.database.collection("users").document(user.uid)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    // User document exists, check if user list exists
                    if let userData = document.data(), let userListId = userData["userListId"] as? String {
                        self.userListRef?.document(userListId).getDocument { doc, err in
                            if let doc = doc, doc.exists {
                                // User list exists
                                self.parseUserListSnapshot(snapshot: doc)
                                UserManager.shared.currentUserList = self.currentUserList
                                completion(.success(user))
                            } else {
                                // User list does not exist, create it
                                let userList = self.addUserList(listName: "My List")
                                userRef.updateData(["userListId": userList.id!]) { error in
                                    if let error = error {
                                        completion(.failure(error))
                                    } else {
                                        UserManager.shared.currentUserList = userList
                                        completion(.success(user))
                                    }
                                }
                            }
                        }
                    } else {
                        // User document does not contain userListId, create user list
                        let userList = self.addUserList(listName: "My List")
                        userRef.updateData(["userListId": userList.id!]) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                UserManager.shared.currentUserList = userList
                                completion(.success(user))
                            }
                        }
                    }
                }
                    else {
                    // User document does not exist, create it and the user list
                    let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List")
                    let userData: [String: Any] = [
                        "email": user.email ?? "",
                        "displayName": user.displayName ?? "",
                        "userListId": userList.id!,
                        "following": 0,
                        "followers": 0,
                        "total posts": 0,
                    ]
                    
                    userRef.setData(userData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            UserManager.shared.currentUserList = userList
                            completion(.success(user))
                        }
                    }
                }
            }
        }
    }
    
    /**
     Checks and creates a user list for the given user if it does not exist, ensuring the user has a default user list.

     - Parameter user: The authenticated user whose user list needs to be verified or created.
     - Parameter completion: A completion handler that confirms the creation or existence of the user list.
    */
    func checkAndCreateUserList(for user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        userListRef?.whereField("userId", isEqualTo: user.uid).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                // No user list found, create a new one
                let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List") // set the user list's name
                self.database.collection("users").document(user.uid).updateData(["userListId": userList.id!]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.currentUserList = userList
                        UserManager.shared.currentUserList = userList
                        completion(.success(()))
                    }
                }
            } else {
                // User list exists
                if let document = querySnapshot?.documents.first {
                    self.parseUserListSnapshot(snapshot: document)
                    UserManager.shared.currentUserList = self.currentUserList
                    completion(.success(()))
                }
                
            }
        }
    }
    
    /**
     Fetches calendar events for the primary calendar of the authenticated user from Google Calendar API.

     - Parameter accessToken: The OAuth2 access token that authorizes the request to Google Calendar API.
     - Parameter completion: A completion handler that returns a list of calendar events or an error if the fetch fails.
    */
    func fetchCalendarEvents(accessToken: String, completion: @escaping (Result<[GTLRCalendar_Event], Error>) -> Void) {
        // Construct the URL for the Google Calendar API endpoint.
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        // Set the authorization header.
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create and start the network task.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors, return failure if any.
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "CalendarError", code: -1, userInfo: nil)))
                return
            }
            
            do {
                // Decode the response data into the EventsResponse model.
                let decoder = JSONDecoder() //
                // Assuming you have a struct that conforms to Codable to parse events
                let eventsResponse = try decoder.decode(EventsResponse.self, from: data)
                completion(.success(eventsResponse.items))
            } catch {
                // Handle decoding errors.
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /**
     Fetches the goals for the currently authenticated user from Firestore.

     - Parameter completion: A completion handler that passes an array of goals or an empty array if the fetch fails.
    */
    func fetchGoals(completion: @escaping ([Goal]) -> Void) {
        // Ensure the current user ID is available.
        guard let userID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        // Reference to the user's document in Firestore.
        let userDocRef = database.collection("users").document(userID)
        userDocRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion([])
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                completion([])
                return
            }
            
            guard let goalsData = document.data()?["goals"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            // Map the dictionary data to Goal objects.
            let goals = goalsData.compactMap { dict -> Goal? in
                guard let title = dict["title"] as? String,
                      let completedValue = dict["completed"] as? Int else {
                    return nil
                }
                return Goal(title: title, isCompleted: completedValue != 0)
            }
            print("Fetched goals successfully:", goals)
            completion(goals)
        }
    }
    
    
    // MARK: - Firebase Controller Specific Methods
    
    /**
     Retrieves a hobby by its ID from the local hobby list.

     - Parameter id: The unique identifier for the hobby.
     - Returns: An optional Hobby object if found; otherwise, nil.
    */
    func getHobbyByID(_ id: String) -> Hobby? {
        for hobby in hobbyList {
            if hobby.id == id { // get a specific hero within the heroList based on the provided ID
                return hobby
            }
        }
        return nil
    }
    
    /**
     Defines errors related to user authentication processes in Firebase.

     - userNotFound: Indicates that the user was not found during an authentication attempt.
     - userCreationFailed: Indicates a failure in creating a new user account.
    */
    enum AuthError: Error {
        case userNotFound
        case userCreationFailed
    }
}





