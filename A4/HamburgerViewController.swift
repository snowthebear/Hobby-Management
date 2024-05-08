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
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("user = \(self.currentUser)")
        self.setupHamburgerUI()
        self.topView.isHidden = false
        self.downView.isHidden = false
        print("view hamburger")
        // Do any additional setup after loading the view.
    }
    
    private func setupHamburgerUI(){
        print("setup hamburger")
        self.mainBackgroundView.clipsToBounds = true
        
//        self.profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
//        self.profileImageView.clipsToBounds = true
//        
//        self.profileImageView.contentMode = .scaleAspectFill
//        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCircularProfileImage()
        print("disinita")
    }

    private func setupCircularProfileImage() {
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        
        self.profileImageView.contentMode = .scaleAspectFill
        
//        if self.profileImageView.image == nil{
//            profileImageView.image = UIImage(named: "default_picture")
//        }
    }
    
    @IBAction func editProfileButtonn(_ sender: Any) {
        self.delegate?.hideHamburgerMenu()
        performSegue(withIdentifier: "editProfileSegue", sender: self)
    }
    



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        print("self user = \(self.currentUser)")
        if segue.identifier == "editProfileSegue" {
            if let destination = segue.destination as? EditProfileViewController {
                destination.modalPresentationStyle = .fullScreen
                destination.currentUser = self.currentUser
//                self.hamburgerViewController = controller
//                self.hamburgerViewController?.delegate = self
            }
        }
    }


}
