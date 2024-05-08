//
//  HamburgerViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 06/05/24.
//

import UIKit

protocol HamburgerViewControllerDelegate {
    func hideHamburgerMenu()
}
 
class HamburgerViewController: UIViewController {
    var delegate: HamburgerViewControllerDelegate?

    @IBOutlet weak var mainBackgroundView: UIView!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    

    
    @IBAction func logoutButton(_ sender: Any) {
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupHamburgerUI()

        // Do any additional setup after loading the view.
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
        setupCircularProfileImage()
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
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
