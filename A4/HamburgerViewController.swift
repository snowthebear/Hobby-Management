//
//  HamburgerViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 06/05/24.
//

import UIKit
import FirebaseAuth

// reference : https://www.youtube.com/watch?v=L6zB8xABwjs

/**
 Protocol for handling actions from the HamburgerViewController.
 */
protocol HamburgerViewControllerDelegate {
    func hideHamburgerMenu()
    func editProfile()
    func logout()
    func setProfilePicture() -> UIImage
    func setName() -> String
}
 
/**
 `HamburgerViewController` manages the display and actions within a hamburger menu,
 providing options to edit the profile, logout, and display user information.
 */
class HamburgerViewController: UIViewController {
    var delegate: HamburgerViewControllerDelegate?
    
    var currentUser:FirebaseAuth.User?

    @IBOutlet weak var mainBackgroundView: UIView!
    
    @IBOutlet weak var downView: UIView!
    
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    /**
     Called after the controller's view is loaded into memory.
     Sets up the UI and initializes the profile information.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupHamburgerUI()
        self.topView.isHidden = false
        self.downView.isHidden = false
        self.configureProfileImageView()
        setName()
        setupPicture()

    }
    
    /**
     Handles the logout button action.
     Displays a confirmation alert before logging out.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func logoutButton(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Logout", message:  "Are you sure you want to log out?",  preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            self.delegate?.logout()
        }))
        
        present(alert, animated: true)
    }
    
    /**
     Called to notify the view controller that its view has just laid out its subviews.
     Ensures the profile picture and name are set correctly.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPicture()
        configureProfileImageView()
        setName()
    }
    
    /**
     Sets up the UI elements of the hamburger menu.
     */
    private func setupHamburgerUI(){
        self.mainBackgroundView.clipsToBounds = true
        
    }
   
    /**
     Configures the profile image view to be circular and sets its content mode.
     */
    private func configureProfileImageView() {
        // Make the image view circular
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        
        // Set content mode to ScaleAspectFill
        profileImageView.contentMode = .scaleAspectFill
        
        if profileImageView.image == nil {
            profileImageView.image = UIImage(named: "default_picture")
        }
    }

    /**
     Handles the edit profile button action.
     Hides the hamburger menu and initiates the edit profile process.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func editProfileButton(_ sender: Any) {
        self.delegate?.hideHamburgerMenu()
        self.delegate?.editProfile()
    }
    
    /**
     Sets up the profile picture by fetching it from the delegate.
     */
    func setupPicture(){
        self.profileImageView.image = self.delegate?.setProfilePicture()
    }
    
    /**
     Sets the user's name by fetching it from the delegate.
     */
    func setName(){
        self.nameLabel.text = self.delegate?.setName()
    }
    



//    // MARK: - Navigation
//
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//        print("self user = \(self.currentUser)")
//        if segue.identifier == "editProfileSegue" {
//            if let destination = segue.destination as? EditProfileViewController {
//                destination.modalPresentationStyle = .fullScreen
//                destination.currentUser = self.currentUser
////                self.hamburgerViewController = controller
////                self.hamburgerViewController?.delegate = self
//            }
//        }
//    }


}
