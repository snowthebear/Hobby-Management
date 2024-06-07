//
//  SearchTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit
import Firebase
import FirebaseAuth

class SearchTableViewController: UITableViewController, UISearchResultsUpdating {
    
    var SECTION_USER = 0
    var CELL_USER = "searchUserCell"
    
    var users: [UserProfile] = []
    var filteredUsers: [UserProfile] = []
    let db = Firestore.firestore()
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        loadUsers()
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Users"
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
                
        // This view controller decides how the search controller is presented
        definesPresentationContext = true
        
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.01)) // Minimal height
        tableView.contentInsetAdjustmentBehavior = .automatic

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredUsers = users
            tableView.reloadData()
            return
        }
        filteredUsers = users.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    func loadUsers() {
        db.collection("users").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.users = querySnapshot!.documents.compactMap { document -> UserProfile? in
                    try? document.data(as: UserProfile.self)
                }
                self.tableView.reloadData()
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
            case SECTION_USER:
                return filteredUsers.count
            default:
                return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath) as! SearchUserCell
            let user = filteredUsers[indexPath.row]
            cell.configure(with: URL(string: user.storageURL), userName: user.displayName)
            return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
