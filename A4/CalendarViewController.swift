//
//  CalendarViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation
import UIKit
import GoogleAPIClientForREST
import GoogleSignIn
import FirebaseAuth


class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    
    var currentUser: User?
    var currentUserList: UserList?
    
    @IBAction func leftButton(_ sender: Any) {
        selectedDate = CalendarHelp().decreaseMonth(date: selectedDate)
        setMonth()
    }
    
    @IBAction func rightButton(_ sender: Any) {
        selectedDate = CalendarHelp().increaseMonth(date: selectedDate)
        setMonth()

    }
    
    var selectedDate = Date()
    var totalSquares = [String]()
    
    
    var events: [CalendarListEntry]? = [] // it holds data relevant to the calendar events
    
    private let scopes =  [kGTLRAuthScopeCalendar]
    private let service = GTLRCalendarService()
    var calendarEvents: [GTLRCalendar_Event] = []
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
 
        setupCalendar()
        self.setCellsView()
        self.fetchCalendarEvents(accessToken: UserManager.shared.accessToken!)
        
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
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setCellsView()  // Adjust collection view cell layout
    }
    
    
    func setCellsView() {
        guard let collectionViewWidth = collectionView?.superview?.bounds.width else { return }

        let width = collectionViewWidth / 7
        let height = width

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = UIEdgeInsets.zero
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
    }
    
    
    func setupCalendar() {
        let currentDate = Date()
        selectedDate = currentDate
        updateMonthLabel(for: currentDate)
        populateTotalSquares()
    }
    
    func setMonth() {
        totalSquares.removeAll()
        
        let daysInMonth = CalendarHelp().daysInMonth(date: selectedDate)
        let firstDayOfMonth = CalendarHelp().firstOfMonth(date: selectedDate)
        let startingSpaces = CalendarHelp().weekDay(date: firstDayOfMonth)
        
        var count: Int = 1
        
        while(count <= 42)
        {
            if(count <= startingSpaces || count - startingSpaces > daysInMonth)
            {
                totalSquares.append("")
            }
            else
            {
                totalSquares.append(String(count - startingSpaces))
            }
            count += 1
        }
        
        monthLabel.text = CalendarHelp().monthString(date: selectedDate)
            + " " + CalendarHelp().yearString(date: selectedDate)
        collectionView.reloadData()
    }

    func updateMonthLabel(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: date)
    }
    
    func populateTotalSquares() {
        totalSquares.removeAll()
        let range = Calendar.current.range(of: .day, in: .month, for: selectedDate)!
        totalSquares = range.map { String($0) }
        collectionView.reloadData()
    }
    
    
    
    
    
    
    func fetchCalendarEvents(accessToken: String) {
        print("here")
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("before task")
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Error fetching calendar events: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.printRawJSON(data: data)

            if let events = self.parseEventsFromData(jsonData: data) {
                print("masuk parse if")
                DispatchQueue.main.async {
                    // Handle the fetched events, e.g., save to a property or update UI
                    print("Fetched and parsed \(events.count) calendar events.")
                }
            } else {
                print("Failed to parse events from data.")
                if let errorMessage = self.checkForAPIError(data: data) {
                    self.handleAPIError(message: errorMessage)
                }
            }
        }
        task.resume()
    }

    func parseEventsFromData(jsonData: Data) -> [CalendarListEntry]? {
        let decoder = JSONDecoder()
        do {
            let calendarListResponse = try decoder.decode(CalendarListResponse.self, from: jsonData)
            return calendarListResponse.items
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not found: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type mismatch for type '\(type)': \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not found: \(context.debugDescription)")
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
        }
        return nil
    }

    func printRawJSON(data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON response: \(jsonString)")
        } else {
            print("Failed to convert data to JSON string")
        }
    }

    func checkForAPIError(data: Data) -> String? {
        do {
            let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            return errorResponse.error.message
        } catch {
            return "Failed to decode error message."
        }
    }

    func handleAPIError(message: String) {
        // Show an alert or update the UI to reflect the error
        print(message)
    }
    
    
    func loadGoogleCalendarConfig() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: "Google-Calendar", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("Failed to load Google-Calendar.plist")
            return nil
        }
        return dict
    }
    

//    func parseEventsFromData(jsonData: Data) -> [CalendarListEntry]? {
//        let decoder = JSONDecoder()
//        do {
//            let calendarList = try decoder.decode(CalendarListResponse.self, from: jsonData)
//            return calendarList.items
//        } catch {
//            print("Error decoding JSON: \(error)")
//            return nil
//        }
//    }
    
    
    
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print("Number of events: \(events.count)")
//        return events.count
            
        return totalSquares.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Configure the cell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calendarCell", for: indexPath) as? EventCollectionViewCell else {
            fatalError("Cannot dequeue CalendarCell")
        }
        let day = totalSquares[indexPath.item]
        cell.dayOfMoth.text = day
        cell.eventLabel.text = ""
        
        return cell
    }

    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
    
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    
    
    
    
    struct APIErrorResponse: Codable {
        let error: APIError
    }

    struct APIError: Codable {
        let code: Int
        let message: String
        let errors: [APIErrorDetail]
        let status: String
    }

    struct APIErrorDetail: Codable {
        let message: String
        let domain: String
        let reason: String
    }
    
    
    

}
extension Date {
    func startOfMonth() -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }

    func endOfMonth() -> Date {
        let start = self.startOfMonth()
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
    }
}

