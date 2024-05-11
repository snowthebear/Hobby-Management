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
    
    override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        authController = Auth.auth()
        database = Firestore.firestore()
      
        super.init()

    }
    
    func cleanup() {
        
    }
    
    func addListener(listener: any DatabaseListener) {
        listeners.addDelegate(listener)

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
    
    enum AuthError: Error {
        case userNotFound
        case userCreationFailed
    }
}
