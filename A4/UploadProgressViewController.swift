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
    
    var currentUserList: UserList?
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var mediaDate: UIDatePicker!
    
    @IBOutlet weak var goalsPicker: UIPickerView!
    
    @IBOutlet weak var captionTextField: UITextField!
    
    @IBOutlet weak var scheduleDatePicker: UIDatePicker!
    
    @IBOutlet weak var durationPicker: UIDatePicker!
    
    @IBOutlet weak var hobbyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
//        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.navigationItem.hidesBackButton = true
        goalsPicker.dataSource = self
        goalsPicker.delegate = self
        
        
        self.currentUser = UserManager.shared.currentUser
        self.currentUserList = UserManager.shared.currentUserList
        
        fetchGoals()
        configureDurationPicker()
        setPopUpMenu()
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
        fetchGoals()
    }
    
    
    @IBAction func hobbyButtonTapped(_ sender: UIButton) {
        setPopUpMenu()
    }
    
    func setPopUpMenu() {
        guard let hobbies = currentUserList?.hobbies, !hobbies.isEmpty else {
            print("No hobbies available or currentUserList is nil")
            return
        }
        
        let optionClosure = {(action: UIAction) in
                    print(action.title)
                }
        
        var optionsArray = [UIAction]()
        let defaultAction = UIAction(title: "Select", state: .off, handler: optionClosure)
        optionsArray.append(defaultAction)

        for hobby in hobbies{
            let action = UIAction(title: hobby.name!, state: .off, handler: optionClosure)
            optionsArray.append(action)
        }
                
        optionsArray[0].state = .on

        // create an options menu
        let optionsMenu = UIMenu(title: "", options: .displayInline, children: optionsArray)
                
        // add everything
        hobbyButton.menu = optionsMenu

        hobbyButton.changesSelectionAsPrimaryAction = true
        hobbyButton.showsMenuAsPrimaryAction = true
    }

    
    func configureDurationPicker() {
        durationPicker.datePickerMode = .countDownTimer
        durationPicker.minuteInterval = 1
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
//        imageView = nil
//        captionTextField = nil
        
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
                    self.goals = goalsData.compactMap { dict -> String? in
                        guard let title = dict["title"] as? String, let completed = dict["completed"] as? Bool, !completed else {
                            return nil
                        }
                        return title
                    }
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
        
        guard let hobby = hobbyButton.titleLabel?.text else {
            displayMessage(title: "Error", message: "Select a hobby!")
            return
        }
        
        
        let selectedRow = goalsPicker.selectedRow(inComponent: 0)
        let selectedGoal = (goals.indices.contains(selectedRow)) ? goals[selectedRow] : ""
        let caption = captionTextField.text ?? ""
        let postDate = Timestamp(date: mediaDate.date)
        let scheduleDate = Timestamp(date: scheduleDatePicker.date)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
     
        let postID = UUID().uuidString
        let storagePath = "\(userID)/posts/\(postID).jpg"
        let storageRef = Storage.storage().reference().child(storagePath)
        
        let durationInSeconds = Int(durationPicker.countDownDuration)
        let minutes = durationInSeconds / 60
    

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                guard let metadata = metadata else {
                    self.displayMessage(title: "Error", message: "Failed to upload image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
    
                storageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        let postData: [String: Any] = [
                            "userID": userID,
                            "hobby": hobby,
                            "imageUrl": downloadURL.absoluteString,
                            "goal": selectedGoal,
                            "caption": caption,
                            "postDate": postDate,
                            "duration": minutes,
                            "schedule": scheduleDate
                        ]
                        
                        Firestore.firestore().collection("posts").document(postID).setData(postData) { error in
                            if let error = error {
                                self.displayMessage(title: "Error", message: "Failed to save post data: \(error.localizedDescription)")
                            } else {
                                self.displayAskToCompleteGoal(goal: selectedGoal)
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
    
    
    private func displayAskToCompleteGoal(goal: String) {
        let alert = UIAlertController(title: "Success!", message: "Do you want to mark the goal '\(goal)' as completed?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.markGoalAsCompleted(goal: goal)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(alert, animated: true)
    }
    
    
    
    private func markGoalAsCompleted(goal: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let userDocRef = Firestore.firestore().collection("users").document(userID)
        userDocRef.getDocument { documentSnapshot, error in
            if let document = documentSnapshot, document.exists, var goals = document.data()?["goals"] as? [[String: Any]] {
                // Find the index of the goal that needs to be updated
                if let index = goals.firstIndex(where: { ($0["title"] as? String) == goal }) {
                    // Update the 'completed' status of the goal
                    goals[index]["completed"] = true
                }

                // Update the goals array in Firestore
                userDocRef.updateData(["goals": goals]) { error in
                    if let error = error {
                        print("Error updating goal completion: \(error)")
                    } else {
                        print("Goal marked as completed.")
                        // Optionally notify the user of success
                    }
                }
            } else {
                print("Document does not exist or error fetching document: \(error?.localizedDescription ?? "Unknown error")")
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



