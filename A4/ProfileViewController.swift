//
//  ProfileViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import UIKit
import Charts
import Firebase
import FirebaseAuth
import TOCropViewController
import SDWebImage


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HamburgerViewControllerDelegate, UIGestureRecognizerDelegate, TOCropViewControllerDelegate {
    
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var currentUser: FirebaseAuth.User?
    var userEmail: String?
    
    private var isHamburgerMenuShown: Bool = false
    
    
    @IBOutlet weak var leadingConstraintForHM: NSLayoutConstraint!
    
    @IBOutlet weak var hamburgerView: UIView!
    @IBOutlet weak var backViewForHamburger: UIView!
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var totalPostsLabel: UILabel!
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var customBarChartView: CustomBarChartView!
    
    @IBOutlet weak var progressSegmentedControl: UISegmentedControl!
    
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        updateChartData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hamburgerViewController?.currentUser = self.currentUser
        setupUI()
        customBarChartView.setupChart()
        loadDailyData()
        
        self.backViewForHamburger.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profilePictureView.addGestureRecognizer(tapGesture)
        profilePictureView.isUserInteractionEnabled = true
        configureProfileImageView()
        addUploadHintImage()
        setupProfilePicture()
        
        self.currentUser = UserManager.shared.currentUser
        self.displayNameLabel.text = self.currentUser?.displayName
        
//        if self.usersReference.document("\(userID)").collection("profile picture").document("\(timestamp)") != nil
//        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.backViewForHamburger.isHidden = true
    }
    
    func setProfilePicture() -> UIImage {
        return self.profilePictureView.image!
    }

    func setName() -> String {
        return self.currentUser?.displayName ?? "Unknown"
    }

    private func setupUI() {
        view.backgroundColor = .white
    }
    
    
    func editProfile() {
        self.performSegue(withIdentifier: "editProfileSegue", sender: self)
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            // Also remove any other user-related data if necessary
            UserDefaults.standard.removeObject(forKey: "userAuthToken")
            UserDefaults.standard.synchronize()
            
            // Navigate to login screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            loginViewController.modalPresentationStyle = .fullScreen
            // loginViewController.modalPresentationStyle = .fullScreen
            
            // Access the window property from the scene delegate if using UISceneDelegate
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = loginViewController
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            // Optionally, show an alert to the user about the error
        }
    }
    

    func hideHamburgerMenu() {
        self.hideHamburgerView()
    }
    
    @objc func handleBackTap() {
        hideHamburgerMenu()
    }
    
    private func hideHamburgerView(){
        
        UIView.animate(withDuration: 0.2, animations: {
            self.leadingConstraintForHM.constant = 10
                self.view.layoutIfNeeded()
        }) {(status) in
            
            UIView.animate(withDuration: 0.2, animations: {
                self.leadingConstraintForHM.constant = -280
                self.view.layoutIfNeeded()
            }) { (status) in
                self.backViewForHamburger.alpha = 0.75
                self.backViewForHamburger.isHidden = true
                self.isHamburgerMenuShown = !self.backViewForHamburger.isHidden
            }
        }
    }
    
    @IBAction func tappedOnHamburgerBackView(_ sender: Any) {
        self.hideHamburgerView()

    }
    
    
    @IBAction func showHamburgerMenu(_ sender: Any) {
        self.backViewForHamburger.isHidden = !self.backViewForHamburger.isHidden
        self.backViewForHamburger.alpha = 0.75
        
        UIView.animate(withDuration: 0.2, animations: {
            self.leadingConstraintForHM.constant = 10
            self.view.layoutIfNeeded()
        }) {(status) in
            UIView.animate(withDuration: 0.2, animations: {
                if self.backViewForHamburger.isHidden == false {
                    self.leadingConstraintForHM.constant = 0
                    self.view.layoutIfNeeded()
                }
                else {
                    self.leadingConstraintForHM.constant = -280
                    self.view.layoutIfNeeded()
 
                }
                
            }) { (status) in
//                self.backViewForHamburger.isHidden = !self.backViewForHamburger.isHidden
                self.isHamburgerMenuShown = !self.backViewForHamburger.isHidden
            }
        }
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == backViewForHamburger {
            return true
        }
        return false
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
    
    private func addUploadHintImage() {
        guard profilePictureView.subviews.first(where: { $0 is UIImageView }) == nil else { return } // Avoid adding the hint multiple times

        let hintLabel = UILabel()
        hintLabel.text = "+"
        hintLabel.font = UIFont.boldSystemFont(ofSize: 24)
        hintLabel.textColor = UIColor.gray.withAlphaComponent(0.3) // Set a subtle color
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.textAlignment = .right
        profilePictureView.addSubview(hintLabel)

        // Center the label within the profile image view
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: profilePictureView.centerXAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: profilePictureView.centerYAnchor)
        ])
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
        
        let timestamp = UInt(Date().timeIntervalSince1970)
        let filename = "\(timestamp).jpg"
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            displayMessage(title: "Error", message: "Image data could not be compressed")
            return
        }
        
        guard let userID = self.currentUser?.uid else {
            displayMessage(title: "Error", message: "No user logged in!")
            return
        }
        
        let imageRef = storageReference.child("\(userID)/\(timestamp)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        let uploadTask = imageRef.putData(data, metadata: metadata)
        
        uploadTask.observe(.success) { [weak self] snapshot in
            imageRef.downloadURL { (url, error) in
                if let downloadURL = url {
                    self?.usersReference.document(userID).setData(["profilePictureURL": downloadURL.absoluteString], merge: true)
                }
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            self.displayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
        }

        _ = setProfilePicture()
        cropViewController.dismiss(animated: true, completion: nil)
        
    }
    
    func setupProfilePicture() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let profilePictureURL = document.data()?["profilePictureURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: profilePictureURL), completed: nil)
                }
            } else {
                print("Document does not exist or error occurred: \(String(describing: error))")
            }
        }
    }
    
    
    func updateChartData() {
        switch progressSegmentedControl.selectedSegmentIndex {
        case 0:
            loadDailyData()
        case 1:
            loadWeeklyData()
        case 2:
            loadMonthlyData()
        default:
            break
        }
    }
    
    func loadDailyData() {
        let dataEntries = [
            BarChartDataEntry(x: 0, yValues: [1, 2, 3]),
            // Add more daily data entries
        ]
        updateChart(with: dataEntries)
    }
    
    
    func loadWeeklyData() {
        let dataEntries = [
            BarChartDataEntry(x: 0, yValues: [5, 4, 3]),
            // Add more weekly data entries
        ]
        updateChart(with: dataEntries)
    }
    
    func loadMonthlyData() {
        let dataEntries = [
            BarChartDataEntry(x: 0, yValues: [9, 6, 7]),
            // Add more monthly data entries
        ]
        updateChart(with: dataEntries)
    }
    
    func updateChart(with dataEntries: [BarChartDataEntry]) {
        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
        dataSet.colors = [UIColor.red, UIColor.green, UIColor.blue]

        let data = BarChartData(dataSets: [dataSet])
        customBarChartView.data = data
        customBarChartView.notifyDataSetChanged() // Refresh chart
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "hamburgerSegue") {
            if let controller = segue.destination as? HamburgerViewController {
                self.hamburgerViewController = controller
                self.hamburgerViewController?.delegate = self
                controller.currentUser = self.currentUser
            }
        }
        
        if segue.identifier == "editProfileSegue" {
            if let destination = segue.destination as? EditProfileViewController {
                destination.modalPresentationStyle = .fullScreen
                destination.currentUser = self.currentUser
//                self.hamburgerViewController = controller
//                self.hamburgerViewController?.delegate = self
            }
        }
    }
    
    private var beginPoint:CGFloat = 0.0
    private var differences:CGFloat = 0.0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isHamburgerMenuShown) {
            if let touch = touches.first {
                let location = touch.location(in: backViewForHamburger)
                beginPoint = location.x
                 
            }
        }
        else {
            return
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isHamburgerMenuShown) {
            if let touch = touches.first {
                let location = touch.location(in: backViewForHamburger)
                let dx = beginPoint - location.x
                
                if (dx > 0 && dx < 280  ){
                    self.leadingConstraintForHM.constant = -dx
                    differences = dx
                    self.backViewForHamburger.alpha = 0.75 - (0.75*differences/280)
                }
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isHamburgerMenuShown) {
            if (differences < 15) {
                self.leadingConstraintForHM.constant = 0
                return
            }
            if let touch = touches.first {
                if (differences > 150){
                    UIView.animate(withDuration: 0.1, animations: {
                        self.leadingConstraintForHM.constant = -280
                    }) { (status) in
                        self.backViewForHamburger.alpha = 0.0
                        self.isHamburgerMenuShown = false
                        self.backViewForHamburger.isHidden = true
                    }
                }
                else {
                    
                    UIView.animate(withDuration: 0.1, animations: {
                        self.leadingConstraintForHM.constant = 0
                    }) { (status) in
                        self.backViewForHamburger.alpha = 0.75
                        self.isHamburgerMenuShown = true
                        self.backViewForHamburger.isHidden = false
                    }
                }
            }
        }
    }
    
}
