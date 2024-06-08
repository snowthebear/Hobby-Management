//
//  CalendarListResponse.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 16/05/24.
//

import Foundation
import GoogleAPIClientForREST


/**
 Represents the response from the Google Calendar API containing a list of calendars.
 */
struct CalendarListResponse: Codable {
    let kind: String
    let etag: String
    let nextSyncToken: String?
    let items: [CalendarListEntry]
}

/**
 Represents an entry in the calendar list.
 */
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

/**
 Represents a reminder for an event.
 */
struct Reminder: Codable {
    let method: String
    let minutes: Int
}

/**
 Represents the notification settings for a calendar.
 */
struct NotificationSettings: Codable {
    let notifications: [Notification]
}

/**
 Represents a notification for a calendar event.
 */
struct Notification: Codable {
    let type: String
    let method: String
}

/**
 Represents the conference properties of a calendar.
 */
struct ConferenceProperties: Codable {
    let allowedConferenceSolutionTypes: [String]
}
