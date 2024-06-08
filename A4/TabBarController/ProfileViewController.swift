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


// Enum defining time periods that can be viewed in the profile.
enum Period {
    case day
    case week
    case month
}

/**
 ProfileViewController manages the user profile interface within the app.
 It interacts with Firebase Firestore to fetch and display user details and posts,
 and allows the user to edit their profile, follow/unfollow other users, and interact with various UI components.
*/

// ProfileViewController manages the user profile view, displaying personal data, posts, and interaction options such as following or unfollowing.
class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HamburgerViewControllerDelegate, UIGestureRecognizerDelegate, TOCropViewControllerDelegate {
    
    // ------------------- properties ----------------------
    private var hobbyColors: [String: UIColor] = [:] // stores colors for chart representation of hobbies.
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    var usersReference = Firestore.firestore().collection("users") // Reference to Firebase Firestore to interact with the user data.
    var storageReference = Storage.storage().reference() // Reference to Firebase Storage to manage user profile images.
    
    var currentUser: FirebaseAuth.User? // Current logged-in Firebase user.
    var currentUserList: UserList? // List of hobbies for current user.
    var userProfile: UserProfile? // Profile model for any user being viewed.
    var isCurrentUser: Bool = true // Indicates if the current profile is of the logged-in user.

    var imageUrls: [String] = [] // Stores URLs of images for posts.
    
    private var isHamburgerMenuShown: Bool = false // Flag to track visibility of the hamburger menu.
    
