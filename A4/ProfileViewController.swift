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
    
    @IBOutlet weak var postCollectionView: UICollectionView!
    
//    private var collectionView: UICollectionView?
    
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var currentUser: FirebaseAuth.User?
    var currentUserLisr: UserList?
    var userEmail: String?
//    var name: String?
    
    private var isHamburgerMenuShown: Bool = false
    
    
    @IBOutlet weak var leadingConstraintForHM: NSLayoutConstraint!
    
    @IBOutlet weak var hamburgerView: UIView!
    @IBOutlet weak var backViewForHamburger: UIView!
    
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
        setupProfile()
        setProfilePicture()
        
        self.currentUser = UserManager.shared.currentUser
        self.currentUserLisr = UserManager.shared.currentUserList

        setupCollectionView()
        Task {
            await loadUserData()
        }
        
        
        
//        // for feed:
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        layout.minimumLineSpacing = 1
//        layout.minimumInteritemSpacing = 1
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        let size = (360 - 4) / 3
//        layout.itemSize = CGSize(width: size, height: size)
//        postCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//                
//        // for cell
//        postCollectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier )
//        
//        postCollectionView?.backgroundColor = .blue
//        
//        postCollectionView?.delegate = self
//        postCollectionView?.dataSource = self
//        
//        guard let collectionView = postCollectionView else {
//            return
//        }
//        view.addSubview(postCollectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("c")
        
        super.viewWillAppear(animated)
        self.backViewForHamburger.isHidden = true
//        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        if self.isHamburgerMenuShown {
            self.hideHamburgerMenu()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        postCollectionView.frame = view.bounds
        let allPostsLabelHeight = allPostsLabel.frame.size.height + 5
        let yOffset = allPostsLabel.frame.origin.y + allPostsLabelHeight
        
        let tabBarHeight = (tabBarController?.tabBar.frame.size.height)! + 5
        
        // Adjust the height of the collection view to take up the remaining space
        let collectionViewHeight = view.bounds.height - yOffset - tabBarHeight
        
        postCollectionView.frame = CGRect(x: 0, y: yOffset, width: view.bounds.width, height: collectionViewHeight)
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
        postCollectionView.backgroundColor = .blue
        
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
    }
    
    
    func editProfile() {
        self.performSegue(withIdentifier: "editProfileSegue", sender: self)
        print("cc")
        setupProfile()
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
    
    func setupProfile() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let profilePictureURL = document.data()?["profilePictureURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: profilePictureURL), completed: nil)
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
                        "profilePictureURL": downloadURL.absoluteString,
                    ], merge: true)
                }
            }
        }

        cropViewController.dismiss(animated: true, completion: nil)
        
        

//        uploadTask.observe(.success) { [weak self] snapshot in
//            imageRef.downloadURL { (url, error) in
//                if let downloadURL = url {
//                    self?.usersReference.document(userID).setData(["profilePictureURL": downloadURL.absoluteString], merge: true)
//                }
//            }
//        }
//
//        uploadTask.observe(.failure) { snapshot in
//            self.displayMessage(title: "Error", message: "Failed to upload image")
//        }
//
//        cropViewController.dismiss(animated: true, completion: nil)
        //--------------------------
        
//        profilePictureView.image = image
//        
//        let timestamp = UInt(Date().timeIntervalSince1970)
//        let filename = "\(timestamp).jpg"
//        
//        guard let data = image.jpegData(compressionQuality: 0.8) else {
//            displayMessage(title: "Error", message: "Image data could not be compressed")
//            return
//        }
//        
//        guard let userID = self.currentUser?.uid else {
//            displayMessage(title: "Error", message: "No user logged in!")
//            return
//        }
//        
//        let imageRef = storageReference.child("\(userID)/\(timestamp)")
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpg"
//        
//        let uploadTask = imageRef.putData(data, metadata: metadata)
//        
//        uploadTask.observe(.success) { [weak self] snapshot in
//            imageRef.downloadURL { (url, error) in
//                if let downloadURL = url {
//                    self?.usersReference.document(userID).setData(["profilePictureURL": downloadURL.absoluteString], merge: true)
//                }
//            }
//        }
//        
//        uploadTask.observe(.failure) { snapshot in
//            self.displayMessage(title: "Error", message: "\(String(describing: snapshot.error))")
//        }
//
//        _ = setProfilePicture()
//        cropViewController.dismiss(animated: true, completion: nil)
//        
    }
    
    func setupProfilePicture() {
        print("setupprofile")
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        usersReference.document(userID).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let profilePictureURL = document.data()?["profilePictureURL"] as? String {
                    self?.profilePictureView.sd_setImage(with: URL(string: profilePictureURL), completed: nil)
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
                destination.displayName = self.displayNameLabel.text
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
    
    func loadUserData() async{
        print("haga")
        guard let user = currentUser else { return }
        
        let userDocRef = usersReference.document(user.uid)
            do {
                let document = try await userDocRef.getDocument()
                if let data = document.data() {
                    DispatchQueue.main.async { [weak self] in
                        self?.displayNameLabel.text = data["displayName"] as? String
                        if let profileImageUrl = data["profilePictureURL"] as? String {
                            self?.loadProfileImage(urlString: profileImageUrl)
                        }
                    }
                }
            } catch {
                print("Error fetching document: \(error.localizedDescription)")
            }
        
        // Set email
//        self.displayNameLabel.text = user.displayName
        
//        // Fetch and set the display name and profile image from Firestore
//        let userDocRef = usersReference.document(user.uid)
//        userDocRef.getDocument { [weak self] (document, error) in
//            guard let self = self else { return }
//            if let document = document, document.exists {
//                let data = document.data()
//                self.displayNameLabel.text = data?["displayName"] as? String
//                
//                if let profileImageUrl = data?["profilePictureURL"] as? String {
//                    self.loadProfileImage(urlString: profileImageUrl)
//                }
//            } else {
//                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
//            }
//        }
    }
    
    func loadProfileImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        profilePictureView.sd_setImage(with: url, placeholderImage: UIImage(named: "default_picture"), options: .continueInBackground, completed: nil)
    }
    
    func fetchImagesURL(userID: String, completion: @escaping ([String]) -> Void) {
        let postsRef = usersReference.document(userID).collection("posts")
        postsRef.getDocuments { (snapshot, error) in
            var imageUrls: [String] = []
            if let error = error {
                print("Error fetching posts: \(error)")
                completion([])
            } else {
                for document in snapshot!.documents {
                    if let imageUrl = document.data()["url"] as? String {
                        imageUrls.append(imageUrl)
                    }
                }
                completion(imageUrls)
            }
        }
    }
    
}


extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return UICollectionViewCell()
//        let cell = postCollectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
//        
//        cell.backgroundColor = .systemCyan
//        return cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell

            fetchImagesURL(userID: currentUser?.uid ?? "") { imageUrls in
                if indexPath.row < imageUrls.count {
                    let imageUrl = imageUrls[indexPath.row]
                    DispatchQueue.main.async {
                        self.profilePictureView.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "placeholder"))
                    }
                }
            }

            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // when the user tap on one of the collection
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        
//        guard kind == UICollectionView.elementKindSectionHeader else {
//            // return footer
//            return UICollectionReusableView()
//        }
//        
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileHeaderCollectionReusableView.identifier, for: indexPath) as! ProfileHeaderCollectionReusableView
//        
//        return header
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        if section == 0 {
//            return CGSize(width: collectionView.width, height: collectionView.height/3)
//        }
//        
//        return .zero
//    }
//    
}

