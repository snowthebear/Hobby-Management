//
//  UploadProgressViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import Foundation
import UIKit
import FirebaseAuth
import Firebase
import SDWebImage
import TOCropViewController

class UploadProgressViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate, UIImagePickerControllerDelegate {
    
    var goals: [String] = []
    weak var databaseController: DatabaseProtocol?
    var currentUser: FirebaseAuth.User?
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var mediaDate: UIDatePicker!
    
    @IBOutlet weak var goalsPicker: UIPickerView!
    
    @IBOutlet weak var captionTextField: UITextField!
    
    @IBOutlet weak var scheduleDatePicker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
//        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.navigationItem.hidesBackButton = true
        goalsPicker.dataSource = self
        goalsPicker.delegate = self
        
        self.currentUser = UserManager.shared.currentUser
//        self.currentUserLisr = UserManager.shared.currentUserList
        
        fetchGoals()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
//        databaseController?.addListener(listener: self)
//        self.currentUserList = UserManager.shared.currentUserList
        fetchGoals()
//        tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        resetHolder()
    }
    
    

    
    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let cropController = TOCropViewController(croppingStyle: .default, image: image)
                cropController.delegate = self
                cropController.customAspectRatio = CGSize(width: 3, height: 4)
                cropController.aspectRatioLockEnabled = true
                cropController.resetAspectRatioEnabled = false
                picker.dismiss(animated: true) {
                    self.present(cropController, animated: true, completion: nil)
                }
            } else {
                picker.dismiss(animated: true, completion: nil)
            }
        }
        
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        imageView.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func insertMediaButton(_ sender: Any) {
        let alert = UIAlertController(title: "Select an option", message: nil,  preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.pickImageFrom(.camera)
        }))

        alert.addAction(UIAlertAction(title: "Add Photo", style: .default, handler: { _ in
            self.pickImageFrom(.photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { _ in
            self.imageView.image = nil // Remove the image
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    
    @IBAction func postButton(_ sender: UIButton) {
        sender.isEnabled = false
//        uploadPost()
        uploadPost { [weak self] success in
            DispatchQueue.main.async {
//                sender.isEnabled = !success  // Re-enable the button only if posting failed
                if success {
                    self?.switchToHomePage()
                    sender.isEnabled = true
                    
                }
                else{
                    sender.isEnabled = true
                }
            }
        }
    
    }
    
    func resetHolder() {
        print("kk")
        imageView = nil
        captionTextField = nil
        
    }
    
    func fetchGoals() {
        guard let userID = self.currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }
        
        let userDocRef = Firestore.firestore().collection("users").document(userID)
        
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let goalsData = document.data()?["goals"] as? [[String: Any]] {
                    self.goals = goalsData.compactMap { $0["title"] as? String }
                    print("Fetched goals: \(self.goals)")
                    DispatchQueue.main.async {
                        self.goalsPicker.reloadAllComponents()
                    }
                }
            } else {
                print("Document does not exist or failed to fetch goals: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
}
    

    func uploadPost(completion: @escaping (Bool) -> Void) {
        // Extract data from the UI elements
        guard let image = imageView.image else {
            displayMessage(title: "Error", message: "Please select an image.")
            return
        }
        
        guard let userID = self.currentUser?.uid else {
            displayMessage(title: "Error", message: "User not logged in.")
            return
        }
        
        
        let selectedRow = goalsPicker.selectedRow(inComponent: 0)
        let selectedGoal = (goals.indices.contains(selectedRow)) ? goals[selectedRow] : ""
        let caption = captionTextField.text ?? ""
//        let postDate = scheduleDatePicker.date
        let postDate = Timestamp(date: scheduleDatePicker.date)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
//        
        let postID = UUID().uuidString
//        let storagePath = "posts/\(userID)/\(postID).jpg"
        let storagePath = "\(userID)/posts/\(postID).jpg"
        let storageRef = Storage.storage().reference().child(storagePath)
    
//        let storageRef = Storage.storage().reference().child("posts/\(userID)/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                guard let metadata = metadata else {
                    self.displayMessage(title: "Error", message: "Failed to upload image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
    
                storageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        let postData: [String: Any] = [
                            "imageUrl": downloadURL.absoluteString,
                            "goal": selectedGoal,
                            "caption": caption,
                            "postDate": postDate,
                            "userID": userID
                        ]
                        
                        Firestore.firestore().collection("posts").document(postID).setData(postData) { error in
                            if let error = error {
                                self.displayMessage(title: "Error", message: "Failed to save post data: \(error.localizedDescription)")
                            } else {
                                self.displayMessage(title: "Success", message: "Post uploaded successfully!")
                                self.switchToHomePage()
                            }
                        }
                    } else {
                        self.displayMessage(title: "Error", message: "Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
        
        else {
            displayMessage(title: "Error", message: "Could not compress image.")
        }
    }
    
    private func switchToHomePage() {
        DispatchQueue.main.async {
            if let tabBarController = self.tabBarController {
                tabBarController.selectedIndex = 0 // homepage index
                self.resetHolder()
            }
        }
    }
    
    
    // MARK: - UIPickerView DataSource and Delegate
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return goals.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return goals[row]
    }
    
}



