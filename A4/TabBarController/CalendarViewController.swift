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


// calendar creation reference : https://www.youtube.com/watch?v=abbWOYFZd68


/**
 CalendarViewController manages the display and interactions with a custom calendar interface, allowing users to view, add, and manage events. It integrates with Google Calendar for event management.

 Properties:
 - currentUser: The currently logged-in user's data.
 - currentUserList: List of current user's hobbies or interests.
 - events: Array holding data relevant to the calendar events.
 - service: Instance of `GTLRCalendarService` to interact with Google Calendar API.
 - calendarEvents: Array of Google Calendar events fetched from the API.
*/
class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    
    var currentUser: User?
    var currentUserList: UserList?
    
    var selectedDate = Date()
    var totalSquares = [String]()
    
    var events: [CalendarListEntry]? = [] // it holds data relevant to the calendar events
    
    private let scopes =  [kGTLRAuthScopeCalendar]
    private let service = GTLRCalendarService()
    var calendarEvents: [GTLRCalendar_Event] = []
    
    
    /**
     Sets the previous month view when the left navigation button is tapped.
    */
    @IBAction func leftButton(_ sender: Any) {
        selectedDate = CalendarHelp().decreaseMonth(date: selectedDate)
        setMonth()
    }
    
    /**
     Sets the next month view when the right navigation button is tapped.
    */
    @IBAction func rightButton(_ sender: Any) {
        selectedDate = CalendarHelp().increaseMonth(date: selectedDate)
        setMonth()

    }

    /**
     Called when the view controller’s view is about to be added to a view hierarchy and hides navigation bar.
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        self.title = "Calendar"
        guard let accessToken = UserManager.shared.accessToken else {
            print("Access token is nil")
            return
        }
        self.fetchCalendarEvents(accessToken: accessToken) // fetch all the events in calendar
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
    }
    
    /**
     Prepares the calendar and its components on view load.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.navigationController?.isNavigationBarHidden = true
        self.navigationController?.title = "Calendar"
        collectionView.delegate = self
        collectionView.dataSource = self
 
        setupCalendar()
        self.setCellsView()
        
        if let user = UserManager.shared.currentUser {
            if currentUser == nil{
                currentUser = user // set the current logged-in user
            }
            
            if let list = UserManager.shared.currentUserList {
                if currentUserList == nil {
                    currentUserList = list // set the user hobby list.
                }
            }
            
            guard let accessToken = UserManager.shared.accessToken else {
                print("Access token is nil")
                return
            }
            self.fetchCalendarEvents(accessToken: accessToken) // fetch the calendar events with the user's access token
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setCellsView()
    }
    
    /**
     Sets the dimensions and layout for calendar cells based on the view's width.
    */
    func setCellsView() {
        guard let collectionViewWidth = collectionView?.superview?.bounds.width else { return }

        let width = collectionViewWidth / 7
        let height = width

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: width, height: height)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 30 // give a gap for each column.
        flowLayout.sectionInset = UIEdgeInsets.zero
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
    }
    
    /**
     Sets up the calendar view for the current month and populates the days.
    */
    func setupCalendar() {
        let currentDate = Date() // set to the current date
        selectedDate = currentDate
        updateMonthLabel(for: currentDate)
        populateTotalSquares()
    }
    
    /**
     Populates totalSquares array representing days in the month and updates the UI accordingly.
    */
    func setMonth() {
        totalSquares.removeAll()
        
        let daysInMonth = CalendarHelp().daysInMonth(date: selectedDate)
        let firstDayOfMonth = CalendarHelp().firstOfMonth(date: selectedDate)
        let startingSpaces = CalendarHelp().weekDay(date: firstDayOfMonth)
        
        var count: Int = 1
        
        while(count <= 42) {
            if(count <= startingSpaces || count - startingSpaces > daysInMonth){
                totalSquares.append("")
            }
            else {
                totalSquares.append(String(count - startingSpaces))
            }
            count += 1
        }
        
        monthLabel.text = CalendarHelp().monthString(date: selectedDate)
            + " " + CalendarHelp().yearString(date: selectedDate)
        collectionView.reloadData()
    }

    func updateMonthLabel(for date: Date) { // updating the month label inside the cell
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: date)
    }
    
    func populateTotalSquares() { // populate number of squares to follow the each month's total day.
        totalSquares.removeAll()
        let range = Calendar.current.range(of: .day, in: .month, for: selectedDate)!
        totalSquares = range.map { String($0) }
        collectionView.reloadData()
    }
    
    
    /**
     Fetches the list of calendar events associated with the user's account from Google Calendar.

     - Parameter accessToken: The OAuth2 access token that authorizes the request to Google Calendar API.
    */
    func fetchCalendarEvents(accessToken: String) {
        // Construct the URL for accessing the Google Calendar API.
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList") else {
            print("Invalid URL")
            return
        }
        
        // Prepare the request with proper headers.
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Use GET method to retrieve data.
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // Authenticate the request with the OAuth2 token.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set the content type of the request to JSON.
  
        // Perform the network task to fetch calendar data.
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Ensure there is data and no errors; if not, handle the error
            guard let self = self, let data = data, error == nil else {
                print("Error fetching calendar events: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Parse the JSON data into structured calendar event entries.
            if let events = self.parseEventsFromData(jsonData: data) {
                DispatchQueue.main.async {
                    self.events = events// Assign the parsed events to the view controller's events property.
                    self.fetchEventsForCalendars(accessToken: accessToken, calendars: events) // Fetch detailed events for each calendar.
                    print("Fetched and parsed \(events.count) calendar events.")
                }
            } else {
                print("Failed to parse events from data.")
                if let errorMessage = self.checkForAPIError(data: data) {
                    self.handleAPIError(message: errorMessage)  // Handle potential API errors received from Google.
                }
            }
        }
        task.resume() // Start the network task.
    }
    
    /**
     Fetches detailed events from Google Calendar for each calendar entry provided.

     - Parameter accessToken: The OAuth2 access token used for authorization.
     - Parameter calendars: A list of calendar entries for which events are to be fetched.
    */
    func fetchEventsForCalendars(accessToken: String, calendars: [CalendarListEntry]) {
        let group = DispatchGroup()

        for calendar in calendars {  // Request event details for each calendar concurrently.
            group.enter()
            fetchEvents(for: calendar.id, accessToken: accessToken) { [weak self] events in
                guard let self = self else { return }
                self.calendarEvents.append(contentsOf: events)
                group.leave()
            }
        }
        
        // when all calendar details have been fetched, reload the collectionView.
        group.notify(queue: .main) {
            self.collectionView.reloadData()
        }
    }
    
    /**
     Fetches event details from Google Calendar for a specific calendar ID.

     - Parameter calendarId: The ID of the calendar for which events are being requested.
     - Parameter accessToken: The OAuth2 access token used for authorization.
     - Parameter completion: A completion handler that passes the fetched events or an empty array on failure.
    */
    func fetchEvents(for calendarId: String, accessToken: String, completion: @escaping ([GTLRCalendar_Event]) -> Void) {
        // Construct the URL for fetching events for a specific calendar.
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events") else {
            print("Invalid URL")
            completion([])
            return
        }
        
        // Prepare the URLRequest with appropriate HTTP method and headers.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // Set the access token for authorization.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")  // Ensure the request content type is JSON.
        
        // Execute the request using URLSession.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for valid data and no errors, if not, handle the error and return an empty array.
            guard let data = data, error == nil else {
                print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            do {
                // Decode the JSON response into a list of events.
                let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)
                completion(eventsResponse.items)
            } catch {
                print("Error parsing events data: \(error.localizedDescription)")
                completion([])
            }
        }
        task.resume() // Start the data task.
    }

    /**
     Parses event data from raw JSON to structured data.
    */
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

    func printRawJSON(data: Data) { // for printing the json (for debugging purpose)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON response: \(jsonString)")
        } else {
            print("Failed to convert data to JSON string")
        }
    }

    func checkForAPIError(data: Data) -> String? { // check if the API error (for debugging purpose)
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
    
    /**
     Fetches the configuration for Google Calendar integration from a local `.plist` file.

     - Returns: A dictionary containing the Google Calendar configuration, or `nil` if the file could not be loaded.
    */
    func loadGoogleCalendarConfig() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: "Google-Calendar", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("Failed to load Google-Calendar.plist")
            return nil
        }
        return dict
    }
    

    /**
     Calculates the `Date` for a specific day of the current month displayed in the calendar.

     - Parameter day: The day of the month for which to generate the date.
     - Returns: A `Date` object representing the specified day of the current month, or `nil` if the date cannot be calculated.
    */
    func getDate(for day: Int) -> Date? {
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        return Calendar.current.date(from: DateComponents(year: components.year, month: components.month, day: day))
    }
    
    /**
     Presents an alert to input details for creating a new event on a specified date.

     - Parameter date: The date on which the event is to be created.
    */
    func promptForEventDetails(on date: Date) {
        let alertController = UIAlertController(title: "New Event", message: "Enter details for your new event on \(date.formattedDate())", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Event Title"
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let title = alertController.textFields?.first?.text, !title.isEmpty else { return }
            self?.createEvent(title: title, date: date)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    /**
     Creates a new event with the specified title and date. Currently, this method simply logs the creation for demonstration purposes.

     - Parameter title: The title of the event.
     - Parameter date: The date on which the event occurs.
    */
    func createEvent(title: String, date: Date) {
        // Logic to create the event in Google Calendar or locally
        // For now, let's just log the creation for simplicity
        print("Event '\(title)' created for \(date.formattedDate())")
    }

    
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        
    if let dayInt = Int(day) {
            let currentMonth = Calendar.current.component(.month, from: selectedDate)
            let currentYear = Calendar.current.component(.year, from: selectedDate)
            let currentDateComponents = DateComponents(year: currentYear, month: currentMonth, day: dayInt)
            let currentDate = Calendar.current.date(from: currentDateComponents)

            for event in calendarEvents {
                if let eventStart = event.start?.dateTime ?? event.start?.date,
                   let eventDate = ISO8601DateFormatter().date(from: eventStart),
                   Calendar.current.isDate(eventDate, inSameDayAs: currentDate!) {
                    cell.eventLabel.text = event.summary
                    break
                }
            }
        }
        
        return cell
    }

    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle tap events
        let day = totalSquares[indexPath.item]
            if let dayInt = Int(day), let selectedDate = getDate(for: dayInt) {
                promptForEventDetails(on: selectedDate)
            } else {
                print("Selection is not a valid day")
            }
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
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }

    func endOfDay() -> Date {
        let components = DateComponents(day: 1, second: -1)
        return Calendar.current.date(byAdding: components, to: self.startOfDay())!
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

