//
//  ProfileViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import UIKit
import Charts
import FirebaseAuth

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HamburgerViewControllerDelegate {

    

    
    var hamburgerViewController: HamburgerViewController? //initialize the delegate
    
    var currentUser: FirebaseAuth.User?
    var userEmail: String?
    

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
    
    func hideHamburgerMenu() {
        self.hideHamburgerView()
    }
    
    private func hideHamburgerView(){
        UIView.animate(withDuration: 0.3) {
                self.leadingConstraintForHM.constant = -280  // Adjust depending on your layout
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.backViewForHamburger.isHidden = true
            }
    }
    
    @IBAction func tappedOnHamburgerBackView(_ sender: Any) {
        self.hideHamburgerView()
//        self.backViewForHamburger.isHidden = !self.backViewForHamburger.isHidden

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.tabBarController?.navigationItem.hidesBackButton = true
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
//        self.backViewForHamburger.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.backViewForHamburger.isHidden = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        customBarChartView.setupChart()
        loadDailyData()
        
        self.backViewForHamburger.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        profilePictureView.addGestureRecognizer(tapGesture)
        profilePictureView.isUserInteractionEnabled = true
        configureProfileImageView()
        addUploadHintImage()
        print ("user = \(UserManager.shared.currentUser)")
        self.currentUser = UserManager.shared.currentUser
        
        print ("profile user = \(self.currentUser)")
        
    }
    
    @IBAction func showHamburgerMenu(_ sender: Any) {
        self.backViewForHamburger.isHidden = !self.backViewForHamburger.isHidden
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
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true)
        if let pickedImage = info[.editedImage] as? UIImage {
            profilePictureView.image = pickedImage
        }
    }
    

    private func setupUI() {
        view.backgroundColor = .white
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
    
    private func configureProfileImageView() {
        // Make the image view circular
        profilePictureView.layer.cornerRadius = profilePictureView.frame.size.width / 2
        profilePictureView.clipsToBounds = true
        
        // Set content mode to ScaleAspectFill
        profilePictureView.contentMode = .scaleAspectFill
        
        profilePictureView.layer.borderWidth = 0.5
        profilePictureView.layer.borderColor = UIColor.black.cgColor
        
        if profilePictureView.image == nil {
            profilePictureView.image = UIImage(named: "defaultProfile")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "hamburgerSegue") {
            if let controller = segue.destination as? HamburgerViewController {
                self.hamburgerViewController = controller
                self.hamburgerViewController?.delegate = self
            }
        }
    }

}
