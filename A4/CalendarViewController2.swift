//
//  CalendarViewController2.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 04/06/24.
//

import Foundation

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import FirebaseAuth

class CalendarViewController2: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var currentUser: User?
    var currentUserList: UserList?
    
    var events = [GTLRCalendar_Event]()
    var daysInMonth = [String]()
    var selectedDate = Date()
    
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        setupDaysInMonth()
        fetchEventsFromGoogleCalendar()
        
        self.currentUser = UserManager.shared.currentUser
        self.currentUserList = UserManager.shared.currentUserList
    }
    
    private func setupDaysInMonth() {
        let range = Calendar.current.range(of: .day, in: .month, for: selectedDate)!
        daysInMonth = range.compactMap { String($0) }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysInMonth.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dayCell", for: indexPath)
        cell.backgroundColor = .lightGray // Customize as needed
        if let dayCell = cell as? EventCell {
            dayCell.dateLabel.text = daysInMonth[indexPath.row]
        }
        return cell
    }
    
    // Define size for cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7 // 7 days a week
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle day selection, potentially update with event data
    }
}


extension CalendarViewController2 {
    func fetchEventsFromGoogleCalendar() {
//        let service = GTLRCalendarService()
//        service.authorizer = self.currentUser.authentication.fetcherAuthorizer()
//
//        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
//        query.maxResults = 10
//        query.timeMin = GTLRDateTime(date: Date())
//        query.singleEvents = true
//        query.orderBy = kGTLRCalendarOrderByStartTime
//        
//        service.executeQuery(query) { [weak self] ticket, result, error in
//            if let error = error {
//                print("Error fetching events: \(error.localizedDescription)")
//                return
//            }
//            if let events = (result as? GTLRCalendar_Events)?.items {
//                self?.events = events
//                DispatchQueue.main.async {
//                    // Reload or update your calendar view if necessary
//                    self?.calendarCollectionView.reloadData()
//                }
//            }
//        }
    }
}
