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
    
    func uploadUserPost(model: UserPost, completion: @escaping (Result<URL, Error>) -> Void) {
        
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

