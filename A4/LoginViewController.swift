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



class LoginViewController: UIViewController {
    
    var firebaseController = FirebaseController()
    var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        passwordTextField.isSecureTextEntry = true
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBAction func loginButton(_ sender: Any) {
        
        guard let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty else {
            displayMessage(title: "Input Error", message: "Please enter both email and password.")
            return
        }
        
        
        firebaseController.signInWithEmail(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                // User signed in successfully, now fetch the team
                self.currentUser = user
                UserManager.shared.currentUser = user
                print ("login user = \(user)")
                self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                
            case .failure(let error):
                print("Error signing in: \(error.localizedDescription)")
                self.displayMessage(title: "Login Error", message: "Failed to sign in. Please check your credentials and try again.")
            }
            
            
        }
        
    }
    
    
    @IBAction func signupButton(_ sender: Any) {
    }
    
    
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
            
            // Authenticate with Firebase using the Google credential
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In error: \(error.localizedDescription)")
                    return
                }
                
                
                guard let user = authResult?.user else { return }
                self.currentUser = user
                UserManager.shared.currentUser = user
                print ("user = \(user), current user = \(self.currentUser)")
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "Full Name": user.displayName!,
                    "email": user.email!,
                    "Hobby(s)": [],
                    "following": 0,
                    "followers": 0,
                    "total posts": 0
                    
                    
                ]) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        print("User registered successfully and data saved to Firestore")
                    }
                }

                // Successfully signed in
                self.performSegue(withIdentifier: "showHomeLogin", sender: self)
            }
        }
    }
    

    func setKeepMeSignedInPreference(_ keepSignedIn: Bool) {
        UserDefaults.standard.set(keepSignedIn, forKey: "KeepMeSignedIn")
    }


    func getKeepMeSignedInPreference() -> Bool {
        return UserDefaults.standard.bool(forKey: "KeepMeSignedIn")
    }

    
    func isValidEmail (_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showHomeLogin" {
            guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                displayMessage(title: "Input Error", message: "Please enter both email and password.")
                return false
            }
            
            // Perform login validation asynchronously
            signInAndPerformSegue(email: email, password: password) { success in
                if success {
//                    // If login successful, perform segue
                    DispatchQueue.main.async {
//                        self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                    }
                }
            }

            // Return false as the segue will be performed asynchronously
            return false
        }

        // Allow the segue to proceed for other identifiers
        return true
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showHomeLogin",
           let tabBarController = segue.destination as? UITabBarController {
            // Access the desired tab by index, assuming the target is at index 0
            if let destination = tabBarController.viewControllers?.first(where: { $0 is HomeTableViewController }) as? HomeTableViewController {
                destination.currentUser = currentUser
                destination.userEmail = emailTextField.text
            }
        }
    }
}
