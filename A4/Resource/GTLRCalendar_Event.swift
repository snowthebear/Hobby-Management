//
//  GTLRCalendar_Event.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation
import GoogleAPIClientForREST

struct EventsResponse: Codable {
    let items: [GTLRCalendar_Event]
}

struct GTLRCalendar_Event: Codable {
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

struct EventDateTime: Codable {
    let dateTime: String?
    let date: String?
}
