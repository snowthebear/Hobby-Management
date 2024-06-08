//
//  AllHobbiesTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit

class AllHobbiesTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {

    let SECTION_HOBBY = 0
    
    let CELL_HOBBY = "hobbyCell"
    
    var allHobbies: [Hobby] = []
    var filteredHobbies: [Hobby] = []
    
    var listenerType = ListenerType.hobbies
    weak var databaseController: DatabaseProtocol?
    
    var currentUserList: UserList?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Hobbies"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        filteredHobbies = allHobbies

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) {
        allHobbies = hobbies
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) {
        
    }
    
    func onGoalsChange(change: DatabaseChange, goals: [Goal]) {
        
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case SECTION_HOBBY:
                return filteredHobbies.count
            default:
                return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure and return a hero cell
        let hobbyCell = tableView.dequeueReusableCell(withIdentifier: CELL_HOBBY, for: indexPath)
        
        var content = hobbyCell.defaultContentConfiguration()
        let hobby = filteredHobbies[indexPath.row]
        content.text = hobby.name
        hobbyCell.contentConfiguration = content
        
        return hobbyCell
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
            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
            let hobby = filteredHobbies[indexPath.row]
            databaseController?.deleteHobby(hobby: hobby)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentList = currentUserList else {
            displayMessage(title: "No List Selected", message: "Please select a list first.")
            return
        }
        
        let hobby = filteredHobbies[indexPath.row]
        
        // Check if the hobby is already in the user's list
        if currentList.hobbies.contains(where: { $0.id == hobby.id }) {
            displayMessage(title: "Oops!", message: "This hobby is already in your list.")
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let hobbyAdded = databaseController?.addHobbyToUserList(hobby: hobby, userList: currentList) ?? false
 
        if hobbyAdded{
            currentList.hobbies.append(hobby)
            tableView.reloadData()
            navigationController?.popViewController(animated: false)
            return
        }
//        displayMessage(title: "Party Full", message: "Unable to add more members to party")
        tableView.deselectRow(at: indexPath, animated: true)

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
    
    
    
    // MARK: - Search Results Updating protocol

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }

        if searchText.count > 0 {
            filteredHobbies = allHobbies.filter({ (hobby: Hobby) -> Bool in
                return (hobby.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredHobbies = allHobbies
        }

        tableView.reloadData()
    }

}
