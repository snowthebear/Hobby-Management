//
//  HamburgerViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 06/05/24.
//

import UIKit
import FirebaseAuth

protocol HamburgerViewControllerDelegate {
    func hideHamburgerMenu()
    func editProfile()
    func logout()
    func setProfilePicture() -> UIImage
    func setName() -> String
}
 
class HamburgerViewController: UIViewController {
    var delegate: HamburgerViewControllerDelegate?
    
    var currentUser:FirebaseAuth.User?

    @IBOutlet weak var mainBackgroundView: UIView!
    
    @IBOutlet weak var downView: UIView!
    
    
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBAction func logoutButton(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Logout", message:  "Are you sure you want to log out?",  preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            self.delegate?.logout()
        }))
        
        present(alert, animated: true)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupHamburgerUI()
        self.topView.isHidden = false
        self.downView.isHidden = false
        self.configureProfileImageView()

    }

    
    private func setupHamburgerUI(){
        self.mainBackgroundView.clipsToBounds = true
        
//        self.profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
//        self.profileImageView.clipsToBounds = true
//        
//        self.profileImageView.contentMode = .scaleAspectFill
//        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPicture()
        configureProfileImageView()
        setName()
        
    }
    
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

    
    @IBAction func editProfileButton(_ sender: Any) {
        self.delegate?.hideHamburgerMenu()
        self.delegate?.editProfile()
    }
    
    func setupPicture(){
        self.profileImageView.image = self.delegate?.setProfilePicture()
    }
    
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
