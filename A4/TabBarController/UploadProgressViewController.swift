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


/**
 UploadProgressViewController  manages the interface for users to upload new posts to the platform. It includes functionalities to select media, set post details like dates and hobbies, and finally upload the information to Firebase Firestore and Firebase Storage.
*/
class UploadProgressViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate, UIImagePickerControllerDelegate {
    
    var goals: [String] = [] // Stores user goals fetched from Firestore.
    weak var databaseController: DatabaseProtocol?
    var currentUser: FirebaseAuth.User?  // Current logged-in Firebase user.
    var currentUserList: UserList? // user hobbies list.
    
    @IBOutlet weak var defaultMenuAction: UICommand!

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var mediaDate: UIDatePicker!
    
    @IBOutlet weak var goalsPicker: UIPickerView!
    
    @IBOutlet weak var captionTextField: UITextField!
    
    @IBOutlet weak var scheduleDatePicker: UIDatePicker!
    
    @IBOutlet weak var durationPicker: UIDatePicker!
    
    @IBOutlet weak var hobbyButton: UIButton!
    
    
    /**
     Configures initial settings and fetches required data when the view is loaded.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.tabBarController?.navigationItem.hidesBackButton = true
        
        goalsPicker.dataSource = self
        goalsPicker.delegate = self
                
        self.currentUser = UserManager.shared.currentUser
        self.currentUserList = UserManager.shared.currentUserList
        
        fetchGoals()
        configureDurationPicker()
        setPopUpMenu()
        addBorderAndAdjustSize(to: imageView, basedOnWidth: imageView.frame.width)

    }
    
    /**
     Fetches user goals and prepares the UI elements every time the view becomes visible.
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        
        fetchGoals()
        viewDidLoad()
    }
    
    /**
     Fetches user goals and ensures all settings are re-checked before the view disappears.
    */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchGoals()
    }
    
    /**
     Adds a border and adjusts the size of a given view, specifically to maintain a 3:4 aspect ratio for the image view.
     
     - Parameter view: The view to modify.
     - Parameter width: The width based on which the height is adjusted.
    */
    func addBorderAndAdjustSize(to view: UIView, basedOnWidth width: CGFloat) {
            // Calculate height based on a 3:4 ratio
            let height = (4.0 / 3.0) * width

            // Adjusting constraints to maintain 3:4 aspect ratio
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: width),
                view.heightAnchor.constraint(equalToConstant: height)
            ])
            
            // Add border properties
            view.layer.borderWidth = 1.0
            view.layer.borderColor = UIColor.gray.cgColor
            view.layer.cornerRadius = 5.0
            view.clipsToBounds = true
        }

    /**
     Handles the selection of the hobby button, presenting users with options to select or change the hobby for their post.
    */
    @IBAction func hobbyButtonTapped(_ sender: UIButton) {
        setPopUpMenu()
    }
    
    
    func setPopUpMenu() {
        // Initialize the options array with the default "Select" action
        var optionsArray = [UIAction]()
        
        let optionClosure = { (action: UIAction) in
            print("\(action.title) selected")
        }
        
        // Create the default "Select" action and set it to be on by default
        let defaultAction = UIAction(title: "Select", state: .on, handler: optionClosure)
        optionsArray.append(defaultAction)
        
        // Check if there are any hobbies and add them to the menu
        if let hobbies = currentUserList?.hobbies, !hobbies.isEmpty {
            for hobby in hobbies {
                let action = UIAction(title: hobby.name ?? "None", handler: optionClosure)
                optionsArray.append(action)
            }
        }
        
        // Create an options menu with the array of actions
        let optionsMenu = UIMenu(title: "", children: optionsArray)
        hobbyButton.menu = optionsMenu
        hobbyButton.changesSelectionAsPrimaryAction = true
        hobbyButton.showsMenuAsPrimaryAction = true
    }
    
    /**
    Configures the duration picker to allow users to select times in one-minute intervals.
    */
    func configureDurationPicker() {
        durationPicker.datePickerMode = .countDownTimer
        durationPicker.minuteInterval = 1
    }
    
    /**
     Initiates the image picker controller to allow the user to pick an image from the specified source type.
     */
    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    /**
     Processes the selected image, applying cropping and setting it to the image view.
     */
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
    
    /**
     Handles the completion of image cropping, setting the cropped image to the imageView and dismissing the crop interface.

     - Parameters:
       - cropViewController: The instance of `TOCropViewController` handling the image cropping.
       - image: The UIImage object resulting from the crop action.
       - cropRect: The CGRect defining the area of the image that was cropped.
       - angle: The angle in degrees to which the original image was rotated during cropping.
    */
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        imageView.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    
    /**
     Presents an action sheet that allows the user to choose how to insert media into the post. Options include taking a new photo, selecting a photo from the library, or removing an already inserted photo.

     - Parameter sender: The UI element that triggered the action, typically a button.
    */
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
    
    
    /**
     Initiates the post upload process when the post button is tapped.
     */
    @IBAction func postButton(_ sender: UIButton) {
        sender.isEnabled = false
        uploadPost { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.switchToHomePage() // switch to home page if the user successfully upload the post
                    sender.isEnabled = true
                }
                else{
                    sender.isEnabled = true
                }
            }
        }
    }
    
    func resetHolder() { // reset the picture and caption text field
        imageView.image = nil
        captionTextField.text = ""
    }
    
    /**
    Fetches user-specific goals from Firestore and updates the picker view.
    */
    func fetchGoals() {
        guard let userID = self.currentUser?.uid else {
            print("Error: User not logged in.")
            return
        }
        
        let userDocRef = Firestore.firestore().collection("users").document(userID) // access the database "users" document
        
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let goalsData = document.data()?["goals"] as? [[String: Any]] { // get the goals data from the user's field in database
                    self.goals = goalsData.compactMap { dict -> String? in
                        guard let title = dict["title"] as? String, let completed = dict["completed"] as? Bool, !completed else {
                            return nil
                        }
                        return title // get the goals name
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
    
    
    /**
     Attempts to upload the prepared post data to Firebase, including image and post details.
     */
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
        
        if hobbyButton.titleLabel?.text == "Select" {
            displayMessage(title: "Hobby Required", message: "Please select a valid hobby before posting.")
            completion(false)
            return
        }
        
        
        let selectedRow = goalsPicker.selectedRow(inComponent: 0) // get the user chosen goal's row
        let selectedGoal = (goals.indices.contains(selectedRow)) ? goals[selectedRow] : ""
        let caption = captionTextField.text ?? "" // get the caption or set it to empty string if no caption.
        let postDate = Timestamp(date: mediaDate.date) // get the post date
        let scheduleDate = Timestamp(date: scheduleDatePicker.date)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
     
        let postID = UUID().uuidString
        let storagePath = "\(userID)/posts/\(postID).jpg"
        let storageRef = Storage.storage().reference().child(storagePath)
        
        let durationInSeconds = Int(durationPicker.countDownDuration)
        let minutes = durationInSeconds / 60 // store the duration in minutes
    

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
                        ] // the picture data for post
                        
                        Firestore.firestore().collection("posts").document(postID).setData(postData) { error in
                            if let error = error {
                                self.displayMessage(title: "Error", message: "Failed to save post data: \(error.localizedDescription)")
                            } else {
                                self.displayAskToCompleteGoal(goal: selectedGoal)
                                self.switchToHomePage()
                                self.resetHolder() // reset the holder if the user successfully upload.
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
    
    /**
     Navigates the user interface back to the home page tab upon successful post upload.
     It also resets the input fields and other UI elements to their default states.
    */
    private func switchToHomePage() { // swith the screen to home page if successful upload the post.
        DispatchQueue.main.async {
            if let tabBarController = self.tabBarController {
                tabBarController.selectedIndex = 0 // homepage index
                self.resetHolder()
            }
        }
    }
    
    /**
     Presents a dialog to the user asking if they wish to mark a specified goal as completed after a successful post upload.

     - Parameter goal: The title of the goal which user might want to mark as completed.
    */
    private func displayAskToCompleteGoal(goal: String) { // to display whether the user wants to mark the goals as completed
        if goal == "" {
            displayMessage(title: "Success", message: "Successfully post!")
            return
        }
        else {
            let alert = UIAlertController(title: "Success!", message: "Do you want to mark the goal '\(goal)' as completed?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.markGoalAsCompleted(goal: goal)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            present(alert, animated: true)
        }
        
    }
    
    /**
     Marks a specified goal as completed within the user's document in Firestore.

     - Parameter goal: The goal to mark as completed. This function finds the goal within the user's stored goals and updates its status.
    */
    private func markGoalAsCompleted(goal: String) { // mark the goal as complete
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
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int { // Returns the number of components for the picker view.
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return goals.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return goals[row]
    }
    
}



