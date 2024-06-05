//
//  UserPosts.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 31/05/24.
//

import Foundation
import FirebaseFirestore

public enum UserPostType: String {
    case photo
    case video

    public init?(rawValue: String) {
        switch rawValue {
        case "photo": self = .photo
        case "video": self = .video
        default: return nil
        }
    }
}

struct UserPost {
    var userID: String
    var userName: String
    var userProfileImageURL: URL?
    var photoURL: URL
    var date: Date
    var caption: String
    var goals: String
    var duration: Int

    init?(dictionary: [String: Any], userName: String, userProfileImageURL: URL?) {
        guard let userID = dictionary["userID"] as? String else {
            return nil
        }
//        guard let userName = UserManager.shared.currentUser?.displayName else {
//            return nil
//        }
        guard let photoURLString = dictionary["imageUrl"] as? String, let photoURL = URL(string: photoURLString) else {
            return nil
        }
        guard let date = dictionary["postDate"] as? Timestamp else {
            return nil
        }

        self.userID = userID
        self.userName = userName
        self.userProfileImageURL = userProfileImageURL
        self.photoURL = photoURL
        self.date = date.dateValue()
        self.caption = dictionary["caption"] as? String ?? " - "
        self.goals = dictionary["goal"] as? String ?? ""
        self.duration = dictionary["duration"] as? Int ?? 0
    }
}



//struct PostComment {
//    let identifier: String
//    let username: String
//    let text: String
//    let createdDate: Date
//
//    init?(dictionary: [String: Any]) {
//        guard let identifier = dictionary["identifier"] as? String,
//              let username = dictionary["username"] as? String,
//              let text = dictionary["text"] as? String,
//              let createdDateTimestamp = dictionary["createdDate"] as? Timestamp else {
//            return nil
//        }
//        self.identifier = identifier
//        self.username = username
//        self.text = text
//        self.createdDate = createdDateTimestamp.dateValue()
//    }
//}
