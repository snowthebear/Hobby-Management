//
//  RegisterViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

/**
 RegisterViewController handles user registration using Firebase authentication.
 It provides fields for inputting name, email, and password, and includes validation checks for these inputs.
 */
class RegisterViewController: UIViewController {
    
    var firebaseController = FirebaseController() //Firebase controller for handling sign-up operations
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    
    /**
     Configures the view once it is loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.navigationItem.title = "HOBSNAP"
        configurePasswordTextField()
    }
    
    /**
    Configures the navigation bar before the view appears.
    - Parameters:
      - animated: If true, the view is being added to the window using an animation.
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.navigationItem.title = "HOBSNAP"
    }
    
    /**
     Clears any configurations when the view will disappear.
     - Parameters:
       - animated: If true, the disappearance of the view is animated.
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /**
     Handles the registration process when the register button is tapped.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func registerButton(_ sender: Any) {
        // Register the user with Firebase Authentication
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Input Error", message: "All fields are required.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Input Error", message: "Passwords do not match.")
            return
        }

        // Ensure valid email
        guard isValidEmail(email) else {
            showAlert(title: "Input Error", message: "Invalid email format.")
            return
        }

        // Ensure password is at least 6 characters
        guard password.count >= 6 else {
            showAlert(title: "Input Error", message: "Password must be at least 6 characters.")
            return
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        firebaseController.signUpWithEmail(email: email, password: password, displayName: name) { [weak self] result in
            activityIndicator.stopAnimating()
            guard let self = self else { return }

            switch result {
            case .success(let user):
                self.showAlert(title: "Registration Successful", message: "You have registered successfully!") {
                    self.performSegue(withIdentifier: "showLogin", sender: self)
                }
                
            case .failure(let error):
                self.showAlert(title: "Registration Error", message: error.localizedDescription)
            }
        }
    }
    
    /**
     Validates if an email address is in a correct format.
     - Parameters:
       - email: The email string to validate.
     - Returns: Boolean indicating if the email is in a valid format.
     */
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /**
     Displays an alert message with an optional completion handler.
     - Parameters:
       - title: Title of the alert.
       - message: Message body of the alert.
       - completion: Optional closure to execute after dismissing the alert.
     */
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    /**
     Determines if the segue should be performed based on validation checks.
     - Parameters:
       - identifier: The identifier for the segue being considered.
       - sender: The object that initiated the segue.
     - Returns: Boolean indicating whether the segue should occur.
     */
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showLogin" {

            guard let name = nameTextField.text, !name.isEmpty,
                  let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty,
                  let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
                showAlert(title: "Input Error", message: "All fields are required.")
                return false
            }

            if password != confirmPassword {
                showAlert(title: "Input Error", message: "Passwords do not match.")
                return false
            }

            if !isValidEmail(email) {
                showAlert(title: "Input Error", message: "Invalid email format.")
                return false
            }

            if password.count < 6 {
                showAlert(title: "Input Error", message: "Password must be at least 6 characters.")
                return false
            }
            return true
        }
        return true
    }
    
    
    /**
     Toggles the visibility of the password text field.
     - Parameters:
       - sender: The button used to toggle visibility.
     */
    @objc func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    /**
    Toggles the visibility of the confirm password text field.
    - Parameters:
      - sender: The button used to toggle visibility.
    */
    @objc func toggleConfirmPasswordVisibility(_ sender: UIButton) {
        confirmPasswordTextField.isSecureTextEntry.toggle()
        let imageName = confirmPasswordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    /**
    Configures the password and confirmation text fields with a visibility toggle button.
    */
    func configurePasswordTextField() {
        let passwordVisibilityButton = UIButton(type: .system)
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordVisibilityButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        passwordTextField.rightView = passwordVisibilityButton
        passwordTextField.rightViewMode = .always

        // Confirmation password field
        let confirmVisibilityButton = UIButton(type: .system)
        confirmVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        confirmVisibilityButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        confirmVisibilityButton.addTarget(self, action: #selector(toggleConfirmPasswordVisibility(_:)), for: .touchUpInside)
        confirmPasswordTextField.rightView = confirmVisibilityButton
        confirmPasswordTextField.rightViewMode = .always
    }
    
}
