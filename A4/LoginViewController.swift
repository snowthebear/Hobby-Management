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



class LoginViewController: UIViewController {
    
    var firebaseController = FirebaseController()
    var currentUser: FirebaseAuth.User?
    var currentUserList: UserList?
    
    
    
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
                self.fetchUserDataAndProceed(user: user)

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
      
            self.firebaseController.signInWithGoogle(idToken: idToken, accessToken: accessToken) { [weak self] result in
                guard let self = self else {
                    return }

                switch result {
                case .success(let user):
                    self.currentUser = user
                    UserManager.shared.currentUser = user
                    self.fetchUserDataAndProceed(user: user)
                    UserManager.shared.accessToken = accessToken
                    self.fetchCalendarEvents(accessToken: accessToken)
                    
                    
                    self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                    
                case .failure(let error):
                    print("Error signing in with Google: \(error.localizedDescription)")
                    self.displayMessage(title: "Login Error", message: "Failed to sign in. Please try again.")
                }
            }
            
        }
    }
    
    
    
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
//                            self.performSegue(withIdentifier: "showHomeLogin", sender: self)
                        } else {
                            print("No user list found or error: \(error?.localizedDescription ?? "Unknown error")")
                            self.displayMessage(title: "Error", message: "No user list found.")
                        }
                    }
                } else {
                    print("No user list ID found in user document.")
                    self.displayMessage(title: "Error", message: "No user list found.")
                }
            } else {
                print("User document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                self.displayMessage(title: "Error", message: "Failed to fetch user data.")
            }
        }
        
//        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
//            guard let self = self else { return }
//
//            if let document = document, document.exists {
//                // Use the fetched user data
//                let userData = document.data()
//                UserManager.shared.userData = userData
//                print("user data = \(userData)")
//                
//           
//            } else {
//                print("User document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
//                self.displayMessage(title: "Error", message: "Failed to fetch user data.")
//            }
//        }
    }
    
    
    
    func fetchCalendarEvents(accessToken: String) {
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendarList") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // Securely passing the access token
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching calendar events: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                print("Calendar events: \(jsonResponse)") // Here, handle the parsed data as needed
            } catch {
                print("Error parsing calendar data: \(error.localizedDescription)")
            }
        }
        task.resume()
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
                destination.currentUserList = self.currentUserList
                destination.userEmail = emailTextField.text
                
                
            }
        }
    }
    
//    func addEventoToGoogleCalendar(summary : String, description :String, startTime : String, endTime : String) {
//        let calendarEvent = GTLRCalendar_Event()
//        
//        calendarEvent.summary = "\(summary)"
//        calendarEvent.descriptionProperty = "\(description)"
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
//        let startDate = dateFormatter.date(from: startTime)
//        let endDate = dateFormatter.date(from: endTime)
//        
//        guard let toBuildDateStart = startDate else {
//            print("Error getting start date")
//            return
//        }
//        guard let toBuildDateEnd = endDate else {
//            print("Error getting end date")
//            return
//        }
//        calendarEvent.start = buildDate(date: toBuildDateStart)
//        calendarEvent.end = buildDate(date: toBuildDateEnd)
//        
//        let insertQuery = GTLRCalendarQuery_EventsInsert.query(withObject: calendarEvent, calendarId: "primary")
//        
//        service.executeQuery(insertQuery) { (ticket, object, error) in
//            if error == nil {
//                print("Event inserted")
//            } else {
//                print(error)
//            }
//        }
//    }
    
    // Helper to build date
    func buildDate(date: Date) -> GTLRCalendar_EventDateTime {
        let datetime = GTLRDateTime(date: date)
        let dateObject = GTLRCalendar_EventDateTime()
        dateObject.dateTime = datetime
        return dateObject
    }
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    

}
