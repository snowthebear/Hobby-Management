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



class FirebaseController: NSObject, DatabaseProtocol {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var authController: Auth
    var database: Firestore
    
    var currentUser: FirebaseAuth.User?
    var currentUserList: UserList?
    var hobbyList: [Hobby]
    
    var hobbiesRef: CollectionReference?
    var userListRef: DocumentReference? // userTeamRef
    var listsRef: CollectionReference? // teamsRef
    
    override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        authController = Auth.auth()
        database = Firestore.firestore()
        hobbyList = [Hobby]()
        
        super.init()
        
        hobbiesRef = database.collection("hobbies")
        listsRef = database.collection("userlists")
        self.setupHobbyListener()
        self.setupUserListListener()

    }
    
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
    
    func deleteHobby(hobby: Hobby) {
        if let hobbyId = hobby.id { // check if they have a valid ID
            hobbiesRef?.document(hobbyId).delete() // combined with the database references to delete them.
        }
    }
    
    func addUserList(listName: String) -> UserList {
        if let currentList = currentUserList {
            // If there is already a team set for the current user, return it.
            print ("aaaa")
            return currentList
        } else {
            let userList = UserList()
            userList.name = listName
            userList.id = UUID().uuidString
            userListRef?.setData(["name": listName], merge: true)
            currentUserList = userList
            return userList
        }
    }
    
    func deleteUserList(list: UserList) {
        userListRef?.delete()
    }
    
    func addHobbyToUserList(hobby: Hobby, userList: UserList) -> Bool {
        guard let hobbyId = hobby.id, let hobbyID = hobby.id, let hobbiesRef = self.hobbiesRef else {
            print("Invalid hobby or hobby list ID.")
            return false
        }
        
        // Reference to the specific team's document
        let hobbyRef = hobbiesRef.document(hobbyID)
        print ("hobbyRef \(hobbyRef)")
        // Add the hero to the team's "heroes" array
        print("\(hobbyID)")

        hobbyRef.updateData(["heroes": FieldValue.arrayUnion([database.collection("hobbies").document(hobbyID)])]) { error in
            if let error = error {
                print("Error adding hero to team: \(error)")
                return
            }
        }
        
        return true
    }
    
    func removeHobbyToUserList(hobby: Hobby, userList: UserList) {
        guard let hobbyId = hobby.id, let listId = userList.id else {
            print("Invalid hero or team ID.")
            return
        }
        
        // Reference to the specific team's document
        let listRef = listsRef?.document(hobbyId)
    
        
        // Remove the hero from the team's "heroes" array
        listRef?.updateData([
            "heroes": FieldValue.arrayRemove([database.collection("hobbies").document(hobbyId)])
        ]) { error in
            if let error = error {
                print("Error removing hero from team: \(error)")
            }
        }
    }
    
    
    
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
    
    func setupUserListListener(){
            
        listsRef = database.collection("userlists")
        //        teamsRef?.whereField("name", isEqualTo: DEFAULT_TEAM_NAME).addSnapshotListener {
        guard let listId = currentUserList?.id else {
                print("No current user list found")
                return
            }
            
            let listRef = listsRef?.document(listId)
            listRef?.addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let self = self, let snapshot = documentSnapshot else {
                    print("Error listening for team updates: \(error?.localizedDescription ?? "No error")")
                    return
                }
                self.parseUserListSnapshot(snapshot: snapshot)
            }
    }
    
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
    
    func parseUserListSnapshot(snapshot: DocumentSnapshot) {
        guard let teamData = snapshot.data(), snapshot.exists else {
            print("Document does not exist or data could not be retrieved")
            return
        }
            
        let userList = UserList()
        userList.name = teamData["name"] as? String
        userList.id = snapshot.documentID
        print ("\(userList.hobbies)")
        
        if let hobbyReferences = teamData["hobbies"] as? [DocumentReference] {
            print ("\(userList.hobbies)")
            userList.hobbies = hobbyReferences.compactMap { reference in
                // convert DocumentReference to Superhero
                getHobbyByID(reference.documentID)
            }
//                print ("\(team.heroes)")
        }
        
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.list || listener.listenerType == ListenerType.all {
                // call the MulticastDelegate's invoke method to update all listeners.
                listener.onUserListChange(change: .update, userHobbies: userList.hobbies)
            }
        }
        
    }
    
    
    func cleanup() {
        userListRef = nil
        currentUser = nil
        currentUserList = nil
        
    }
    
    func addListener(listener: any DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .hobbies || listener.listenerType == .all {
            listener.onAllHobbyChange(change: .update, hobbies: hobbyList)
        }
        
        // This ensures the listeners get a team of heroes when added to the Multicast Delegate.
        if listener.listenerType == .list || listener.listenerType == .all {
            userListRef?.getDocument { (documentSnapshot, error) in
                if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                    do {
                        let list = try documentSnapshot.data(as: UserList.self)
                        listener.onUserListChange(change: .update, userHobbies: list.hobbies)
                    } catch {
                        print("Error decoding list: \(error)")
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }

    }
    
    func removeListener(listener: any DatabaseListener) {
        listeners.removeDelegate(listener)

    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else {
                completion(.failure(AuthError.userNotFound))
                return
            }
            
            if let user = authResult?.user {
                self?.currentUser = user
                completion(.success(user))
//                return
            }


            else if let error = error {
                completion(.failure(error))
//                return
            }


        }
    }
    
    
//    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
//        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
//               guard let self = self else {
//                   completion(.failure(AuthError.userNotFound))
//                   return
//               }
//
//               if let error = error {
//                   completion(.failure(error))
//                   return
//               }
//
//               guard let user = authResult?.user else {
//                   completion(.failure(AuthError.userCreationFailed))
//                   return
//               }
//            
//               // Store user data in Firestore. Note: Do not store the password.
//            let userData: [String: Any] = ["email": email, "password": password]
////            self.currentUser = user
//            self.database.collection("users").document(user.uid).setData(userData) { error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//            }
//        }
//    }
    
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
            let userData: [String: Any] = [
                "email": email,
                "displayName": displayName,
                "Hobby(s)": [],
                "following": 0,
                "followers": 0,
                "total posts": 0,
            ]
            
            self.database.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.currentUser = user
                    completion(.success(user))
                }
            }
        }
    }
    
    
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
                    // User document exists, no need to create
                    completion(.success(user))
                } else {
                    // User document does not exist, create it
                    let userData: [String: Any] = [
                        "email": user.email ?? "",
                        "displayName": user.displayName ?? "",
                        "Hobby(s)": [],
                        "following": 0,
                        "followers": 0,
                        "total posts": 0,
//                        "profilePictureURL": ""
                    ]
                    
                    userRef.setData(userData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(user))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Firebase Controller Specific m=Methods
    func getHobbyByID(_ id: String) -> Hobby? {
        for hobby in hobbyList {
            if hobby.id == id { // get a specific hero within the heroList based on the provided ID
                return hobby
            }
        }
        return nil
    }
    
    enum AuthError: Error {
        case userNotFound
        case userCreationFailed
    }
}
