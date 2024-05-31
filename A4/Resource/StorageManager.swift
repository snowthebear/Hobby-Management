//
//  StorageManager.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import Foundation
import FirebaseStorage

public class StorageManager {
    
    static let shared = StorageManager()
    
    private let bucket = Storage.storage().reference()
    
    public enum StorageManagerError: Error {
        case failedToDownload
    }
    
    
    // MARK: - Public
    
    public func uploadUserPost(model: UserPost, completion: @escaping (Result<URL, Error>) -> Void) {
        
    }
    
    public func downloadImage(with reference: String, completion: @escaping (Result<URL, StorageManagerError>) -> Void) {
        bucket.child(reference).downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(.failedToDownload))
                return
            }
            
            completion(.success(url))
            
        })
    }
    
}

public enum UserPostType {
    case photo
    case video
}

// Represent user posts
public struct UserPost{
    let identifier: String
    let postType: UserPostType
    let photoThumbnail: URL
    let postURL: URL // either photo full resolution or video url
    let caption: String?
    let likeCount: [PostLikes]?
    let comments: [PostComment]?
    let createdDate: Date
    
}

struct PostLikes {
    let username: String
    let postIdentifier: String
}

struct CommentLikes {
    let username: String
    let commentIdentifier: String
}

struct PostComment {
    let identifier: String
    let username: String
    let text: String
    let createdDate: Date
    let commentLikes: CommentLikes
    let likes: [CommentLikes]
}
