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
//    var userListRef: DocumentReference? // userTeamRef
    var userListRef: CollectionReference? // teamsRef
//    var goalsRef: CollectionReference?
    
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
    
    func addGoals(goal: String) {
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
        let userRef = database.collection("users").document(userID)
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
    
    func deleteGoals(goalId: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        
        let userDocRef = database.collection("users").document(userID)
        
        userDocRef.getDocument { (document, error) in
            if let document = document, let data = document.data(), let goals = data["goals"] as? [[String: Any]] {
                if let goalToDelete = goals.first(where: { $0["title"] as? String == goalId }) {
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
    
    
    func deleteUserList(list: UserList) {
//        userListRef?.delete()
        
        if let listId = list.id {
            userListRef?.document(listId).delete()
        }
    }
    
    func addHobbyToUserList(hobby: Hobby, userList: UserList) -> Bool {
        guard let hobbyId = hobby.id, let hobbiesRef = self.hobbiesRef else {
            print("Invalid hobby or hobby list ID.")
            return false
        }
        
        guard let userListId = userList.id else {
            print("No current user.")
            return false
        }
        
        let userHobbyRef = userListRef?.document(userListId)
        
        let hobbyRef = hobbiesRef.document(hobbyId)

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
    
    func removeHobbyFromUserList(hobby: Hobby, userList: UserList) {
        guard let hobbyId = hobby.id, let userListId = userList.id else {
            print("Invalid hobby ID or user list ID.")
            return
        }
        let userHobbyRef = database.collection("userlists").document(userListId)

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
    
    
    func cleanup() {
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
            setupUserListListener()
        }

    }
    
    func removeListener(listener: any DatabaseListener) {
        listeners.removeDelegate(listener)

    }
    
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
            UserManager.shared.currentUser = user
            
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
                                let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List")
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
                                UserManager.shared.currentUserList = userList
                                completion(.success(user))
                            }
                        }
                    }
                }
            }
        }
    }

    
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
            
            self.database.collection("users").document(user.uid).setData(userData) { error in
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
    
    
    func checkAndCreateUserList(for user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        userListRef?.whereField("userId", isEqualTo: user.uid).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let querySnapshot = querySnapshot, querySnapshot.isEmpty {
                // No user list found, create a new one
                let userList = self.addUserList(listName: "\(user.displayName ?? "User")'s List")
//                self.userListRef?.document(userList.id!).setData(["userId": user.uid, "name": userList.name!])
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
    
    
    func fetchCalendarEvents(accessToken: String, completion: @escaping (Result<[GTLRCalendar_Event], Error>) -> Void) {
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "CalendarError", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Assuming you have a struct that conforms to Codable to parse events
                let eventsResponse = try decoder.decode(EventsResponse.self, from: data)
                completion(.success(eventsResponse.items))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
    func fetchGoals(completion: @escaping ([Goal]) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
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
    
    
    
    
//    func fetchPosts(completion: @escaping ([HomeFeedRenderViewModel]?) -> Void) {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("Error: User not logged in")
//            completion(nil)
//            return
//        }
//        
//        let postsRef = Firestore.firestore().collection("posts").whereField("userID", isEqualTo: userID)
//        postsRef.getDocuments { (snapshot, error) in
//            if let error = error {
//                print("Error getting documents: \(error)")
//                completion(nil)
//                return
//            }
//
//            guard let documents = snapshot?.documents, !documents.isEmpty else {
//                print("No documents found")
//                completion(nil)
//                return
//            }
//
//            let models = documents.compactMap { docSnapshot -> HomeFeedRenderViewModel? in
//                guard let post = UserPost(dictionary: docSnapshot.data()) else { return nil }
//                // Create your view models here
//                return HomeFeedRenderViewModel(
//                    header: RenderViewModel(renderType: .header(provider: self.currentUser!)),
//                    post: RenderViewModel(renderType: .postContent(provider: post)),
//                    actions: RenderViewModel(renderType: .actions(provider: "Actions for this post")),
//                    comments: RenderViewModel(renderType: .comments(provider: post.comments ?? []))
//                )
//            }
//            completion(models)
//        }
//    }

    
    
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
    
//    struct EventsResponse: Codable {
//        let items: [Event]
//    }
//
//    struct Event: Codable {
//        let id: String
//        let summary: String
//        let description: String?
//        let start: EventDateTime
//        let end: EventDateTime
//    }
//
//    struct EventDateTime: Codable {
//        let dateTime: String
//        let timeZone: String?
//    }
}