    // --------------------- outlet -----------------------
    @IBOutlet weak var postCollectionView: UICollectionView!
    @IBOutlet weak var hamburgerMenu: UIBarButtonItem!
    @IBOutlet weak var goalsMenu: UIBarButtonItem!
    @IBOutlet weak var leadingConstraintForHM: NSLayoutConstraint!
    @IBOutlet weak var hamburgerView: UIView!
    @IBOutlet weak var backViewForHamburger: UIView!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var hobbyButton: UIButton!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var totalPostsLabel: UILabel!
    @IBOutlet weak var allPostsLabel: UILabel!
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var customBarChartView: CustomBarChartView!
    @IBOutlet weak var progressSegmentedControl: UISegmentedControl!
    
    
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        updateChartData()
    }
    
    // Sets up initial UI elements, fetches user data, and configures collection view on view load.
    override func viewDidLoad() {
        super.viewDidLoad()
        hamburgerView.isHidden = true // hides the hamburger view as it is not needed at first
        self.backViewForHamburger.isHidden = true // hides the back view for hamburger view as it is not needed at first
        self.currentUser = UserManager.shared.currentUser // assign
        self.currentUserList = UserManager.shared.currentUserList // assign
        hamburgerViewController?.currentUser = self.currentUser
        
        setupUI() // setting up the UI
        
        // tap gesture for the user profile picture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profilePictureView.isUserInteractionEnabled = isCurrentUser
        profilePictureView.addGestureRecognizer(tapGesture)
        
        configureProfileImageView()
        addUploadHintImage()
        
        // check if its the logged in user
        if isCurrentUser {
            Task {
                await loadUserData()
            }
        }
        
        _ = setProfilePicture() // set the profile picture to the hamburger view
        
        customBarChartView.setupChart() // setting up the chart
        loadUserSettings() //load user setting
        loadDailyData() // load daily data for the chart

        setupCollectionView() // setup the profile post's collections
        updateFollowersFollowingLabels()

        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        postCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        if let userID = currentUser?.uid { // fetch all the user post's
            fetchImagesURL(userID: userID) { [weak self] fetchedUrls in
                self?.imageUrls = fetchedUrls
                DispatchQueue.main.async {
                    self?.postCollectionView.reloadData()
                    self?.fetchPostCount(for: userID)
                    self?.updateFollowersFollowingLabels()
                }
            }
        } else {
            print("Current user ID is nil.")
        }

    }
    
    override func viewWillAppear(_ animated: Bool) { // setting up the view controller whenever we go this controller
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true

        if isCurrentUser {
            // Fetch and update UI for the current logged-in user
            if let userID = currentUser?.uid {
                fetchPostCount(for: userID)
                setupProfile(for: userID)
                updateFollowersFollowingLabels()
            }
        } else{
            // load the user searched user.
            if let userID = self.userProfile?.userID {
                fetchPostCount(for: userID)
                setupProfile(for: userID)
                updateFollowersFollowingLabels()
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hamburgerView.isHidden = true
        self.backViewForHamburger.isHidden = true
        if self.isHamburgerMenuShown {
            self.hideHamburgerMenu()
        }
        progressSegmentedControl.selectedSegmentIndex = 0
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let allPostsLabelHeight = allPostsLabel.frame.size.height + 5
        let yOffset = allPostsLabel.frame.origin.y + allPostsLabelHeight
        
        let tabBarHeight = (tabBarController?.tabBar.frame.size.height ?? 0) + 5

        let collectionViewHeight = view.bounds.height - yOffset - tabBarHeight
        
        postCollectionView.frame = CGRect(x: 0, y: yOffset, width: view.bounds.width, height: collectionViewHeight)
    }
    

    /**
     Responds to the Follow/Unfollow button press. Ensures a user cannot follow themselves and toggles between follow and unfollow states for other users.
    */
    @IBAction func followButton(_ sender: Any) {
        // avoid follow the user itself.
        guard let viewedUserID = userProfile?.userID,
              let currentUserID = currentUser?.uid,
              viewedUserID != currentUserID else {
            print("Action not permitted.")
            return
        }
        
        // if the user havent follow that other user
        if (sender as AnyObject).title(for: .normal) == "Follow" {
            followUser(withID: viewedUserID) { [weak self] in
                self?.followButton.setTitle("Unfollow", for: .normal)
                self?.updateFollowersFollowingLabels()
            }
        } else { // if the user wants to unfollow
            unfollowUser(withID: viewedUserID) { [weak self] in
                self?.followButton.setTitle("Follow", for: .normal)
                self?.updateFollowersFollowingLabels()
            }
        }
    }

    /**
     Updates the display labels for followers and following counts by fetching data from Firestore.
    */
    func updateFollowersFollowingLabels() { // updating the label
        // Helper function to update labels based on the user's ID and labels
        func updateLabels(for userID: String, followersLabel: UILabel, followingLabel: UILabel) {
            let userRef = usersReference.document(userID)

            // Fetch the count of followings
            userRef.collection("following").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching followings: \(error)")
                } else {
                    let followingCount = snapshot?.documents.count ?? 0
                    DispatchQueue.main.async {
                        followingLabel.text = "\(followingCount)"
                    }
                }
            }

            // Fetch the count of followers
            userRef.collection("followers").getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching followers: \(error)")
                } else {
                    let followersCount = snapshot?.documents.count ?? 0
                    DispatchQueue.main.async {
                        followersLabel.text = "\(followersCount)"
                    }
                }
            }
        }

        // Determine which user profile to update
        if isCurrentUser {
            guard let currentUserID = currentUser?.uid else { return }
            updateLabels(for: currentUserID, followersLabel: self.followersLabel, followingLabel: self.followingLabel)
        } else if let viewedUserID = userProfile?.userID, viewedUserID != currentUser?.uid {
            updateLabels(for: viewedUserID, followersLabel: self.followersLabel, followingLabel: self.followingLabel)
        }
    }
    
    
    /**
     Initiates following a user by updating Firestore collections and counters for both the current user and the viewed user.
     
     - Parameter viewedUserID: ID of the user to follow.
     - Parameter completion: Closure to execute after the operation is completed.
    */
    func followUser(withID viewedUserID: String, completion: @escaping () -> Void) { // for updating the followers and following of the user and logged-in user
        let db = Firestore.firestore()
        let currentUserID = currentUser?.uid ?? ""
        let batch = db.batch()
        
        // References to the user documents
        let currentUserRef = db.collection("users").document(currentUserID)
        let viewedUserRef = db.collection("users").document(viewedUserID)
        
        // Update following and followers subcollections
        let currentUserFollowingRef = currentUserRef.collection("following").document(viewedUserID)
        let viewedUserFollowersRef = viewedUserRef.collection("followers").document(currentUserID)
        
        batch.setData([:], forDocument: currentUserFollowingRef)
        batch.setData([:], forDocument: viewedUserFollowersRef)
        
        
        // Update following and followers counts
        batch.updateData(["following": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
        batch.updateData(["followers": FieldValue.increment(Int64(1))], forDocument: viewedUserRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error updating following/followers: \(error.localizedDescription)")
            } else {
                print("Successfully followed user")
                completion()
            }
        }
    }
    
    /**
     Initiates unfollowing a user by updating Firestore collections and counters for both the current user and the viewed user.
     
     - Parameter viewedUserID: ID of the user to unfollow.
     - Parameter completion: Closure to execute after the operation is completed.
    */
    func unfollowUser(withID viewedUserID: String, completion: @escaping () -> Void) { // for updating the followers and following of the user and logged-in user
        let db = Firestore.firestore()
        let currentUserID = currentUser?.uid ?? ""
        let batch = db.batch()
        
        // References to the user documents
        let currentUserRef = db.collection("users").document(currentUserID)
        let viewedUserRef = db.collection("users").document(viewedUserID)
        
        // Update following and followers subcollections
        let currentUserFollowingRef = currentUserRef.collection("following").document(viewedUserID)
        let viewedUserFollowersRef = viewedUserRef.collection("followers").document(currentUserID)
        
        batch.deleteDocument(currentUserFollowingRef)
        batch.deleteDocument(viewedUserFollowersRef)
        
        // Update following and followers counts
        batch.updateData(["following": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
        batch.updateData(["followers": FieldValue.increment(Int64(-1))], forDocument: viewedUserRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error updating following/followers: \(error.localizedDescription)")
            } else {
                print("Successfully unfollowed user")
                completion()
            }
        }
    }

    
    /**
         Sets up the layout and properties of the collection view used to display posts.
     */
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let size = (view.frame.width - 4) / 3
        layout.itemSize = CGSize(width: size, height: size)
        
        postCollectionView.setCollectionViewLayout(layout, animated: true)

        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        postCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
    }
    
    /**
     Returns the current image displayed as the profile picture in the profile view controller.
     
     - Returns: A UIImage object representing the current profile picture.
    */
    func setProfilePicture() -> UIImage { // setting up the profile picture in hamburger view
        return self.profilePictureView.image ?? UIImage(named: "default_picture")!
    }

    /**
     Returns the current name displayed in the profile view controller.
     
     - Returns: A string representing the user's displayed name.
    */
    func setName() -> String { // setting up the name in hamburger view
        return self.displayNameLabel.text ?? "Unknown"
    }

    /**
     Configures the initial UI settings for the profile view controller based on whether the current user is viewing their own profile.
    */
    private func setupUI() { // setting up the UI
        view.backgroundColor = .white

        hamburgerMenu.isHidden = !isCurrentUser
        goalsMenu.isHidden = !isCurrentUser
        hobbyButton.isHidden = !isCurrentUser

        followButton.isHidden = isCurrentUser
    }
    
    /**
     Initiates the editing process for the user profile, performing a segue and setting up the edit profile view.
    */
    func editProfile() { // if the user press edit profile in hamburger view
        self.performSegue(withIdentifier: "editProfileSegue", sender: self)
        setupEditProfile()
    }
    
    /**
     Handles the user logout process, including signing out from Firebase Authentication and navigating to the login screen.
    */
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
            loginViewController.navigationController?.isNavigationBarHidden = false
            loginViewController.title = "HOBSNAP"
            
            // Access the window property from the scene delegate if using UISceneDelegate
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.window?.rootViewController = loginViewController
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    
    /**
     Sets up the user interface elements based on the current user's profile data retrieved from Firestore.
    */
    func setupEditProfile() {
        // setting up the user data inside the edit profile such as name, email, and profile picture.
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let storageURL = document.data()?["storageURL"] as? String { //getting the profile picture
                    self?.profilePictureView.sd_setImage(with: URL(string: storageURL), completed: nil)
                }
                if let userData = document.data() {
                    UserManager.shared.userData = userData
                    if let displayName = userData["displayName"] as? String { // getting the name
                        self?.displayNameLabel.text = displayName
                        
                    }
                }
            } else {
                print("Document does not exist or error occurred: \(String(describing: error))")
            }
        }
    }
    
    /**
     Checks if the specified user is already followed by the current user.
     
     - Parameter userID: The user ID to check against the current user's following list.
     - Parameter completion: The completion handler that returns the result as a boolean.
    */
    func checkIfUserIsFollowed(userID: String, completion: @escaping (Bool) -> Void) { // to check whether the user is followed
        guard let currentUserID = currentUser?.uid else { return }

        let followingRef = usersReference.document(currentUserID).collection("following").document(userID)
        followingRef.getDocument { documentSnapshot, error in
            completion(documentSnapshot?.exists ?? false)
        }
        
    }
    
    
    /**
     Configures the profile view based on the userID, distinguishing between current and searched users.

     - Parameter userID: The user ID for which the profile needs to be set up.
    */
    func setupProfile(for userID: String) { // setup the profile for either searched user and logged-in user
        // mark with the boolean
        if isCurrentUser {
            loadCurrentUserProfile() // for current logged-in user
        } else {
            loadUserProfile(for: userID) // for the searched user
            checkIfUserIsFollowed(userID: userID) { [weak self] isFollowed in
                DispatchQueue.main.async {
                    self?.followButton.setTitle(isFollowed ? "Unfollow" : "Follow", for: .normal)
                }
            }
        }
    }

    
    /**
     Retrieves and updates the UI with the current logged-in user's profile data.

     - Uses Firestore to fetch user data and updates the UI accordingly.
    */
    private func loadCurrentUserProfile() { // retrieve all the logged-in user information
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let usersReference = Firestore.firestore().collection("users")
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                print("Document does not exist or error occurred: \(error?.localizedDescription ?? "No error")")
                return
            }

            do {
                var userProfile = try document.data(as: UserProfile.self)
                userProfile.userID = userID // Set the userID manually
                self.updateUI(with: userProfile) // update all the UI inside the profile view controller with the current user information
                self.fetchImagesURL(userID: userID) { [weak self] fetchedUrls in
                    self?.imageUrls = fetchedUrls
                    DispatchQueue.main.async {
                        self?.postCollectionView.reloadData()
                        self?.updateFollowersFollowingLabels()
                    }
                }
            } catch let error {
                print("Error decoding user profile: \(error)")
            }
        }
    }
    
    
    /**
     Fetches and sets up the profile for a user specified by userID, intended for viewing profiles other than the logged-in user.

     - Parameter userID: The user ID of the profile to load.
    */
    private func loadUserProfile(for userID: String) {  // retrieve all the searched user information
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                print("Document does not exist or error occurred: \(error?.localizedDescription ?? "No error")")
                return
            }

            do {
                guard let userProfile = self.userProfile else {
                    return
                }
                
                // update all the UI inside the profile view controller with the current user information
                self.userProfile = userProfile
                self.updateUI(with: userProfile)
                self.updateFollowersFollowingLabels()
                self.fetchImagesURL(userID: userID) { [weak self] fetchedUrls in
                    self?.imageUrls = fetchedUrls
                    DispatchQueue.main.async {
                        self?.postCollectionView.reloadData()
                        self?.fetchPostCount(for: userID)
                        
                    }
                }
            }
        }
    }


    /**
     Updates various UI components with the information from the user's profile data.

     - Parameter userProfile: The user profile data used to update the UI.
    */
    func updateUI(with userProfile: UserProfile) { // update the profile picture, name, and chart for the user
        DispatchQueue.main.async {
            self.displayNameLabel.text = userProfile.displayName
            if let url = URL(string: userProfile.storageURL) {
                self.profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultProfile"))
            }
            self.updateChartData()
        }
    }


    func hideHamburgerMenu() { // hide the hamburger menu
        self.hideHamburgerView()
    }
    
    @objc func handleBackTap() { // to handle the back tap of hamburger menu
        hideHamburgerMenu()
    }
    
    private func hideHamburgerView(){ // the logic of hiding the hamburger view
        UIView.animate(withDuration: 0.2, animations: {
            self.leadingConstraintForHM.constant = 10 // the bounce of the animation of showing the hamburger view
                self.view.layoutIfNeeded()
        }) {(status) in
            
            UIView.animate(withDuration: 0.2, animations: {
                self.leadingConstraintForHM.constant = -280 // set to this number as per our constraint
                self.view.layoutIfNeeded()
            }) { (status) in
                self.backViewForHamburger.alpha = 0.75
                self.backViewForHamburger.isHidden = true
                self.isHamburgerMenuShown = !self.backViewForHamburger.isHidden // when the user press the hamburger menu, reverse it
            }
        }
    }
    
    /**
     Triggered when the user taps on the background view of the hamburger menu, used to close the menu.
    */
    @IBAction func tappedOnHamburgerBackView(_ sender: Any) { // hide the hamburger menu if the user tap the back view of hamburger view
        self.hideHamburgerView()

    }
    
    /**
     Displays the hamburger menu by setting visibility and updating UI elements within the menu.
    */
    @IBAction func showHamburgerMenu(_ sender: Any) { // showing the hamburger menu logic
        hamburgerView.isHidden = false // showing the hamburger menu
        hamburgerViewController?.setupPicture() // setup the picture inside the hamburger view
        hamburgerViewController?.setName() // set the name inside the hamburgerview
        
        self.backViewForHamburger.isHidden = !self.backViewForHamburger.isHidden
        self.backViewForHamburger.alpha = 0.75
        
        UIView.animate(withDuration: 0.2, animations: { // bounce animation of showing the hamburger menu
            self.leadingConstraintForHM.constant = 10
            self.view.layoutIfNeeded()
        }) {(status) in
            UIView.animate(withDuration: 0.2, animations: {
                if self.backViewForHamburger.isHidden == false {
                    self.leadingConstraintForHM.constant = 0 // set to this number as per our constraint
                    self.view.layoutIfNeeded()
                }
                else {
                    self.leadingConstraintForHM.constant = -280
                    self.view.layoutIfNeeded()
 
                }
                
            }) { (status) in
                self.isHamburgerMenuShown = !self.backViewForHamburger.isHidden // when the user press the hamburger menu, reverse it
            }
        }
        
    }
    
    /**
     Determines if a gesture should begin based on the touch location within the hamburger back view.
    */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // for gesture recognitation.
        if touch.view == backViewForHamburger {
            return true
        }
        return false
    }
    
    /**
     Configures the initial appearance of the profile image view.
    */
    private func configureProfileImageView() { // configuring the profile picture UI
        // Make the image view circular
        profilePictureView.layer.cornerRadius = profilePictureView.frame.size.width / 2
        profilePictureView.clipsToBounds = true
      
        profilePictureView.contentMode = .scaleAspectFill
        
        profilePictureView.layer.borderWidth = 0.5 // give the profile picture a border
        profilePictureView.layer.borderColor = UIColor.black.cgColor
        
        if profilePictureView.image == nil {
            profilePictureView.image = UIImage(named: "default_picture") // if there's no profile picture, set it to the default picture.
        }
    }
    
    /**
     Adds a visual hint to the profile image view indicating the user can upload an image.
    */
    private func addUploadHintImage() { // add upload hint '+' inside the profile picture to give a hint to the user.
        guard profilePictureView.subviews.first(where: { $0 is UIImageView }) == nil else { return }
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
    
    
    /**
     Presents an action sheet allowing the user to select a photo source or remove the current photo.
    */
    @objc func handleImageTap() { // if the user tap the profile picture
        // showing up the option for user to uplaode the profile picture/
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
     Presents an image picker to allow the user to select an image from the specified source.
    */
    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        // pick the image for the source
        let imagePicker = UIImagePickerController() // utilizing the UIImaagePickerController
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    /**
     Handles the image selected by the user, potentially cropping it and updating the UI.
    */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // if the user chose a picture
        dismiss(animated: true)
        if let pickedImage = info[.originalImage] as? UIImage {
            let cropViewController = TOCropViewController(croppingStyle: .circular, image: pickedImage) // crop to a circle as the profile picture is set to be a circle
            cropViewController.delegate = self
            self.present(cropViewController, animated: true, completion: nil)
        
        }
    }

    /**
     Handles the cropped image, updates the user profile picture, and uploads it to storage.
    */
    func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
        profilePictureView.image = image // setting the UI image to the chosen picture.
        let filename = "profile/profile_picture.jpg"

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            DisplayMessage(title: "Error", message: "Image data could not be compressed")
            return
        }

        guard let userID = self.currentUser?.uid else {
            DisplayMessage(title: "Error", message: "No user logged in!")
            return
        }
        
        // save the picture to our firebase database
        let imageRef = storageReference.child("\(userID)/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadTask = imageRef.putData(data, metadata: metadata)
        
        imageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                self.DisplayMessage(title: "Error", message: "Failed to upload image: \(error.localizedDescription)")
                return
            }

            imageRef.downloadURL { url, error in
                if let downloadURL = url {
                    // Update Firestore with the new image URL
                    self.usersReference.document(userID).setData([
                        "storageURL": downloadURL.absoluteString,
                    ], merge: true)
                }
            }
        }

        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    
    /**
     Sets up the user's profile picture by retrieving it from Firestore and updating the UI accordingly.
    */
    func setupProfilePicture() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let storageURL = document.data()?["storageURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: storageURL), completed: nil)
                }
                if let userData = document.data() {
                    UserManager.shared.userData = userData
                    if let displayName = userData["displayName"] as? String { // retrieving the name
                        self?.displayNameLabel.text = displayName // set the name to the displayNameLabel
                    }
                }
            } else {
                print("Document does not exist or error occurred: \(String(describing: error))")
            }
        }
    }

    
    
    // ---------------------------------------- Chart -----------------------------------------------------
    
    
    func updateChartData() { // to update the chart from the segment user's choose.
        let userID = isCurrentUser ? currentUser?.uid : userProfile?.userID
        guard let userID = userID else { return }
        
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
    
    func loadDailyData() { // load the daily data of the user spent on their hobby
        fetchData(for: .day) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    func loadWeeklyData() { // load the weekly data of the user spent on their hobby
        fetchData(for: .weekOfYear) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    func loadMonthlyData() { // load the monthly data of the user spent on their hobby
        fetchData(for: .month) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    
    /**
     Updates the chart with new data entries and ensures the chart displays the latest hobby progress.

     - Parameters:
       - dataEntries: Array of bar chart data entries.
       - hobbies: Dictionary of hobby names and their respective time spent in minutes.
    */
    func updateChart(with dataEntries: [BarChartDataEntry], hobbies: [String: Double]) { // updating the chart to show their progress on their hobby
        let sortedHobbies = hobbies.keys.sorted()

        initializeHobbyColors(hobbies: sortedHobbies) // initialize each of the hobby with a color for the chart

        let sortedDataEntries = dataEntries.sorted {
            let hobby1 = Array(hobbies.keys)[Int($0.x)]
            let hobby2 = Array(hobbies.keys)[Int($1.x)]
            return hobby1 < hobby2
        }

        let dataSet = BarChartDataSet(entries: sortedDataEntries, label: "Hobbies")
        dataSet.colors = sortedDataEntries.map { entry in
            let hobbyIndex = Int(entry.x)
            let hobby = sortedHobbies[hobbyIndex]
            return hobbyColors[hobby] ?? .black // returning the color of the hobby
        }

        let data = BarChartData(dataSets: [dataSet])
        customBarChartView.data = data
        customBarChartView.legend.setCustom(entries: createLegendEntries(hobbies: hobbies, sortedKeys: sortedHobbies))
        customBarChartView.notifyDataSetChanged() // Refresh the chart
    }

    
    /**
     Fetches hobby data for the specified time period and computes the duration spent on each hobby.

     - Parameters:
       - period: Time period component (day, weekOfYear, or month).
       - completion: Closure that handles the result as bar chart data entries and a dictionary of hobby durations.
    */
    private func fetchData(for period: Calendar.Component, completion: @escaping ([BarChartDataEntry], [String: Double]) -> Void) {
        // fetching all the user data for the profile picture view controller from the database
        
        guard let userID = isCurrentUser ? currentUser?.uid : userProfile?.userID else {
            print("No user ID available")
            completion([], [:])
            return
        }
   
        guard let hobbiesList = (isCurrentUser ? currentUserList?.hobbies : userProfile?.userHobby) else {
            print("No hobbies list available")
            completion([], [:])
            return
        }
            
        var hobbyDurations = [String: Double]() // to store the hobby and their duration spent on each hobby in minutes.
        for hobby in hobbiesList {
            hobbyDurations[hobby.name ?? ""] = 0.0
        }
        
        let db = Firestore.firestore()
        db.collection("posts").whereField("userID", isEqualTo: userID).getDocuments { (querySnapshot, error) in
            // access the database "posts" document with finding the correect "userID" for the process.
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                completion([], hobbyDurations)
                return
            }
            
            let calendar = Calendar.current
            let now = Date()
            
            for document in documents {
                if let postDate = (document.data()["postDate"] as? Timestamp)?.dateValue(), // getting the post date
                   let hobbyName = document.data()["hobby"] as? String, // getting the hobby name
                   let duration = document.data()["duration"] as? Double, // getting the total duration
                   hobbyDurations[hobbyName] != nil { // Only count durations for hobbies in the current list
                    
                    var shouldInclude = false
                    switch period {
                    case .day:
                        shouldInclude = calendar.isDateInToday(postDate)
                    case .weekOfYear:
                        shouldInclude = calendar.isDate(postDate, equalTo: now, toGranularity: .weekOfYear)
                    case .month:
                        shouldInclude = calendar.isDate(postDate, equalTo: now, toGranularity: .month)
                    default:
                        break
                    }
                    
                    if shouldInclude {
                        hobbyDurations[hobbyName]! += duration // increment the duration
                    }
                }
            }
            
            let dataEntries = hobbyDurations.compactMap { (hobby, duration) -> BarChartDataEntry? in
                if let index = hobbiesList.firstIndex(where: {$0.name == hobby}) { // getting the obby from the hobbiesList
                    let visualValue = max(0.1, duration) // 0.1 just to show the visual of the bart chart
                    let entry = BarChartDataEntry(x: Double(index), y: visualValue)
                    entry.data = Int(duration) as AnyObject
                    return entry
                }
                return nil
            }.sorted(by: {$0.x < $1.x})
            
            completion(dataEntries, hobbyDurations)
        }
    }

    
    /**
     Initializes colors for hobbies to ensure each hobby is represented by a distinct color in the chart.

     - Parameters:
       - hobbies: List of hobby names to assign colors to.
    */
    private func initializeHobbyColors(hobbies: [String]) { // initialize the hobby color
        loadUserSettings() // load the uesr setting to ensure no repeating color assignment if the user has already initialize it
        let colors = generateDistinctColors() // generate different color for each hobby
        var colorIndex = 0
        for hobby in hobbies {
            if hobbyColors[hobby] == nil {
                hobbyColors[hobby] = colors[colorIndex % colors.count]
                colorIndex += 1 // increment the index to avoid using the same color.
            }
        }
        saveUserSettings() // save the user setting
    }
    

    /**
     Creates legend entries for the chart based on the sorted hobbies and their assigned colors.

     - Parameters:
       - hobbies: Dictionary of hobbies and their durations.
       - sortedKeys: Sorted list of hobby names.
     - Returns: Array of LegendEntry objects for the chart legend.
    */
    private func createLegendEntries(hobbies: [String: Double],  sortedKeys: [String]) -> [LegendEntry] {
        return sortedKeys.map { hobby in
            let entry = LegendEntry(label: hobby)
            entry.form = .square
            entry.formSize = 10.0
            entry.formLineWidth = 1.0
            entry.formLineDashPhase = 0.0
            entry.formLineDashLengths = nil
            entry.formColor = hobbyColors[hobby] ?? .gray // Ensure the color is consistent
            return entry
        }
    }
    
    
    /**
     Converts a UIColor to a Data object for storage in UserDefaults.

     - Parameters:
       - color: The UIColor instance to convert.
     - Returns: Optional Data representation of the UIColor.
    */
    func colorToData(color: UIColor) -> Data? { // Helper function to convert from UIColor to Data
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            return data
        } catch {
            print("Error converting color to data: \(error)")
            return nil
        }
    }
    
    /**
     Converts stored Data back to a UIColor instance.

     - Parameters:
       - data: Data object representing a UIColor.
     - Returns: Optional UIColor derived from the Data.
    */
    func dataToColor(data: Data) -> UIColor? { // Helper function to convert from Data to UIColor
        do {
            if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return color
            }
        } catch {
            print("Error converting data to color: \(error)")
        }
        return nil
    }
    
    func loadUserSettings() { // load the user setting for the hobby colors.
        let userDefaults = UserDefaults.standard
        if let storedHobbyColors = userDefaults.object(forKey: "HobbyColors") as? [String: Data] {
            hobbyColors = storedHobbyColors.compactMapValues { dataToColor(data: $0) }
        }
    
    }

    func saveUserSettings() { // save the setting for the hobby colors for each user.
        let userDefaults = UserDefaults.standard
        let storedHobbyColors = hobbyColors.compactMapValues { colorToData(color: $0) }
        userDefaults.set(storedHobbyColors, forKey: "HobbyColors")
    }
    
    /**
     Generates a list of distinct colors used for differentiating hobbies in the chart.
     
     - Returns: Array of UIColor instances.
    */
    private func generateDistinctColors() -> [UIColor] { // generating different color for each hobbies.
        return [
            
            UIColor.red,
            UIColor.green,
            UIColor.magenta,
            UIColor.orange,
            UIColor.purple,
            UIColor.cyan,
            UIColor.blue,
            UIColor.yellow,
            UIColor.brown,
            
            UIColor.systemMint,
            UIColor.systemCyan,
            UIColor.systemRed,
            UIColor.systemBlue,
            UIColor.systemGreen,
            UIColor.systemYellow,
            UIColor.systemOrange,
            UIColor.systemPurple,
            UIColor.systemTeal,
            UIColor.systemPink,
            UIColor.systemIndigo,
            UIColor.systemBrown,
            UIColor.systemGray
            
        ]
    }

    
    // ======================================================================================
    
    
    
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
                destination.displayName = self.displayNameLabel.text
            }
        }
    }
    
