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


class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBAction func leftButton(_ sender: Any) {
        selectedDate = CalendarHelp().decreaseMonth(date: selectedDate)
        setMonth()
//        guard let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) else { return }
//        selectedDate = newDate
//        updateMonthLabel(for: selectedDate)
//        fetchCalendarEvents(accessToken: UserManager.shared.accessToken!)
    }
    
    @IBAction func rightButton(_ sender: Any) {
        selectedDate = CalendarHelp().increaseMonth(date: selectedDate)
        setMonth()
//        guard let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) else { return }
//        selectedDate = newDate
//        updateMonthLabel(for: selectedDate)
//        fetchCalendarEvents(accessToken: UserManager.shared.accessToken!)
    }
    
    var selectedDate = Date()
    var totalSquares = [String]()
    
    
    var events: [CalendarListEntry] = [] // it holds data relevant to the calendar events
    
    private let scopes =  [kGTLRAuthScopeCalendar]
    private let service = GTLRCalendarService()
    var calendarEvents: [GTLRCalendar_Event] = []
    
    
//    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
 
        setupCalendar()
        self.setCellsView()
        self.fetchCalendarEvents(accessToken: UserManager.shared.accessToken!)
        
        
    }
    
    func setCellsView(){
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            flowLayout.itemSize = CGSize(width: (collectionView.frame.size.width - 2) / 8, height: (collectionView.frame.size.height - 2) / 8)
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        let width = (collectionView.frame.size.width - 2) / 7
//        let height = (collectionView.frame.size.height - 2) / 8
//        
//        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
//        flowLayout.itemSize = CGSize(width: width, height: height)
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
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Error fetching calendar events: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

//            self.events = self.parseEventsFromData(data)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        task.resume()
    }
    
//    func fetchCalendarEvents(accessToken: String) {
//        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
//        query.timeMin = GTLRDateTime(date: selectedDate.startOfMonth())
//        query.timeMax = GTLRDateTime(date: selectedDate.endOfMonth())
//
//        service.executeQuery(query) { [weak self] (ticket, result, error) in
//            guard let self = self, let events = (result as? GTLRCalendar_Events)?.items, error == nil else {
//                print("View controller has been deinitialized.")
//                return
//            }
//            if let error = error {
//                print("Error fetching events: \(error.localizedDescription)")
//                return
//            }
//            guard let events = (result as? GTLRCalendar_Events)?.items else {
//                print("No events found.")
//                return
//            }
//
//            // Map GTLRCalendar_Event directly to CalendarListEntry using the correct initializer
////            self.events = events.map { CalendarListEntry(from: $0 as! Decoder) }
//            
//            // Reload the collection view on the main thread
//            DispatchQueue.main.async {
//                self.collectionView.reloadData()
//            }
//        }
//    }
    
//    func fetchCalendarEvents(accessToken: String) {
//            let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
//            query.timeMin = GTLRDateTime(date: selectedDate.startOfMonth())
//            query.timeMax = GTLRDateTime(date: selectedDate.endOfMonth())
//
//            service.executeQuery(query) { [weak self] (_, result, error) in
//                guard let self = self else { return }
//                if let error = error {
//                    print("Error fetching events: \(error.localizedDescription)")
//                    return
//                }
//                guard let events = (result as? GTLRCalendar_Events)?.items else {
//                    print("No events found.")
//                    return
//                }
//                self.events = events.map(CalendarListEntry.init)
//                DispatchQueue.main.async {
//                    self.populateTotalSquares() // ensure totalSquares and collectionView are updated
//                }
//            }
//        }




    
    func loadGoogleCalendarAPIKey() -> String? {
      if let path = Bundle.main.path(forResource: "client_162068403502-6rjsnhf3bhm3hoht02qb834mchnjqtpg.apps.googleusercontent.com", ofType: "plist"),
         let configDict = NSDictionary(contentsOfFile: path) {
        return configDict["api_key"] as? String
      }
      return nil
    }

    func handleAPIError(message: String) {
        // Show an alert or update the UI to reflect the error
        print(message) // Replace this with UI update code
    }

    func checkForAPIError(data: Data) -> String? {
        do {
            let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            return errorResponse.error.message
        } catch {
            return "Failed to decode error message."
        }
    }

    
    func printRawJSON(data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON response: \(jsonString)")
        } else {
            print("Failed to convert data to JSON string")
        }
    }
    
    
    func parseEventsFromData(_ data: Data) -> [CalendarListEntry] {
        do {
            let decoder = JSONDecoder()
            let eventData = try decoder.decode(CalendarListResponse.self, from: data)
            return eventData.items
        } catch {
            print("Error parsing data: \(error)")
            return []
        }
    }
    
    
    
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
        
        cell.dayOfMoth.text = totalSquares[indexPath.item]
//        cell.dayOfMoth.text = totalSquares[indexPath.row]
//        let event = events[indexPath.row]
//        cell.configure(with: event)
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

