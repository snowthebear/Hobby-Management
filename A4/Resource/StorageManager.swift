//
//  StorageManager.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 30/05/24.
//

import Foundation
import FirebaseStorage

/**
 StorageManager is a singleton class responsible for managing storage operations, such as uploading and downloading files, using Firebase Storage.
 */
public class StorageManager {
    
    static let shared = StorageManager() // The shared instance of StorageManager for singleton access
    
    private let bucket = Storage.storage().reference() // Reference to the Firebase Storage bucket
    
    public enum StorageManagerError: Error { // the error that can occur during storage operations
        case failedToDownload
    }
    
    
    // MARK: - Public (probably for future to do list)
    
//    /**
//     Downloads an image from Firebase Storage.
//     - Parameters:
//       - reference: The reference path of the image in Firebase Storage.
//       - completion: Completion handler called with the result of the download operation.
//     */
//    public func downloadImage(with reference: String, completion: @escaping (Result<URL, StorageManagerError>) -> Void) {
//        bucket.child(reference).downloadURL(completion: { url, error in
//            guard let url = url, error == nil else {
//                completion(.failure(.failedToDownload))
//                return
//            }
//            
//            completion(.success(url))
//            
//        })
//    }
//    
}

