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
    
//    private var collectionView: UICollectionView?
    
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    var usersReference = Firestore.firestore().collection("users")
    var storageReference = Storage.storage().reference()
    
    var currentUser: FirebaseAuth.User?
    var currentUserList: UserList?
    var userEmail: String?
//    var name: String?
    
    var imageUrls: [String] = []
    
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
        
        self.currentUser = UserManager.shared.currentUser
        self.currentUserList = UserManager.shared.currentUserList

        hamburgerViewController?.currentUser = self.currentUser
        setupUI()

        self.backViewForHamburger.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profilePictureView.addGestureRecognizer(tapGesture)
        profilePictureView.isUserInteractionEnabled = true
        configureProfileImageView()
        addUploadHintImage()
        setupProfile()
        setProfilePicture()

        customBarChartView.setupChart()
        loadUserSettings()
        loadDailyData()

        setupCollectionView()
        Task {
            await loadUserData()
        }
        
        postCollectionView.delegate = self
        postCollectionView.dataSource = self
        postCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        if let userID = currentUser?.uid {
            fetchImagesURL(userID: userID) { [weak self] fetchedUrls in
                self?.imageUrls = fetchedUrls
                DispatchQueue.main.async {
                    self?.postCollectionView.reloadData()
                }
            }
        } else {
            print("Current user ID is nil.")
        }
        
//        updateChartData()
        
        
        
        
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
        
        if let userID = currentUser?.uid {
            fetchImagesURL(userID: userID) { [weak self] fetchedUrls in
                self?.imageUrls = fetchedUrls
                DispatchQueue.main.async {
                    self?.postCollectionView.reloadData()
                }
            }
        } else {
            print("Current user ID is nil.")
        }
        
        loadDailyData()

        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.backViewForHamburger.isHidden = true
//        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        if self.isHamburgerMenuShown {
            self.hideHamburgerMenu()
        }
        progressSegmentedControl.selectedSegmentIndex = 0
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        postCollectionView.frame = view.bounds
        let allPostsLabelHeight = allPostsLabel.frame.size.height + 5
        let yOffset = allPostsLabel.frame.origin.y + allPostsLabelHeight
        
        let tabBarHeight = (tabBarController?.tabBar.frame.size.height ?? 0) + 5
        
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
//        postCollectionView.backgroundColor = .blue
        
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
                        "storageURL": downloadURL.absoluteString,
                    ], merge: true)
                }
            }
        }

        cropViewController.dismiss(animated: true, completion: nil)
        
        

//        uploadTask.observe(.success) { [weak self] snapshot in
//            imageRef.downloadURL { (url, error) in
//                if let downloadURL = url {
//                    self?.usersReference.document(userID).setData(["storageURL": downloadURL.absoluteString], merge: true)
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
//                    self?.usersReference.document(userID).setData(["storageURL": downloadURL.absoluteString], merge: true)
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
//    
//    func updateChart(with dataEntries: [BarChartDataEntry], hobbies: [String: Double]) {
//        // Sort the hobbies keys to maintain the order
//        let sortedHobbies = hobbies.keys.sorted()
//
//        // Assign colors to the hobbies
//        for hobby in sortedHobbies where hobbyColors[hobby] == nil {
//            hobbyColors[hobby] = generateUniqueColor(for: hobby)
//        }
//
//        // Create chart data entries and ensure they are sorted
//        let sortedDataEntries = dataEntries.sorted {
//            let hobby1 = Array(hobbies.keys)[Int($0.x)]
//            let hobby2 = Array(hobbies.keys)[Int($1.x)]
//            return hobby1 < hobby2
//        }
//
//        let dataSet = BarChartDataSet(entries: sortedDataEntries, label: "Hobbies")
//        dataSet.colors = sortedDataEntries.map { entry in
//            let hobbyIndex = Int(entry.x)
//            let hobby = sortedHobbies[hobbyIndex]
//            return hobbyColors[hobby] ?? .black
//        }
//
//        let data = BarChartData(dataSets: [dataSet])
//        customBarChartView.data = data
//        let entries = createLegendEntries(hobbies: hobbies, sortedKeys: sortedHobbies)
//        customBarChartView.legend.setCustom(entries: entries)
//        customBarChartView.notifyDataSetChanged() // Refresh the chart
//    }
    
    
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

    
    
//    func updateChart(with dataEntries: [BarChartDataEntry], hobbies: [String: Double]) {
//        for hobby in hobbies.keys where hobbyColors[hobby] == nil {
//            hobbyColors[hobby] = generateUniqueColor()
//        }
//
//        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
//        dataSet.colors = dataEntries.map { entry in
//            let hobbyIndex = Int(entry.x)
//            let hobby = Array(hobbies.keys)[hobbyIndex]
//            return hobbyColors[hobby] ?? .black
//        }
//
//        let data = BarChartData(dataSets: [dataSet])
//        customBarChartView.data = data
//        customBarChartView.legend.setCustom(entries: createLegendEntries(hobbies: hobbies))
//        customBarChartView.notifyDataSetChanged() // Refresh chart
//    }
    
    
    private func fetchData(for period: Calendar.Component, completion: @escaping ([BarChartDataEntry], [String: Double]) -> Void) {
        guard let userID = currentUser?.uid, let hobbiesList = currentUserList?.hobbies else {
            print("No user or hobbies available")
            completion([], [:])
            return
        }
        
        // Initialize all hobbies with zero duration
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
                   let hobby = document.data()["hobby"] as? String,
                   let duration = document.data()["duration"] as? Double {
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
                        hobbyDurations[hobby] = (hobbyDurations[hobby] ?? 0.0) + duration
                    }
                }
            }

            let sortedHobbies = hobbyDurations.keys.sorted()
            let dataEntries = sortedHobbies.enumerated().map { index, hobby in
                BarChartDataEntry(x: Double(index), y: hobbyDurations[hobby] ?? 0.0)
            }
            
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
    
    private func generateUniqueColor() -> UIColor {
        return UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)
    }


//    private func generateUniqueColor(for hobby: String) -> UIColor {
//        var total: Int = 0
//        for character in hobby.utf8 {
//            total += Int(character)
//        }
//        srand48(total * 200)
//
//        return UIColor(hue: CGFloat(drand48()), saturation: 0.5, brightness: 0.9, alpha: 1)
//    }

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
    
    
    // Helper function to convert UIColor to Data
    func colorToData(color: UIColor) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            return data
        } catch {
            print("Error converting color to data: \(error)")
            return nil
        }
    }

    // Helper function to convert Data back to UIColor
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
//                if let profileImageUrl = data?["storageURL"] as? String {
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
                print("Fetched image URLs: \(imageUrls)")  // Check the fetched URLs.
                completion(imageUrls)
            }
        }
    }
    
//    func fetchImagesURL(userID: String, completion: @escaping ([String]) -> Void) {
//        let postsRef = usersReference.document(userID).collection("posts")
//        postsRef.getDocuments { (snapshot, error) in
//            var imageUrls: [String] = []
//            if let error = error {
//                print("Error fetching posts: \(error)")
//                completion([])
//            } else {
//                for document in snapshot!.documents {
//                    if let imageUrl = document.data()["url"] as? String {
//                        imageUrls.append(imageUrl)
//                    }
//                }
//                completion(imageUrls)
//            }
//        }
//    }
    
}


extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        return UICollectionViewCell()
//        let cell = postCollectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
//        
//        cell.backgroundColor = .systemCyan
//        return cell
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

