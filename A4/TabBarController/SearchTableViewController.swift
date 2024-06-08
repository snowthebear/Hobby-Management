//
//  SearchTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 11/05/24.
//

import UIKit
import Firebase
import FirebaseAuth


/**
 SearchTableViewController handles user search and display within the app. It enables searching, listing,
 and selection of user profiles using Firestore database queries. It integrates search results into a UITableView
 and updates search results dynamically with a UISearchController.
*/
class SearchTableViewController: UITableViewController, UISearchResultsUpdating {
    // Constants for identifying section and cell types
    var SECTION_USER = 0
    var CELL_USER = "searchUserCell"
    
    var currentUser: User? // current logged-in user
    
    // Arrays to store all users and filtered search results
    var users: [UserProfile] = []
    var filteredUsers: [UserProfile] = []
    
    let db = Firestore.firestore() // firestore database reference
    var selectedUser: UserProfile? // currently selected user profile from search
    
    weak var databaseController: DatabaseProtocol?
    
    // Arrays to store document IDs and user lists for additional functionality
    var selectedUserDocumentIDs: [String] = []
    var selectedUserLists: [String] = []

    
    /**
     Sets up the search controller and loads initial user data when the view is loaded.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        self.currentUser = UserManager.shared.currentUser
        
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
    
    /**
     Ensures the navigation bar is hidden and reloads search results when the view appears.
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    /**
     Method to update search results based on the text input in the search bar.
    */
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredUsers = users // set the filtered users as users
            tableView.reloadData()
            return
        }
        filteredUsers = users.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    /**
     Fetches all user profiles from Firestore to populate search results.
    */
    func loadUsers() {
        db.collection("users").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.users = []
                self.selectedUserDocumentIDs = [] // Resetting or initializing the array
                for document in querySnapshot!.documents {
                    if let userProfile = try? document.data(as: UserProfile.self) {
                        if document.documentID != self.currentUser?.uid {
                            self.users.append(userProfile) // append the users array wuth the UserProfile object
                            self.selectedUserDocumentIDs.append(document.documentID) // Storing document IDs
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    /**
     Fetches hobbies associated with the selected user profiles.
     
     - Parameter hobbyIDs: An array of hobby document IDs to fetch from Firestore.
     - Parameter completion: Closure to execute after all hobbies are fetched.
    */
    func fetchHobbies(hobbyIDs: [String], completion: @escaping ([Hobby]) -> Void) {
        var hobbies: [Hobby] = []
        let group = DispatchGroup()
        
        for id in hobbyIDs {
            group.enter()
            db.collection("hobbies").document(id).getDocument { (document, error) in
                defer { group.leave() }
                if let document = document, document.exists, let hobby = try? document.data(as: Hobby.self) {
                    hobbies.append(hobby)
                } else {
                    print("Error fetching hobby: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        group.notify(queue: .main) {
            completion(hobbies)
        }
    }


    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { // determines the number of sections in the table, which is one for user search results.
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
        //  determines the number of rows in a given section of the table, based on the count of filtered user profiles.
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath) as! SearchUserCell
        let user = filteredUsers[indexPath.row] // showing all the users with the filtered users array
        cell.configure(with: URL(string: user.storageURL), userName: user.displayName)
        return cell
    }
    
    /**
     Handles the selection of a user profile row, sets up the user profile data, and navigates to the profile detail view.
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedUser = filteredUsers[indexPath.row] // the user's selected user
        selectedUser.userID = selectedUserDocumentIDs[indexPath.row] // get the user's selected user user id
        
        if let userListId = selectedUser.userListId {
            db.collection("userlists").document(userListId).getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let document = document, document.exists {
                    let data = document.data()
                    if let hobbyIDs = data?["hobbies"] as? [String] { // access the hobbies document
                        self.fetchHobbies(hobbyIDs: hobbyIDs) { hobbies in
                            selectedUser.userHobby = hobbies // set the user selected user hobby list.
                            self.selectedUser = selectedUser
                            self.performSegue(withIdentifier: "showUserProfile", sender: self)
                            
                        }
                    }
                }
            }
        }
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUserProfile", let destinationVC = segue.destination as? ProfileViewController {
            destinationVC.isCurrentUser = false // set the boolean to false as we want the viewed user screen and not the logged-in user.
            destinationVC.userProfile = self.selectedUser
            
        }
    }


}