// ====================== touch back hamburger =================================================
    // reference : https://www.youtube.com/watch?v=L6zB8xABwjs , https://github.com/kashyapbhatt/iOSHamburgerMenu/blob/main/HamburgerMenu/HamburgerViewController.swift
    
    private var beginPoint:CGFloat = 0.0 // initial touch point on the screen used for calculating the drag distance.
    private var differences:CGFloat = 0.0 // difference between the initial touch point and the current touch point during a drag.
    
    
    /**
     Handles the beginning of a touch event. Records the initial touch point used later to calculate drag distances.

     - Parameters:
       - touches: A set of UITouch instances that represent the touches for the starting phase of the event, which are typically the touches involved in the initial tap.
       - event: An object encapsulating the information about the touch event.
    */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // for the first time user tap
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
    
    /**
     Responds to movements of a touch event within the view. Adjusts the leading constraint of the hamburger menu based on the drag distance to create a sliding effect.

     - Parameters:
       - touches: A set of UITouch instances that represent the touches during the moving phase of the event.
       - event: An object encapsulating the information about the touch event.
    */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { // when there's a movement from the tap
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
    
    /**
     Responds to movements of a touch event within the view. Adjusts the leading constraint of the hamburger menu based on the drag distance to create a sliding effect.

     - Parameters:
       - touches: A set of UITouch instances that represent the touches during the moving phase of the event.
       - event: An object encapsulating the information about the touch event.
    */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { // the moment the tap stopped.
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
    
    // ==============================================================================
    
    /**
     Loads the current user's data asynchronously to populate UI elements such as the display name, profile image, and total posts label. This method fetches the user document from Firestore based on the current user's ID.

     This function ensures that UI updates are performed on the main thread to prevent issues with UI access from background threads.

     - Precondition: `currentUser` must be non-nil.
     - Postcondition: UI elements are updated with user data.
    */
    func loadUserData() async{ // load user data to display the name, profile image, and total posts label.
        guard let user = currentUser else { return }
        
        let userDocRef = usersReference.document(user.uid)
            do {
                let document = try await userDocRef.getDocument()
                if let data = document.data() {
                    DispatchQueue.main.async { [weak self] in
                        self?.displayNameLabel.text = data["displayName"] as? String
                        if let profileImageUrl = data["storageURL"] as? String {
                            self?.loadProfileImage(urlString: profileImageUrl)
                        }
                        self?.totalPostsLabel.text = data["total posts"] as? String
                    }
                }
            } catch {
                print("Error fetching document: \(error.localizedDescription)")
            }
    }
    
    /**
     Loads and sets the user's profile image into the profilePictureView using the SDWebImage library, which caches images and manages loading them efficiently to optimize performance and network usage.

     - Parameter urlString: The URL string of the user's profile image.
     - Precondition: `urlString` must be a valid URL.
     - Postcondition: The user's profile image is updated in the UI.
    */
    func loadProfileImage(urlString: String) { // load the user profile image and use SDImageWeb to avoid retrieving multiple times.
        guard let url = URL(string: urlString) else { return }
        profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_picture"), options: .continueInBackground, completed: nil)
    }
    
    
    /**
     Fetches the URLs of all images associated with a user's posts from Firestore. This function accesses the 'posts' collection and filters documents by the user's ID to retrieve all associated image URLs.

     - Parameter userID: The user ID for which to fetch post images.
     - Parameter completion: A closure that takes an array of strings (image URLs) and returns void. It is called when the image URLs are fetched successfully or on failure.
     - Precondition: `userID` should be a valid identifier corresponding to a user.
     - Postcondition: Returns an array of image URLs or an empty array if an error occurs.
    */
    func fetchImagesURL(userID: String, completion: @escaping ([String]) -> Void) { // fetching the image for all the user's posts
        let postsRef = Firestore.firestore().collection("posts").whereField("userID", isEqualTo: userID) // access the database posts using the userID
        postsRef.getDocuments { (snapshot, error) in
            var imageUrls: [String] = []
            if let error = error {
                print("Error fetching posts: \(error)") // error handling
                completion([])
            } else {
                for document in snapshot!.documents {
                    if let imageUrl = document.data()["imageUrl"] as? String { // retrieve all the image url from the "imageUrl" in the document data
                        imageUrls.append(imageUrl)
                    } else {
                        print("Document \(document.documentID) does not contain a valid 'imageUrl'")
                    }
                }
                completion(imageUrls)
            }
        }
    }
    
    
    
    /**
     Retrieves and updates the total number of posts made by a user. This method queries the 'posts' collection for documents matching the provided user ID and counts them.

     - Parameter userID: The identifier for the user whose post count is to be retrieved.
     - Precondition: `userID` must correspond to a valid user.
     - Postcondition: Updates the UI element displaying the total number of posts.
    */
    func fetchPostCount(for userID: String) { // retrieve the total posts the user has so far
        let postsRef = Firestore.firestore().collection("posts").whereField("userID", isEqualTo: userID)
        postsRef.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching posts: \(error)")
                self.totalPostsLabel.text = "0"  // show 0 in case of error
            } else if let snapshot = querySnapshot {
                let count = snapshot.documents.count // count the posts user has
                self.totalPostsLabel.text = "\(count)" // showing the correct total of user's post
            }
        }
    }
}


