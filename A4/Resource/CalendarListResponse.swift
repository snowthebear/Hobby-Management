//
//  CalendarListResponse.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 16/05/24.
//

import Foundation
import GoogleAPIClientForREST


struct CalendarListResponse: Codable {
    let kind: String
    let etag: String
    let nextSyncToken: String?
    let items: [CalendarListEntry]
}

struct CalendarListEntry: Codable {
    let kind: String
    let etag: String
    let id: String
    let summary: String
    let description: String?
    let timeZone: String
    let colorId: String
    let backgroundColor: String
    let foregroundColor: String
    let selected: Bool
    let accessRole: String
    let defaultReminders: [Reminder]
    let notificationSettings: NotificationSettings?
    let primary: Bool?
    let conferenceProperties: ConferenceProperties
}

struct Reminder: Codable {
    let method: String
    let minutes: Int
}

struct NotificationSettings: Codable {
    let notifications: [Notification]
}

struct Notification: Codable {
    let type: String
    let method: String
}

struct ConferenceProperties: Codable {
    let allowedConferenceSolutionTypes: [String]
}
