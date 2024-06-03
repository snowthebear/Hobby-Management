//
//  HomeTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore



class HomeTableViewController: UITableViewController {
    var currentUser: User?
    var currentUserList: UserList?
    var userEmail: String?
    
    var posts: [UserPost] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationItem.setHidesBackButton(true, animated: true)
//        self.tabBarController?.navigationItem.hidesBackButton = true
//        self.tabBarController?.navigationItem.title = "HOBSNAP"
        print("aaaa")
        fetchPosts()
//        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.navigationItem.hidesBackButton = true
     
     
        if let user = UserManager.shared.currentUser {
            if currentUser == nil{
                currentUser = user
            }
            
            if let list = UserManager.shared.currentUserList {
                if currentUserList == nil {
                    currentUserList = list
                }
            }
        }
        print("vvv")
        fetchPosts()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts").order(by: "postDate", descending: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.posts = querySnapshot?.documents.compactMap { UserPost(dictionary: $0.data()) } ?? []
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count * 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postIndex = indexPath.section / 4
        let sectionType = indexPath.section % 4
        let post = posts[postIndex]

        switch sectionType {
        case 0: // Header cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! FeedHeaderTableViewCell
            cell.configure(with: post.userID, userName: post.userName)
            return cell
        case 1: // Post content cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! FeedPostTableViewCell
            print("Setting image for section \(indexPath.section): \(post.photoURL)")
            cell.configure(with: post.photoURL, date: post.date)
            return cell
        case 2: // Caption cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "captionCell", for: indexPath) as! FeedCaptionTableViewCell
            cell.configure(with: post.caption)
            return cell
        case 3: // Goals cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "goalCell", for: indexPath) as! FeedGoalsTableViewCell
            cell.configure(with: post.goals)
            return cell
        default:
            fatalError("Unexpected IndexPath which is out of section bounds")
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