/**
 Extension for ProfileViewController that conforms to UICollectionViewDelegate, UICollectionViewDataSource, and UICollectionViewDelegateFlowLayout protocols. This extension manages the display and interaction of a UICollectionView which shows images related to the user's profile.
 */
extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    /**
     Determines the number of items in the collection view's section, which corresponds to the number of images available.
     
     - Parameters:
        - collectionView: The collection view requesting this information.
        - section: An integer identifying the section of the collection view.
     - Returns: The number of items (images) in the section.
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    
    /**
     Provides the cell to be used for a specific location in the collection view. Cells are reused as they scroll off-screen using the cell's reuse identifier.
     
     - Parameters:
        - collectionView: The collection view requesting the cell.
        - indexPath: An index path locating the item in the collection view.
     - Returns: A configured cell object. If no cell is available for reuse and cannot be created, a fatal error is triggered.
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Unable to dequeue PhotoCollectionViewCell")
        }

        if indexPath.row < imageUrls.count, let imageUrl = URL(string: imageUrls[indexPath.row]) {
            cell.configure(with: imageUrl) // Using the new configure method
        }

        return cell
    }
    
    
    /**
     Handles the selection event of a cell in the collection view. This function is called when a user taps on a cell.
     
     - Parameters:
        - collectionView: The collection view where the selection occurred.
        - indexPath: An index path locating the selected item in the collection view.
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // when the user tap on one of the collection
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

