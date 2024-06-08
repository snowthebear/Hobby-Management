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


/**
 EditProfileViewController manages the editing of user profiles, allowing users to change their display name, email, and profile picture using Firebase for authentication and Firestore for storing user data.
 */
class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
    
    var currentUser: FirebaseAuth.User?
    var displayName: String?
    
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var changePicture:Bool = false
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    /**
     Called after the controller's view is loaded into memory.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureProfileImageView()
        self.loadUserData()

    }
    
    /**
     Handles the action to edit the profile picture.
     - Parameters:
       - sender: The button that triggers this action.
     */
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
    
    /**
     Handles the action to save the updated profile information.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func saveButton(_ sender: Any) {
        var updates: [String: Any] = [:] // to store updates
        
        guard let user = self.currentUser else { return } // Ensure there is a current user logged in
        
        // Retrieve the display name and email from the text fields
        let displayName = nameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        
        let userDocRef = usersReference.document(user.uid) // Reference to the user's document in Firestore
        
        if displayName != user.displayName { // Check if the display name has changed
            updates = ["displayName": displayName]
        }
        
        // Update email (This requires re-authentication, simplified here)
        if user.email != email {
            user.updateEmail(to: email) { error in
                if let error = error {
                    // Display error message if email update fails
                    print("Failed to update email: \(error.localizedDescription)")
                    self.DisplayMessage(title: "Error", message: "Failed to update email: \(error.localizedDescription)")
                    return
                }
                
                // If email update succeeds, update Firestore document
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
            // If email hasn't changed, only update display name in Firestore
            userDocRef.updateData(updates) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document successfully updated")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        guard let userID = self.currentUser?.uid else { // Ensure there is a user ID available
            DisplayMessage(title: "Error", message: "No user logged in!")
            return
        }
        
        // Check if the profile picture has been changed
        if self.changePicture == true {
            // Ensure there is a new image to upload
            if let newImage = profilePictureView.image, let imageData = newImage.jpegData(compressionQuality: 0.8) {
                let timestamp = UInt(Date().timeIntervalSince1970)
                let filename = "\(timestamp).jpg"
                
                // Reference to the image storage location in Firebase Storage
                let imageRef = storageReference.child("\(userID)/\(timestamp)")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpg"
                
                let uploadTask = imageRef.putData(imageData, metadata: metadata)  // Upload the image to Firebase Storage
                
                // Observe the success of the upload task
                uploadTask.observe(.success) { snapshot in
                    // Retrieve the download URL of the uploaded image
                    imageRef.downloadURL { (url, error) in
                        if let downloadURL = url {
                            userDocRef.updateData(["storageURL": downloadURL.absoluteString]) // Update the user's document in Firestore with the image URL
                        }
                    }
                }
                // Observe the failure of the upload task
                uploadTask.observe(.failure) { snapshot in
                    // Display an error message if the upload fails
                    self.DisplayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
                }
            }
        }
    }
    
    
    @IBAction func changePasswordButtonn(_ sender: Any) {
    }
    
    /**
     Loads the user's data from Firestore and populates the UI elements.
     */
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
                
                if let profileImageUrl = data?["storageURL"] as? String {
                    self.loadProfileImage(urlString: profileImageUrl)
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    /**
     Loads the profile image from a given URL string.
     - Parameters:
       - urlString: The URL string of the profile image.
     */
    func loadProfileImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_picture"), options: .continueInBackground, completed: nil)
    }

    /**
     Configures the profile image view to be circular and sets its content mode.
     */
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
    
    
    /**
     Presents an action sheet to select an option for the profile picture.
     */
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
    
    
    /**
     Opens the image picker for the specified source type.
     - Parameters:
       - sourceType: The source type for the image picker (e.g., camera, photo library).
     */
    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    /**
     Handles the selected image from the image picker.
     - Parameters:
       - picker: The image picker controller.
       - info: A dictionary containing the selected image and other relevant info.
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let pickedImage = info[.originalImage] as? UIImage {
            let cropViewController = TOCropViewController(croppingStyle: .circular, image: pickedImage)
            cropViewController.delegate = self
            self.present(cropViewController, animated: true, completion: nil)
        }
    }
    
    /**
     Handles the cropped image from the crop view controller.
     - Parameters:
       - cropViewController: The crop view controller.
       - image: The cropped image.
       - cropRect: The cropping rectangle.
       - angle: The rotation angle.
     */
    func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
        profilePictureView.image = image
        self.changePicture = true
        cropViewController.dismiss(animated: true, completion: nil)
    }

}
