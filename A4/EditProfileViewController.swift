//
//  EditProfileViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 08/05/24.
//

import Foundation
import UIKit
import FirebaseAuth
import Firebase
import TOCropViewController

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
    
    var currentUser: FirebaseAuth.User?
    var displayName: String?
    
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var changePicture:Bool = false
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBAction func editProfilePictureButton(_ sender: Any) {
        let alert = UIAlertController(title: "Select an option", message: nil,  preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.pickImageFrom(.camera)
        }))

        alert.addAction(UIAlertAction(title: "Add Photo", style: .default, handler: { _ in
            self.pickImageFrom(.photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { _ in
            self.profilePictureView.image = nil // Remove the image
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        var updates: [String: Any] = [:]
        
        guard let user = self.currentUser else { return }
        
        
        let displayName = nameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        
        let userDocRef = usersReference.document(user.uid)
        
        
        if displayName != user.displayName {
            updates = ["displayName": displayName]
        }
        
        // Update email (This requires re-authentication, simplified here)
        if user.email != email {
            user.updateEmail(to: email) { error in
                if let error = error {
                    print("Failed to update email: \(error.localizedDescription)")
                    self.displayMessage(title: "Error", message: "Failed to update email: \(error.localizedDescription)")
                    return
                }
                updates["email"] = email
                userDocRef.updateData(updates) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    } else {
                        print("Document successfully updated")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } else {
            userDocRef.updateData(updates) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document successfully updated")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        guard let userID = self.currentUser?.uid else {
            displayMessage(title: "Error", message: "No user logged in!")
            return
        }
        
        if self.changePicture == true {
            if let newImage = profilePictureView.image, let imageData = newImage.jpegData(compressionQuality: 0.8) {
                let timestamp = UInt(Date().timeIntervalSince1970)
                let filename = "\(timestamp).jpg"
                
                let imageRef = storageReference.child("\(userID)/\(timestamp)")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpg"
                
                let uploadTask = imageRef.putData(imageData, metadata: metadata)
                
                uploadTask.observe(.success) { snapshot in
                    imageRef.downloadURL { (url, error) in
                        if let downloadURL = url {
                            userDocRef.updateData(["profilePictureURL": downloadURL.absoluteString])
                        }
                    }
                }
                
                uploadTask.observe(.failure) { snapshot in
                    self.displayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
                }
            }
        }
    }
    
    
    @IBAction func changePasswordButtonn(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureProfileImageView()
        self.loadUserData()

    }
    
    func loadUserData() {
        guard let user = currentUser else { return }
        
        // Set email
        emailTextField.text = user.email
        nameTextField.text = user.displayName
        
        // Fetch and set the display name and profile image from Firestore
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        userDocRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                let data = document.data()
                self.nameTextField.text = data?["displayName"] as? String
                
                if let profileImageUrl = data?["profilePictureURL"] as? String {
                    self.loadProfileImage(urlString: profileImageUrl)
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func loadProfileImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_picture"), options: .continueInBackground, completed: nil)
    }

    
    private func configureProfileImageView() {
        // Make the image view circular
        profilePictureView.layer.cornerRadius = profilePictureView.frame.size.width / 2
        profilePictureView.clipsToBounds = true
        
        // Set content mode to ScaleAspectFill
        profilePictureView.contentMode = .scaleAspectFill
        
        profilePictureView.layer.borderWidth = 0.5
        profilePictureView.layer.borderColor = UIColor.black.cgColor
        
        if profilePictureView.image == nil {
            profilePictureView.image = UIImage(named: "default_picture")
        }
}
    
    @objc func handleImageTap() {
        let alert = UIAlertController(title: "Select an option", message: nil,  preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.pickImageFrom(.camera)
        }))

        alert.addAction(UIAlertAction(title: "Add Photo", style: .default, handler: { _ in
            self.pickImageFrom(.photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { _ in
            self.profilePictureView.image = nil // Remove the image
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true)
        if let pickedImage = info[.originalImage] as? UIImage {
            let cropViewController = TOCropViewController(croppingStyle: .circular, image: pickedImage)
            cropViewController.delegate = self
            self.present(cropViewController, animated: true, completion: nil)
        }
        
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
        profilePictureView.image = image
        self.changePicture = true
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    
    
    
   
}
