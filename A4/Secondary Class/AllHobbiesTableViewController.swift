//
//  AllHobbiesTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit


/**
 AllHobbiesTableViewController displays a list of all hobbies in a table view.
 It includes search functionality to filter hobbies and allows adding hobbies to the user's list.
 */
class AllHobbiesTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {

    let SECTION_HOBBY = 0 // section index for hobbies in the table view.
    
    let CELL_HOBBY = "hobbyCell" // cell identifier for hobby cells
    
    var allHobbies: [Hobby] = [] // to store all hobbies.
    var filteredHobbies: [Hobby] = [] // to store filtered hobbies based on search input
    
    var listenerType = ListenerType.hobbies // type of listener to listen for hobby changes in the database
    weak var databaseController: DatabaseProtocol? // reference to the database controller for database operations
    
    var currentUserList: UserList? // current user's list of hobbies
    
    
    /**
     Called after the controller's view is loaded into memory.
     Sets up the database controller, search controller, and initializes filtered hobbies.
     */
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
    
    /**
     Called when there is a change in all hobbies in the database.
     Updates the list of all hobbies and the search results.
     - Parameters:
       - change: The type of change in the database.
       - hobbies: The updated list of hobbies.
     */
    func onAllHobbyChange(change: DatabaseChange, hobbies: [Hobby]) {
        allHobbies = hobbies
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    
    func onUserListChange(change: DatabaseChange, userHobbies: [Hobby]) { // this method is not used in this class.
    }
    
    func onGoalsChange(change: DatabaseChange, goals: [Goal]) { // this method is not used in this class.
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { // returns the number of sections in the table view.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // returns the number of rows in a given section of the table view.
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case SECTION_HOBBY:
                return filteredHobbies.count
            default:
                return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // configures and returns a cell for the specified index path in the table view.
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
            let hobby = filteredHobbies[indexPath.row]
            databaseController?.deleteHobby(hobby: hobby)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handles the selection of a row in the table view.
        // Adds the selected hobby to the user's list if it is not already present.
        
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
    
    /**
     Updates the search results based on the search controller's search bar text.
     Filters the list of hobbies and reloads the table view.
     - Parameters:
       - searchController: The search controller containing the search bar.
     */
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
