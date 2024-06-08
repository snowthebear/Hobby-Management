//
//  UserHobbiesTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit
import FirebaseAuth


/**
 UserHobbiesTableViewController displays a user's list of hobbies in a table view.
 It listens for changes in the database and updates the view accordingly.
 */
class UserHobbiesTableViewController: UITableViewController, DatabaseListener {
    func onGoalsChange(change: DatabaseChange, goals: [Goal]) { // This method is not used in this class.
        
    }
    
    /**
     Called when there is a change in the user's list of hobbies in the database.
     Updates the user's list of hobbies and reloads the table view.
     - Parameters:
       - change: The type of change in the database.
       - userHobbies: The updated list of user hobbies.
     */
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) {
        DispatchQueue.main.async { [weak self] in
            self?.currentUserList?.hobbies = userHobbies
            self?.tableView.reloadData()
        }
    }
    
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) { // This method is not used in this class.
        
    }
    
    let SECTION_HOBBY = 0 // section index for hobbies in the table view
    let SECTION_INFO = 1 // section index for info in the table view

    let CELL_HOBBY = "hobbyCell" // cell identifier for hobby cells.
    let CELL_INFO = "totalCell" // cell identifier for info cells.

    var currentParty: [Hobby] = [] // to store the current list of hobbies
    
    var currentUserList: UserList? // current user's list of hobbies
    var currentUser: FirebaseAuth.User? // current logged-in Firebase user
    
    var firebaseController: FirebaseController? // reference to the Firebase controller for Firebase operations
    var listenerType: ListenerType = .list // type of listener to listen for changes in the user's list.
    weak var databaseController: DatabaseProtocol? // reference to the database controller for database operations
    
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
        
        self.currentUserList = UserManager.shared.currentUserList

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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Returns the number of sections in the table view.
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //  Returns the number of rows in a given section of the table view
        switch section {
            case SECTION_HOBBY:
            return currentUserList?.hobbies.count ?? 0
            case SECTION_INFO:
                return 1
            default:
                return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configures and returns a cell for the specified index path in the table view.
        if indexPath.section == SECTION_HOBBY {
            let hobbyCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOBBY, for: indexPath)
            
            if let currentUserList = currentUserList {
                let hobby = currentUserList.hobbies[indexPath.row]
                var content = hobbyCell.defaultContentConfiguration()
                content.text = hobby.name
                hobbyCell.contentConfiguration = content
            }
            return hobbyCell
        }
        else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
                    
            let listCount = currentUserList?.hobbies.count
            var content = infoCell.defaultContentConfiguration()
            if listCount == 0 {
                content.text = "No Hobbies in list. Tap + to add some."
            } else {
                content.text = "\(listCount ?? 0) hobbies in your list"
            }
            infoCell.contentConfiguration = content

            return infoCell
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.section == SECTION_HOBBY {
            return true
        }

        return false
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //  Commits the editing actions for the specified row in the table view.
        if editingStyle == .delete && indexPath.section == SECTION_HOBBY {
            guard let currentUserList = currentUserList else {
                return
            }
            
            self.databaseController?.removeHobbyFromUserList(hobby: currentUserList.hobbies[indexPath.row], userList:  currentUserList)
            currentUserList.hobbies.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showAllHobbies" {
            guard let destination = segue.destination as? AllHobbiesTableViewController else {
                return
            }
            destination.currentUserList = self.currentUserList
            destination.databaseController = self.databaseController
        }
    }
    

}
