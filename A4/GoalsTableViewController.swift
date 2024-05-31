//
//  GoalsTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class GoalsTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    
    
    let SECTION_GOAL = 0
    let SECTION_INFO = 1
    
    let CELL_GOAL = "goalCell"
    let CELL_INFO = "totalCell"
    
    
    var allGoals: [String] = []
    var filteredGoals: [String] = []
    
    var currentUserList: UserList?
    var currentUser: FirebaseAuth.User?
    
    var firebaseController: FirebaseController?
    var listenerType = ListenerType.goals
    weak var databaseController: DatabaseProtocol?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        if firebaseController == nil {
            firebaseController = FirebaseController()
        }
//        fetchGoals()
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
        fetchGoals()
        tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)

    }
    
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) {
        
    }
    
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) {
        
    }
    
    func onGoalsChange(change: DatabaseChange, goals: [String]) {
        DispatchQueue.main.async { [weak self] in
            self?.allGoals = goals
            self?.tableView.reloadData()
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    func fetchGoals() {
        databaseController?.fetchGoals { [weak self] goals in
            DispatchQueue.main.async {
                self?.allGoals = goals
                self?.tableView.reloadData()
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allGoals.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_GOAL, for: indexPath)
        cell.textLabel?.text = allGoals[indexPath.row]

        // Configure the cell...

        return cell
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
            self.databaseController?.deleteGoals(goalId: allGoals[indexPath.row])
            self.allGoals.remove(at: indexPath.row)
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
