//
//  Event.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 15/05/24.
//

import Foundation

struct EventsResponse: Codable {
    let items: [Event]
}

struct Event: Codable {
    let summary: String?
    let start: EventDateTime?
    let end: EventDateTime?
}

struct EventDateTime: Codable {
    let dateTime: String?
    let date: String?
}
