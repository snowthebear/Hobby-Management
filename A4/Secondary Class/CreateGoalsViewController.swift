//
//  CreateGoalsViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit

class CreateGoalsViewController: UIViewController {
    
    @IBOutlet weak var goalsTextField: UITextField!
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        guard let goals = goalsTextField.text else {
            return
        }

        if goals.isEmpty {
            var errorMsg = "Please Enter Your Goals:\n"
            
            displayMessage(title: "Goals Field Empty!", message: errorMsg)
            return
        }

        let _ = databaseController?.addGoals(goal: goals)

        navigationController?.popViewController(animated: true)
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
