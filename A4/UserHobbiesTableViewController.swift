//
//  UserHobbiesTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit
import FirebaseAuth

class UserHobbiesTableViewController: UITableViewController, DatabaseListener {
    func onGoalsChange(change: DatabaseChange, goals: [String]) {
        
    }
    
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) {
        DispatchQueue.main.async { [weak self] in
            self?.currentUserList?.hobbies = userHobbies
            self?.tableView.reloadData()
        }
    }
    
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) {
        
    }
    

    let SECTION_HOBBY = 0
    let SECTION_INFO = 1

    let CELL_HOBBY = "hobbyCell"
    let CELL_INFO = "totalCell"

    var currentParty: [Hobby] = []
    var currentUserList: UserList?
    
    var currentUser: FirebaseAuth.User?
    
    var firebaseController: FirebaseController?
    var listenerType: ListenerType = .list
    weak var databaseController: DatabaseProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if firebaseController == nil {
            firebaseController = FirebaseController()
        }
        
        self.currentUserList = UserManager.shared.currentUserList

        tableView.reloadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        self.currentUserList = UserManager.shared.currentUserList
        tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
        if indexPath.section == SECTION_HOBBY {
            // Configure and return a hero cell
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
            // Configure and return an info cell instead
            let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
                    
            let listCount = self.currentUserList?.hobbies.count
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
        if editingStyle == .delete && indexPath.section == SECTION_HOBBY {
            guard let currentUserList = currentUserList else {
                return
            }
            self.databaseController?.removeHobbyFromUserList(hobby: currentUserList.hobbies[indexPath.row], userList:  currentUserList)
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
