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
    }
    
    @IBAction func changePasswordButtonn(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = self.currentUser?.displayName
        emailTextField.text = self.currentUser?.email
        
        self.configureProfileImageView()
        
        // Load the current user data
//        loadUserData()

    }
    
    
//    func loadUserData() {
//        guard let user = currentUser else { return }
//        
//        // Set email
//        emailTextField.text = user.email
//        
//        // Fetch and set the display name and profile image from Firestore
//        let db = Firestore.firestore()
//        let userDocRef = db.collection("users").document(user.uid)
//        userDocRef.getDocument { (document, error) in
//            if let document = document, document.exists {
//                let data = document.data()
//                self.nameTextField.text = data?["Full Name"] as? String
//                
//                if let profileImageUrl = data?["profileImageUrl"] as? String {
//                    self.loadProfileImage(urlString: profileImageUrl)
//                }
//            }
//        }
//    }
    
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
        print("a")
        profilePictureView.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    
    
    
   
}
