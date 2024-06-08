//
//  LoginViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import UIKit
import FirebaseAuth
import Firebase
import GoogleSignIn
import FirebaseFirestore
import GoogleAPIClientForREST
import GTMSessionFetcher


/**
 LoginViewController  manages the user authentication interface, handling login, sign-up, and Google sign-in operations using Firebase.
 */
class LoginViewController: UIViewController {
    
    var firebaseController = FirebaseController() // Controller for handling Firebase operations.
    var currentUser: FirebaseAuth.User? // The current logged-in Firebase user.
    var currentUserList: UserList? // user list of hobbies
    
    
    /**
     Sets up the view controller's navigation item and title before the view appears.
     */
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationItem.hidesBackButton = true
        super.viewWillAppear(animated)
        self.title = "HOBSNAP"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /**
     Configures the initial view settings, particularly the navigation and security settings of the text fields.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationItem.hidesBackButton = true
        self.title = "HOBSNAP"
        
        passwordTextField.isSecureTextEntry = true
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    /**
     Handles user login with email and password.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func loginButton(_ sender: Any) {
        // Ensures non-empty credentials are provided before attempting login.
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty else {
            DisplayMessage(title: "Input Error", message: "Please enter both email and password.")
            return
        }
        
        // Attempts to sign in with email and password using Firebase.
        firebaseController.signInWithEmail(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                // User signed in successfully, now fetch the team
                self.currentUser = user
                UserManager.shared.currentUser = user
                self.fetchUserDataAndProceed(user: user)

                self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                
            case .failure(let error):
                print("Error signing in: \(error.localizedDescription)")
                self.DisplayMessage(title: "Login Error", message: "Failed to sign in. Please check your credentials and try again.")
            }
        }
    }
    
    
    @IBAction func signupButton(_ sender: Any) {
    }
    
    /**
     Initiates Google sign-in process.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func googleSignInButton(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }
        
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        _ = !getKeepMeSignedInPreference()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                return
            }

            // Safely unwrap both idToken and accessToken using optional binding
            guard let idToken = signInResult?.user.idToken?.tokenString,
                  let accessToken = signInResult?.user.accessToken.tokenString else {
                print("Google Sign-In error: Missing tokens")
                return
            }
      
            
            // Create the credential with unwrapped tokens
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
      
            self.firebaseController.signInWithGoogle(idToken: idToken, accessToken: accessToken) { [weak self] result in
                guard let self = self else {
                    return }

                switch result {
                case .success(let user):
                    self.currentUser = user
                    UserManager.shared.currentUser = user
                    self.fetchUserDataAndProceed(user: user)
                    UserManager.shared.accessToken = accessToken
                 
                    self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                    
                case .failure(let error):
                    print("Error signing in with Google: \(error.localizedDescription)")
                    self.DisplayMessage(title: "Login Error", message: "Failed to sign in. Please try again.")
                }
            }
            
        }
    }
    
    
    /**
     Fetches user-specific data from Firestore and proceeds with user session setup.
     - Parameters:
       - user: The Firebase user for whom data is to be fetched.
     */
    func fetchUserDataAndProceed(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let document = document, document.exists {
                let userData = document.data()
                UserManager.shared.userData = userData
                print("User data = \(userData ?? [:])")
                
                if let userListId = userData?["userListId"] as? String {
                    self.firebaseController.userListRef?.document(userListId).getDocument { document, error in
                        if let document = document, document.exists {
                            self.firebaseController.parseUserListSnapshot(snapshot: document)
                            UserManager.shared.currentUserList = self.firebaseController.currentUserList
                        } else {
                            print("No user list found or error: \(error?.localizedDescription ?? "Unknown error")")
                            self.DisplayMessage(title: "Error", message: "No user list found.")
                        }
                    }
                } else {
                    print("No user list ID found in user document.")
                    self.DisplayMessage(title: "Error", message: "No user list found.")
                }
            } else {
                print("User document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                self.DisplayMessage(title: "Error", message: "Failed to fetch user data.")
            }
        }
    }

    /**
     Returns the user's preference for staying signed in.
     - Returns: Boolean indicating if the user prefers to stay signed in.
     */
    func getKeepMeSignedInPreference() -> Bool {
        return UserDefaults.standard.bool(forKey: "KeepMeSignedIn")
    }

    /**
    Validates the email format.
    - Parameters:
      - email: The email string to validate.
    - Returns: Boolean indicating if the email is in a valid format.
    */
    func isValidEmail (_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /**
     Checks the existence of an email in the Firestore database.
     - Parameters:
       - email: The email to check.
       - completion: A closure to call with the result (true if the email exists, false otherwise).
     */
    func checkEmailExistence(email: String, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking email existence:", error)
                completion(false)
                return
            }
            // Check if any documents were returned (indicating the email exists)
            if let snapshot = snapshot, !snapshot.isEmpty {
                // If snapshot is not nil and it's not empty, it means documents exist
                completion(true)
            } else {
                // No documents were returned, indicating the email does not exist
                completion(false)
            }
        }
    }
    
    /**
     Determines whether the segue with the specified identifier should be performed.
     
     - Parameters:
       - identifier: The identifier for the segue being considered.
       - sender: The object that initiated the segue.
     - Returns: Boolean indicating whether the segue should occur.
     */
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showHomeLogin" {
            guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                DisplayMessage(title: "Input Error", message: "Please enter both email and password.")
                return false
            }
            // Perform login validation asynchronously
            signInAndPerformSegue(email: email, password: password) { success in
                if success {
                    // If login successful, perform segue
                    DispatchQueue.main.async {
                    }
                }
            }
            // Return false as the segue will be performed asynchronously
            return false
        }
        // Allow the segue to proceed for other identifiers
        return true
    }
    
    /**
     Initiates a sign-in process with the provided email and password, and executes a completion handler based on the outcome.

     - Parameters:
       - email: The user's email address.
       - password: The user's password.
       - completion: A closure that gets called with the result (true if sign-in is successful, otherwise false).
     */
    func signInAndPerformSegue(email: String, password: String, completion: @escaping (Bool) -> Void) {
        checkEmailExistence(email: email) { exists in
            print("Checking existence of email: \(email)")
            if exists {
                self.firebaseController.signInWithEmail(email: email, password: password) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            completion(true)
                        case .failure(_):
                            completion(false)
                        }
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    /**
     Prepares for a segue to the HomeTableViewController, configuring it with current user details.

     - Parameters:
       - segue: The segue object containing information about the view controllers involved in the segue.
       - sender: The object that initiated the segue.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHomeLogin",
           let tabBarController = segue.destination as? UITabBarController {
            // Access the desired tab by index, assuming the target is at index 0
            if let destination = tabBarController.viewControllers?.first(where: { $0 is HomeTableViewController }) as? HomeTableViewController {
                destination.currentUser = currentUser
                destination.currentUserList = self.currentUserList
                destination.userEmail = emailTextField.text
                
                
            }
        }
    }
}
