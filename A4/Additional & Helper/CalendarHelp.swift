//
//  CalendarHelp.swift
//  A4
//
// Reference: https://github.com/codeWithCal/CalendarExampleTutorial/blob/main/CalendarExampleTutorial/CalendarHelper.swift
//
//  Created by Yenny Fransisca Halim on 04/06/24.
//

import Foundation
import UIKit

/**
 CalendarHelp provides utility functions for working with dates and the calendar.
 */
class CalendarHelp {
    let calendar = Calendar.current // The current calendar instance used for date calculations
    
    /**
     Increases the given date by one month.
     - Parameters:
       - date: The date to increase.
     - Returns: A new `Date` object increased by one month.
     */
    func increaseMonth(date: Date) -> Date{
        return calendar.date(byAdding: .month, value: 1, to: date)!
    }
    
    /**
     Decreases the given date by one month.
     - Parameters:
       - date: The date to decrease.
     - Returns: A new `Date` object decreased by one month.
     */
    func decreaseMonth(date: Date) -> Date{
        return calendar.date(byAdding: .month, value: -1, to: date)!
    }
    
    /**
     Gets the month name for the given date.
     - Parameters:
       - date: The date to get the month name from.
     - Returns: A `String` representing the month name.
     */
    func monthString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
        return dateFormatter.string(from: date)
    }
    
    /**
    Gets the year as a string for the given date.
    - Parameters:
      - date: The date to get the year from.
    - Returns: A `String` representing the year.
    */
    func yearString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: date)
    }
    
    /**
     Gets the number of days in the month of the given date.
     - Parameters:
       - date: The date to get the number of days from.
     - Returns: An `Int` representing the number of days in the month.
     */
    func daysInMonth(date: Date) -> Int{
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    /**
     Gets the day of the month for the given date.
     - Parameters:
       - date: The date to get the day of the month from.
     - Returns: An `Int` representing the day of the month.
     */
    func dayOfMonth(date: Date) -> Int{
        let components = calendar.dateComponents([.day], from: date)
        return components.day!
    }
    
    /**
     Gets the first date of the month for the given date.
     - Parameters:
       - date: The date to get the first date of the month from.
     - Returns: A `Date` object representing the first date of the month.
     */
    func firstOfMonth(date: Date) -> Date{
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }
    
    /**
     Gets the weekday of the given date.
     - Parameters:
       - date: The date to get the weekday from.
     - Returns: An `Int` representing the weekday (0 for Sunday, 1 for Monday, etc.).
     */
    func weekDay(date: Date) -> Int{
        let components = calendar.dateComponents([.weekday], from: date)
        return components.weekday! - 1
    }
    
}
