//
//  GoalsTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


/**
 Represents a user's goal with a title and completion status.
 */
struct Goal {
    var title: String
    var isCompleted: Bool
}

/**
 GoalsTableViewController displays and manages a list of user goals in a table view.
 It listens for changes in the database and updates the view accordingly.
 */
class GoalsTableViewController: UITableViewController, DatabaseListener {
    
    let SECTION_GOAL = 0 // section index for goals in the table view.
    let SECTION_INFO = 1 // section index for info in the table view.
    
    let CELL_GOAL = "goalCell" // cell identifier for goal cells
    let CELL_INFO = "totalCell" // cell identifier for info cells
    
    
    var allGoals: [Goal] = [] // to store all goals
    var filteredGoals: [String] = [] // to store filtered goals
    
    var currentUserList: UserList? // current user's list of hobbies
    var currentUser: FirebaseAuth.User? // current logged-in Firebase user
    
    var firebaseController: FirebaseController? // Reference to the Firebase controller for Firebase operations.
    var listenerType = ListenerType.goals // Type of listener to listen for changes in goals
    weak var databaseController: DatabaseProtocol? // Reference to the database controller for database operations

    /**
     Called after the controller's view is loaded into memory.
     Sets up the database controller and reloads the table view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if firebaseController == nil {
            firebaseController = FirebaseController()
        }
        
        tableView.allowsMultipleSelectionDuringEditing = true
        fetchGoals()
        tableView.reloadData()
    }
    
    /**
     Called before the view is added to the window.
     Adds the current view controller as a listener to the database controller.
     - Parameters:
       - animated: If true, the view is being added to the window using an animation.
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        self.currentUserList = UserManager.shared.currentUserList
        fetchGoals()
        tableView.reloadData()
        
    }
    
    /**
     Called before the view is removed from the window.
     Removes the current view controller as a listener from the database controller.
     - Parameters:
       - animated: If true, the disappearance of the view is animated.
     */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)

    }
    
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) { // This method is not used in this class.
        
    }
    
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) { // This method is not used in this class.
        
    }
    
    /**
     Called when there is a change in the user's goals in the database.
     Updates the list of goals and reloads the table view.
     - Parameters:
       - change: The type of change in the database.
       - goals: The updated list of goals.
     */
    func onGoalsChange(change: DatabaseChange, goals: [Goal]) {
        DispatchQueue.main.async { [weak self] in
            self?.allGoals = goals
            self?.tableView.reloadData()
        }
    }
    
    /**
     Saves the changes made to the goals.
     Filters out the completed goals and updates the database.
     */
    func saveGoalChanges() {
        _ = allGoals.filter { $0.isCompleted }
    }
    
    /**
     Fetches the goals from the database and reloads the table view.
     */
    func fetchGoals() {
        databaseController?.fetchGoals { [weak self] goals in
            print("Fetched goals:", goals)
            DispatchQueue.main.async {
                self?.allGoals = goals
                self?.tableView.reloadData()
            }
        }
    }
    
    /**
    Updates the completion status of a goal in the database.
    - Parameters:
      - goalTitle: The title of the goal to update.
      - isCompleted: The new completion status of the goal.
    */
    func updateGoalCompletion(goalTitle: String, isCompleted: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let userDocRef = Firestore.firestore().collection("users").document(userID)

        // Fetch the current goals
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var goals = document.data()?["goals"] as? [[String: Any]] ?? []
                
                // Find the goal and update the completion status
                if let index = goals.firstIndex(where: { $0["title"] as? String == goalTitle }) {
                    goals[index]["completed"] = isCompleted
                }
                
                // Update the entire array back to Firestore
                userDocRef.updateData(["goals": goals]) { error in
                    if let error = error {
                        print("Error updating goal: \(error.localizedDescription)")
                    } else {
                        print("Goal updated successfully.")
                    }
                }
            } else {
                print("Document does not exist or error fetching document: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Returns the number of sections in the table view.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Returns the number of rows in a given section of the table view.
        return allGoals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configures and returns a cell for the specified index path in the table view.
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_GOAL, for: indexPath)
        let goal = allGoals[indexPath.row]
        cell.textLabel?.text = goal.title
        cell.accessoryType = goal.isCompleted ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handles the selection of a row in the table view.
        // Toggles the completion status of the selected goal and updates the database.

        allGoals[indexPath.row].isCompleted.toggle()
        updateGoalCompletion(goalTitle: allGoals[indexPath.row].title, isCompleted: allGoals[indexPath.row].isCompleted)
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.section == SECTION_GOAL {
            return true
        }

        return false
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == SECTION_GOAL {
            self.databaseController?.deleteGoals(goalId: allGoals[indexPath.row].title)
            allGoals.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
