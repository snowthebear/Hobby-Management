//
//  GTLRCalendar_Event.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation
import GoogleAPIClientForREST

/**
 Represents the response from the Google Calendar API containing a list of events.
 */
struct EventsResponse: Codable {
    let items: [GTLRCalendar_Event] // array of `GTLRCalendar_Event` objects representing the calendar events
}

/**
 Represents an event in the Google Calendar.
 */
struct GTLRCalendar_Event: Codable {
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

/**
 Represents the date and time information for an event.
 */
struct EventDateTime: Codable {
    let dateTime: String? // the date and time in ISO 8601 format, if the event is not an all-day event
    let date: String? // the date in YYYY-MM-DD format, if the event is an all-day event
}
