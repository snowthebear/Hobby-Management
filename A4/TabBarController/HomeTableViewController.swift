//
//  HomeTableViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


/**
 HomeTableViewController  manages the display of posts in a home feed layout within the app.
 It fetches and displays posts from users that the current user follows, including their own posts.
 This controller uses Firestore to fetch user and post data dynamically.
*/
class HomeTableViewController: UITableViewController {
//---------- properties -----------
    var currentUser: User?
    var currentUserList: UserList?
    var userEmail: String?
    var posts: [UserPost] = []
// --------------------------------
    
    
    /**
     Sets up the view each time it appears, hiding navigation elements and updating the title.
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        self.title = "HOBSNAP"
        fetchPosts()
    }

    /**
     Configures initial view settings and fetches posts for the current user upon view loading.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.navigationItem.hidesBackButton = true
        self.tabBarController?.navigationController?.isNavigationBarHidden = true // hides the tab bar navigation controller
        self.title = "HOBSNAP" // set the view controller title
     
     
        if let user = UserManager.shared.currentUser { // assign the user
            if currentUser == nil{
                currentUser = user
            }
            
            if let list = UserManager.shared.currentUserList { // assign the user hobby list
                if currentUserList == nil {
                    currentUserList = list
                }
            }
        }
        fetchPosts() // fetch all post that user have.
        
    }

    /**
     Fetches posts from Firestore for the current user and their followees, ordering by post date.
     Updates the table view with these posts or handles errors appropriately.
    */
    func fetchPosts() {
        guard let currentUserID = currentUser?.uid else {
            print("Current user ID is not set.")
            return
        }

        let db = Firestore.firestore()
        let followingRef = db.collection("users").document(currentUserID).collection("following") // access the user's following collection

        // Fetch followed user IDs
        followingRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching following list: \(error.localizedDescription)")
                return
            }
            
            var followedUserIDs = [String]() // to store all the followed users' id
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                followedUserIDs = snapshot.documents.map { $0.documentID }
            }
            
            // always include themself
            followedUserIDs.append(currentUserID)
            
            // fetch posts from followed users
            db.collection("posts").whereField("userID", in: followedUserIDs).order(by: "postDate", descending: true).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting posts: \(error.localizedDescription)")
                    return
                }
                
                var fetchedPosts = [UserPost]()
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let group = DispatchGroup()
                    
                    for document in documents { // loop through the document
                        group.enter()
                        let data = document.data()
                        let userID = data["userID"] as? String ?? ""
                        
                        db.collection("users").document(userID).getDocument { userSnapshot, userError in
                            if let userDoc = userSnapshot, userError == nil, let userData = userDoc.data() {
                                let userName = userData["displayName"] as? String ?? "Unknown" // get the user name
                                let storageURL = userData["storageURL"] as? String // get the user's storage url
                                let userProfileImageURL = URL(string: storageURL ?? "") // get the profile picture by using the storage url
                                
                                if let post = UserPost(dictionary: data, userName: userName, userProfileImageURL: userProfileImageURL) { // make it as UserPost type to distinguish the viewed user and logged-in user.
                                    fetchedPosts.append(post) // append all the pictures
                                } else {
                                    print("Error parsing document data: \(data)")
                                }
                            } else if let userError = userError {
                                print("Error fetching user details: \(userError.localizedDescription)")
                            }
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        print("Updating UI with \(fetchedPosts.count) posts.")
                        self.posts = fetchedPosts
                        self.tableView.reloadData() // reload the table view
                    }
                } else {
                    print("No posts found for the user.")
                    self.posts = [] // Clear posts or display some default content
                    self.tableView.reloadData()
                }
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Determines the number of sections in the table view, which is a multiple of 5 for different cell types per post.
        return posts.count * 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Always returns 1 row per section, as each section represents a part of a single post.
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postIndex = indexPath.section / 5
        let sectionType = indexPath.section % 5
        let post = posts[postIndex]

        switch sectionType {
        case 0: // Header cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! FeedHeaderTableViewCell
            cell.configure(with: post.userProfileImageURL, userName: post.userName)
            return cell
        case 1: // Post content cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as! FeedPostTableViewCell
            cell.configure(with: post.photoURL, date: post.date, duration: post.duration)
            return cell
        case 2: // Caption cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "captionCell", for: indexPath) as! FeedCaptionTableViewCell
            cell.configure(with: post.caption)
            return cell
        case 3: // Goals cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "goalCell", for: indexPath) as! FeedGoalsTableViewCell
            cell.configure(with: post.goals)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "breakCell", for: indexPath)
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
