//
//  CalendarViewController.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation
import UIKit


class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var events: [Event] = [] // t holds data relevant to the calendar events
    var accessToken: String? // This needs to be set from the login flow
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        // Register cell class if not using a storyboard or if the cells are created programmatically
        
        collectionView.isScrollEnabled = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CalendarCell")
        
        if let token = accessToken {
            fetchCalendarEvents(token: token)
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Return the number of days in the month
//        return 30 // Example: September would have 30 days
        return events.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarCell", for: indexPath)
        
        // Configure the cell
        if let eventCell = cell as? EventCollectionViewCell {  // Change this line if you're using a standard cell
            eventCell.titleLabel.text = events[indexPath.row].title
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            eventCell.startTimeLabel.text = formatter.string(from: events[indexPath.row].startTime)
        } else {
            // Fallback for standard cell (if you're not using a custom cell)
            cell.textLabel?.text = "\(events[indexPath.row].title) at \(events[indexPath.row].startTime)"
        }

        return cell
    }

    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
    
        
    func fetchCalendarEvents(token: String) {
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                return
            }

            // Parse JSON and update the events array
            DispatchQueue.main.async {
                self.events = self.parseEventsFromData(data)
                self.collectionView.reloadData()
            }
        }

        task.resume()
    }
    
    
    func parseEventsFromData(_ data: Data) -> [Event] {
            do {
                // Assuming you decode a JSON response into an array of Event objects
                let decoder = JSONDecoder()
                let eventData = try decoder.decode([Event].self, from: data)
                return eventData
            } catch {
                print("Error parsing data: \(error)")
                return []
            }
        }

}


struct Event: Codable {
    var title: String
    var startTime: Date
    
    enum CodingKeys: String, CodingKey {
        case title = "summary"
        case startTime = "start"
    }
    
    enum DateCodingKeys: String, CodingKey {
        case dateTime = "dateTime"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .summary)
        
        let dateContainer = try container.nestedContainer(keyedBy: DateCodingKeys.self, forKey: .start)
        let dateString = try dateContainer.decode(String.self, forKey: .dateTime)
        
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            self.startTime = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .dateTime, in: dateContainer, debugDescription: "Date string does not conform to ISO 8601 format.")
        }
    }
}
