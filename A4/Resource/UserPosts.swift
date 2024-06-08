//
//  UserPosts.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 31/05/24.
//

import Foundation
import FirebaseFirestore


/**
 Represents the type of a user's post, either a photo or a video.
 */
public enum UserPostType: String {
    case photo
    case video

    /**
     Initializes a `UserPostType` from a raw string value.
     - Parameters:
       - rawValue: The raw string value representing the post type.
     */
    public init?(rawValue: String) {
        switch rawValue {
        case "photo": self = .photo
        case "video": self = .video
        default: return nil
        }
    }
}

/**
 Represents a user's post with various attributes such as user information, photo URL, date, caption, goals, and duration.
 */
struct UserPost {
    var userID: String
    var userName: String
    var userProfileImageURL: URL?
    var photoURL: URL
    var date: Date
    var caption: String
    var goals: String
    var duration: Int

    /**
     Initializes a new UserPost instance from a dictionary.
     - Parameters:
       - dictionary: The dictionary containing post data.
       - userName: The name of the user who made the post.
       - userProfileImageURL: The URL of the user's profile image.
     - Returns: An optional `UserPost` instance.
     */
    init?(dictionary: [String: Any], userName: String, userProfileImageURL: URL?) {
        guard let userID = dictionary["userID"] as? String else {
            return nil
        }

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
