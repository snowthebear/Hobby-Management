//
//  RegisterViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 02/05/24.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore


class RegisterViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePasswordTextField()
        passwordTextField.textContentType = .none
        confirmPasswordTextField.textContentType = .none
        
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        passwordTextField.autocapitalizationType = .none
        confirmPasswordTextField.autocorrectionType = .no
        confirmPasswordTextField.spellCheckingType = .no
        confirmPasswordTextField.autocapitalizationType = .none
        
    }
    
    @IBAction func registerButton(_ sender: Any) {

        // Register the user with Firebase Authentication
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        // Register the user with Firebase Authentication
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { authResult, error in
            activityIndicator.stopAnimating()
            if let error = error {
                self.showAlert(title: "Registration Error", message: error.localizedDescription)
                return
            }

            guard let user = authResult?.user else {
                self.showAlert(title: "Registration Error", message: "User registration failed.")
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "Full Name": self.nameTextField.text ?? "",
                "email": self.emailTextField.text ?? "",
                "Hobby(s)": []
            ]) { error in
                if let error = error {
                    self.showAlert(title: "Database Error", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "Registration Successful", message: "You have registered successfully!"){
                        self.performSegue(withIdentifier: "showLogin", sender: self)
                            
                    }
                }
            }
            
        }
        
            
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showLogin" {
            // Perform validation to check if segue should be performed
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
    
    
    
    @objc func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc func toggleConfirmPasswordVisibility(_ sender: UIButton) {
        confirmPasswordTextField.isSecureTextEntry.toggle()
        let imageName = confirmPasswordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    func configurePasswordTextField() {
        let passwordVisibilityButton = UIButton(type: .system)
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordVisibilityButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        passwordTextField.rightView = passwordVisibilityButton
        passwordTextField.rightViewMode = .always
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .none

        // Confirmation password field
        let confirmVisibilityButton = UIButton(type: .system)
        confirmVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        confirmVisibilityButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        confirmVisibilityButton.addTarget(self, action: #selector(toggleConfirmPasswordVisibility(_:)), for: .touchUpInside)
        confirmPasswordTextField.rightView = confirmVisibilityButton
        confirmPasswordTextField.rightViewMode = .always
        confirmPasswordTextField.isSecureTextEntry = true
        
        confirmPasswordTextField.textContentType = .none
        
    }

    
}
