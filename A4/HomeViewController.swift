//
//  HomeViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import Foundation
import UIKit
import FirebaseAuth


struct HomeFeedRenderViewModel {
    let header: RenderViewModel
    let post: RenderViewModel
    let actions: RenderViewModel
    let comments: RenderViewModel
}

class HomeViewController: UIViewController {
    var currentUser: User?
    var currentUserList: UserList?
    var userEmail: String?
    
    private var feedRenderModels = [HomeFeedRenderViewModel]()
    
    private var tableView: UITableView {
        let tableView = UITableView()
        
        // Register Cell
        tableView.register(FeedPostTableViewCell.self, forCellReuseIdentifier: FeedPostTableViewCell.identifier)
        tableView.register(FeedHeaderTableViewCell.self, forCellReuseIdentifier: FeedHeaderTableViewCell.identifier)
        tableView.register(FeedActionTableViewCell.self, forCellReuseIdentifier: FeedActionTableViewCell.identifier)
        tableView.register(FeedCommentLikeTableViewCell.self, forCellReuseIdentifier: FeedCommentLikeTableViewCell.identifier)
        return tableView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // check auth status
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
                if let user = UserManager.shared.currentUser {
            if currentUser == nil{
                currentUser = user
            }
        }
        
        if let list = UserManager.shared.currentUserList {
            if currentUserList == nil {
                currentUserList = list
            }
        }
        
        createModels()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds // entire screenn
    }
    
    private func createModels() {
        guard let currentUser = currentUser else{
            return
        }
//        for x in 0..<5 {
//            let viewModel = HomeFeedRenderViewModel(header: RenderViewModel(renderType: .header(provider: currentUser)),
//                                                    post: RenderViewModel(renderType: .postContent(provider: nil)),
//                                                    actions: RenderViewModel(renderType: .header(provider: currentUser)),
//                                                    comments: RenderViewModel(renderType: .header(provider: currentUser)))
//            feedRenderModels.append(viewModel)
//        }
    }
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return feedRenderModels.count * 4 // because each model has its section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let x = section
        let model: HomeFeedRenderViewModel
        
        if x == 0 {
            model = feedRenderModels[0]
        }
        else {
            let position = x % 4 == 0 ? x / 4 : ((x - (x % 4)) / 4 )
            model = feedRenderModels[position]
        }
        
        let subSect = x % 4
        
        if subSect == 0 {
            // header
            return 1
        }
        else if subSect == 1 {
            // post
            return 1
        }
        else if subSect == 2 {
            // actions
            return 1
        }
        else if subSect == 3 {
            // comments
            let commentModel = model.comments
            switch commentModel.renderType {
            case .comments(provider: let comments): return comments.count > 2 ? 2 : comments.count
            case .header, .actions, .postContent: return 0
    
            }
        }
        
        else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let x = indexPath.section
        let model: HomeFeedRenderViewModel
        
        if x == 0 {
            model = feedRenderModels[0]
        }
        else {
            let position = x % 4 == 0 ? x / 4 : ((x - (x % 4)) / 4 )
            model = feedRenderModels[position]
        }
        
        let subSect = x % 4
        
        if subSect == 0 {
            // header
            let header = model.header

            switch header.renderType {
            case .header(provider: let user):
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedHeaderTableViewCell.identifier, for: indexPath) as! FeedHeaderTableViewCell
                return cell
                
            case .comments, .actions, .postContent: return UITableViewCell()
            }
        }
        else if subSect == 1 {
            // post
            let post = model.post
            switch post.renderType {
            case .postContent(provider: let post):
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostTableViewCell.identifier, for: indexPath) as! FeedPostTableViewCell
                return cell
            case .comments, .actions, .header: return UITableViewCell()

            }
        }
        else if subSect == 2 {
            // actions
            let actions = model.actions
            switch actions.renderType {
            case .actions(provider: let provider):
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedActionTableViewCell.identifier, for: indexPath) as! FeedActionTableViewCell
                return cell
            case .comments, .header, .postContent: return UITableViewCell()

            }
            
        }
        else if subSect == 3 {
            // comments
            let commentModel = model.comments
            switch commentModel.renderType {
            case .comments(provider: let comments):
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedCommentLikeTableViewCell.identifier, for: indexPath) as! FeedCommentLikeTableViewCell
                return cell
                
            case .header, .actions, .postContent: return UITableViewCell()
            }
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostTableViewCell.identifier, for: indexPath) as! FeedPostTableViewCell
            return cell
        }
         
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let subSect = indexPath.section % 4
        
        if subSect == 0 {
            return 70
        }
        else if subSect == 1 {
            return tableView.width
        }
        else if subSect == 2 {
            return 60
        }
        else if subSect == 3 {
            return 50
        }
        else{
            return 0
        }
        
    }
    
    
    
    
}

enum RenderType {
    case header(provider: User)
    case postContent(provider: UserPost) // for the post
    case actions(provider: String) // for like, comment, and share
    case comments(provider: [PostComment])
}

struct RenderViewModel {
    let renderType: RenderType
}
