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


enum Period {
    case day
    case week
    case month
}

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HamburgerViewControllerDelegate, UIGestureRecognizerDelegate, TOCropViewControllerDelegate {
    
    private var hobbyColors: [String: UIColor] = [:]
    
    @IBOutlet weak var postCollectionView: UICollectionView!
    
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var currentUser: FirebaseAuth.User?
    var currentUserList: UserList?
    var userProfile: UserProfile?
    var isCurrentUser: Bool = true
    var userEmail: String?

    var imageUrls: [String] = []
    
    private var isHamburgerMenuShown: Bool = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hamburgerView.isHidden = true
        self.currentUser = UserManager.shared.currentUser
        self.currentUserList = UserManager.shared.currentUserList

        hamburgerViewController?.currentUser = self.currentUser
        setupUI()

        self.backViewForHamburger.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profilePictureView.isUserInteractionEnabled = isCurrentUser
        profilePictureView.addGestureRecognizer(tapGesture)
//        profilePictureView.isUserInteractionEnabled = true
        
        configureProfileImageView()
        addUploadHintImage()
        
        if isCurrentUser {
            Task {
                await loadUserData()
            }
        }
        
        _ = setProfilePicture()
        
        customBarChartView.setupChart()
        loadUserSettings()
        loadDailyData()

        setupCollectionView()
        updateFollowersFollowingLabels()

        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        postCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        if let userID = currentUser?.uid {
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
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    @IBAction func followButton(_ sender: Any) {
        guard let viewedUserID = userProfile?.userID,
                  let currentUserID = currentUser?.uid,
                  viewedUserID != currentUserID else {
                print("Cannot follow oneself or invalid user state")
                return
            }

            // References to the followings subcollection of the current user and the followers subcollection of the viewed user
            let currentUserFollowingRef = usersReference.document(currentUserID).collection("following").document(viewedUserID)
            let viewedUserFollowersRef = usersReference.document(viewedUserID).collection("followers").document(currentUserID)

            // Check if the current user is already following the viewed user
            currentUserFollowingRef.getDocument { [weak self] documentSnapshot, error in
                if let document = documentSnapshot, document.exists {
                    print("Already following this user.")
                } else {
                    // Not following yet, proceed to follow
                    let batch = Firestore.firestore().batch()
                    batch.setData([:], forDocument: currentUserFollowingRef)
                    batch.setData([:], forDocument: viewedUserFollowersRef)

                    batch.commit { err in
                        if let err = err {
                            print("Error following user: \(err)")
                        } else {
                            print("User followed successfully")
                            DispatchQueue.main.async {
                                self?.updateFollowersFollowingLabels()
                            }
                        }
                    }
                }
            }
        guard let viewedUserID = userProfile?.userID,
                  let currentUserID = currentUser?.uid,
                  viewedUserID != currentUserID else {
                print("Cannot follow oneself or invalid user state")
                return
            }

            let viewedUserRef = usersReference.document(viewedUserID)
            let currentUserRef = usersReference.document(currentUserID)
          
            let db = Firestore.firestore()
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let viewedUserDocument: DocumentSnapshot
                let currentUserDocument: DocumentSnapshot
                do {
                    try viewedUserDocument = transaction.getDocument(viewedUserRef)
                    try currentUserDocument = transaction.getDocument(currentUserRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                let currentViewedUserFollowers = viewedUserDocument.data()?["followers"] as? Int ?? 0
                let currentUserFollowing = currentUserDocument.data()?["following"] as? Int ?? 0

                transaction.updateData(["followers": currentViewedUserFollowers + 1], forDocument: viewedUserRef)
                transaction.updateData(["following": currentUserFollowing + 1], forDocument: currentUserRef)
                return nil

                
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    print("Transaction successfully committed!")
                    DispatchQueue.main.async {
                        self.updateFollowersFollowingLabels()
                    }
                }
            }
    }
    
//    func updateFollowersFollowingLabels() {
//        guard let currentUserID = currentUser?.uid else { return }
//        
//        if isCurrentUser {
//            let currentUserRef = usersReference.document(currentUserID)
//            currentUserRef.getDocument { [weak self] (document, error) in
//                guard let self = self, let document = document, document.exists else { return }
//                if let currentUserData = document.data() {
//                    DispatchQueue.main.async {
//                        if let followingCount = currentUserData["following"] as? Int {
//                            self.followingLabel.text = "\(followingCount)"
//                        }
//                        if let followersCount = currentUserData["followers"] as? Int {
//                            self.followersLabel.text = "\(followersCount)"
//                        }
//                    }
//                }
//            }
//        }
//        
//        if !isCurrentUser {
//            if let viewedUserID = userProfile?.userID, viewedUserID != currentUserID {
//                let viewedUserRef = usersReference.document(viewedUserID)
//                viewedUserRef.getDocument { [weak self] (document, error) in
//                    if let document = document, document.exists {
//                        if let viewedUserData = document.data() {
//                            DispatchQueue.main.async {
//                                if let followersCount = viewedUserData["followers"] as? Int {
//                                    self?.followersLabel.text = "\(followersCount)"
//                                }
//                                if let followingCount = viewedUserData["following"] as? Int {
//                                    self?.followingLabel.text = "\(followingCount)"
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//    }
    
    func updateFollowersFollowingLabels() {
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
    
    func setProfilePicture() -> UIImage {
        return self.profilePictureView.image ?? UIImage(named: "default_picture")!
    }

    func setName() -> String {
        return self.displayNameLabel.text ?? "Unknown"
    }

    private func setupUI() {
        view.backgroundColor = .white

        hamburgerMenu.isHidden = !isCurrentUser
        goalsMenu.isHidden = !isCurrentUser
        hobbyButton.isHidden = !isCurrentUser

        followButton.isHidden = isCurrentUser
    }
    
    
    func editProfile() {
        self.performSegue(withIdentifier: "editProfileSegue", sender: self)
        setupEditProfile()
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
    
    func setupEditProfile() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let storageURL = document.data()?["storageURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: storageURL), completed: nil)
                }
                if let userData = document.data() {
                    UserManager.shared.userData = userData
                    if let displayName = userData["displayName"] as? String {
                        self?.displayNameLabel.text = displayName
                        
                    }
                }
            } else {
                print("Document does not exist or error occurred: \(String(describing: error))")
            }
        }
    }
    
    func setupProfile(for userID: String) {
        if isCurrentUser {
            loadCurrentUserProfile()
        } else {
            print(userID)
            loadUserProfile(for: userID)
        }
    }


    private func loadCurrentUserProfile() {
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
                self.updateUI(with: userProfile)
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
    
    
    
    
    private func loadUserProfile(for userID: String) {
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else {
                print("Document does not exist or error occurred: \(error?.localizedDescription ?? "No error")")
                return
            }

            do {
                guard let userProfile = self.userProfile else {
                    return
                }
                
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



    func updateUI(with userProfile: UserProfile) {
        DispatchQueue.main.async {
            self.displayNameLabel.text = userProfile.displayName
            if let url = URL(string: userProfile.storageURL) {
                self.profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultProfile"))
            }
            self.updateChartData()
        }
    }
    
    
    func resetUI() {
        displayNameLabel.text = ""
        profilePictureView.image = UIImage(named: "defaultProfile")
        imageUrls.removeAll()
        postCollectionView.reloadData()
    }
    
    func resolveHobbies(hobbyReferences: [DocumentReference], completion: @escaping ([Hobby]) -> Void) {
        var hobbies: [Hobby] = []
        let group = DispatchGroup()

        for reference in hobbyReferences {
            group.enter()
            reference.getDocument { (documentSnapshot, error) in
                if let document = documentSnapshot, document.exists {
                    do {
                        let hobby = try document.data(as: Hobby.self)
                        hobbies.append(hobby)
                    } catch let error {
                        print("Error decoding hobby: \(error)")
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(hobbies)
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
        hamburgerView.isHidden = false
        hamburgerViewController?.setupPicture()
        hamburgerViewController?.setName()
        
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
      
        profilePictureView.contentMode = .scaleAspectFill
        
        profilePictureView.layer.borderWidth = 0.5
        profilePictureView.layer.borderColor = UIColor.black.cgColor
        
        if profilePictureView.image == nil {
            profilePictureView.image = UIImage(named: "default_picture")
        }
    }
    
    private func addUploadHintImage() {
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
//        let filename = "profile/\(UUID().uuidString).jpg"  // Ensure unique file names within the profile folder
        let filename = "profile/profile_picture.jpg"

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            displayMessage(title: "Error", message: "Image data could not be compressed")
            return
        }

        guard let userID = self.currentUser?.uid else {
            displayMessage(title: "Error", message: "No user logged in!")
            return
        }

        let imageRef = storageReference.child("\(userID)/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadTask = imageRef.putData(data, metadata: metadata)
        
        imageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                self.displayMessage(title: "Error", message: "Failed to upload image: \(error.localizedDescription)")
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
    
    
    func setupProfilePicture() {
        print("setupProfilePicture")
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let storageURL = document.data()?["storageURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: storageURL), completed: nil)
                }
                if let userData = document.data() {
                    UserManager.shared.userData = userData
                    if let displayName = userData["displayName"] as? String {
                        self?.displayNameLabel.text = displayName
                    }
                }
            } else {
                print("Document does not exist or error occurred: \(String(describing: error))")
            }
        }
    }

    
    
    // ---------------------------------------- Chart -----------------------------------------------------
    
    
    func updateChartData() {
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
    
    func loadDailyData() {
        fetchData(for: .day) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    func loadWeeklyData() {
        fetchData(for: .weekOfYear) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    func loadMonthlyData() {
        fetchData(for: .month) { dataEntries, hobbies in
            self.updateChart(with: dataEntries, hobbies: hobbies)
        }
    }

    
    func updateChart(with dataEntries: [BarChartDataEntry], hobbies: [String: Double]) {
        let sortedHobbies = hobbies.keys.sorted()

        initializeHobbyColors(hobbies: sortedHobbies)

        let sortedDataEntries = dataEntries.sorted {
            let hobby1 = Array(hobbies.keys)[Int($0.x)]
            let hobby2 = Array(hobbies.keys)[Int($1.x)]
            return hobby1 < hobby2
        }

        let dataSet = BarChartDataSet(entries: sortedDataEntries, label: "Hobbies")
        dataSet.colors = sortedDataEntries.map { entry in
            let hobbyIndex = Int(entry.x)
            let hobby = sortedHobbies[hobbyIndex]
            return hobbyColors[hobby] ?? .black
        }

        let data = BarChartData(dataSets: [dataSet])
        customBarChartView.data = data
        customBarChartView.legend.setCustom(entries: createLegendEntries(hobbies: hobbies, sortedKeys: sortedHobbies))
        customBarChartView.notifyDataSetChanged() // Refresh the chart
    }

    
    private func fetchData(for period: Calendar.Component, completion: @escaping ([BarChartDataEntry], [String: Double]) -> Void) {
        print("fetchData")
        guard let userID = isCurrentUser ? currentUser?.uid : userProfile?.userID else {
            print("No user ID available")
            completion([], [:])
            return
        }
        
        print("userprofile = \(userProfile)")
        guard let hobbiesList = (isCurrentUser ? currentUserList?.hobbies : userProfile?.userHobby) else {
            print("No hobbies list available")
            completion([], [:])
            return
        }
            
        var hobbyDurations = [String: Double]()
        for hobby in hobbiesList {
            hobbyDurations[hobby.name ?? ""] = 0.0
        }
        
        let db = Firestore.firestore()
        db.collection("posts").whereField("userID", isEqualTo: userID).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                completion([], hobbyDurations)
                return
            }
            
            let calendar = Calendar.current
            let now = Date()
            
            for document in documents {
                if let postDate = (document.data()["postDate"] as? Timestamp)?.dateValue(),
                   let hobbyName = document.data()["hobby"] as? String,
                   let duration = document.data()["duration"] as? Double,
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
                        hobbyDurations[hobbyName]! += duration
                    }
                }
            }
            
            let dataEntries = hobbyDurations.compactMap { (hobby, duration) -> BarChartDataEntry? in
                if let index = hobbiesList.firstIndex(where: {$0.name == hobby}) {
                    let visualValue = max(0.1, duration) // Ensure a minimum height of 0.5 for visual effect
                    let entry = BarChartDataEntry(x: Double(index), y: visualValue)
                    entry.data = Int(duration) as AnyObject
                    return entry
                }
                return nil
            }.sorted(by: {$0.x < $1.x})
            
            completion(dataEntries, hobbyDurations)
        }
    }

    
    private func initializeHobbyColors(hobbies: [String]) {
        loadUserSettings()
        let colors = generateDistinctColors()
        var colorIndex = 0
        for hobby in hobbies {
            if hobbyColors[hobby] == nil {
                hobbyColors[hobby] = colors[colorIndex % colors.count]
                colorIndex += 1
            }
        }
        saveUserSettings()
    }
    
//    private func generateUniqueColor() -> UIColor {
//        return UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)
//    }
//    

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
    
    
    // Helper function to convert from UIColor to Data
    func colorToData(color: UIColor) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            return data
        } catch {
            print("Error converting color to data: \(error)")
            return nil
        }
    }

    // Helper function to convert from Data to UIColor
    func dataToColor(data: Data) -> UIColor? {
        do {
            if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return color
            }
        } catch {
            print("Error converting data to color: \(error)")
        }
        return nil
    }
    
    func loadUserSettings() {
        let userDefaults = UserDefaults.standard
        if let storedHobbyColors = userDefaults.object(forKey: "HobbyColors") as? [String: Data] {
            hobbyColors = storedHobbyColors.compactMapValues { dataToColor(data: $0) }
        }
    
    }

    func saveUserSettings() {
        let userDefaults = UserDefaults.standard
        let storedHobbyColors = hobbyColors.compactMapValues { colorToData(color: $0) }
        userDefaults.set(storedHobbyColors, forKey: "HobbyColors")
    }
    
    
    private func generateDistinctColors() -> [UIColor] {
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
    
    // ==============================================================================
    
    func loadUserData() async{
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
    
    func loadProfileImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_picture"), options: .continueInBackground, completed: nil)
    }
    
    
    func fetchImagesURL(userID: String, completion: @escaping ([String]) -> Void) {
        let postsRef = Firestore.firestore().collection("posts").whereField("userID", isEqualTo: userID)
        postsRef.getDocuments { (snapshot, error) in
            var imageUrls: [String] = []
            if let error = error {
                print("Error fetching posts: \(error)")
                completion([])
            } else {
                for document in snapshot!.documents {
                    if let imageUrl = document.data()["imageUrl"] as? String {
                        imageUrls.append(imageUrl)
                    } else {
                        print("Document \(document.documentID) does not contain a valid 'imageUrl'")
                    }
                }
                completion(imageUrls)
            }
        }
    }
    
    func fetchPostCount(for userID: String) {
        let postsRef = Firestore.firestore().collection("posts").whereField("userID", isEqualTo: userID)
        postsRef.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching posts: \(error)")
                self.totalPostsLabel.text = "0"  // Show 0 in case of error
            } else if let snapshot = querySnapshot {
                let count = snapshot.documents.count
                self.totalPostsLabel.text = "\(count)"
            }
        }
    }
}


extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("Unable to dequeue PhotoCollectionViewCell")
        }

        if indexPath.row < imageUrls.count, let imageUrl = URL(string: imageUrls[indexPath.row]) {
            cell.configure(with: imageUrl) // Using the new configure method
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // when the user tap on one of the collection
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

