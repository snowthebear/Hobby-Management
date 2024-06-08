//
//  CreateGoalsViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit


/**
 CreateGoalsViewController  provides an interface for users to create new goals.
 It includes a text field for entering the goal and a save button to add the goal to the database.
 */
class CreateGoalsViewController: UIViewController {
    
    @IBOutlet weak var goalsTextField: UITextField!
    
    weak var databaseController: DatabaseProtocol? // Reference to the database controller for database operations
    
    /**
     Called after the controller's view is loaded into memory.
     Sets up the database controller.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    /**
     Handles the save button action.
     Validates the input and adds the goal to the database if valid.
     - Parameters:
       - sender: The button that triggers this action.
     */
    @IBAction func saveButton(_ sender: Any) {
        guard let goals = goalsTextField.text else {
            return
        }

        if goals.isEmpty {
            var errorMsg = "Please Enter Your Goals:\n"
            
            displayMessage(title: "Goals Field Empty!", message: errorMsg)
            return
        }

        let _ = databaseController?.addGoals(goal: goals) // add the goals to the database

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
