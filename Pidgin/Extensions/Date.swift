//
//  Date.swift
//  Pidgin
//
//  Created by Atemnkeng Fontem on 2/11/20.
//  Copyright © 2020 Atemnkeng Fontem. All rights reserved.
//

import Foundation

extension Date {

func getElapsedInterval() -> String {

    let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self, to: Date())

    if let year = interval.year, year > 0 {
        return year == 1 ? "\(year)" + " " + "year ago" :
            "\(year)" + " " + "years ago"
    } else if let month = interval.month, month > 0 {
        return month == 1 ? "\(month)" + " " + "month ago" :
            "\(month)" + " " + "months ago"
    } else if let day = interval.day, day > 0 {
        return day == 1 ? "\(day)" + " " + "day ago" :
            "\(day)" + " " + "days ago"
    }else if let hour = interval.hour, hour > 0{
        return hour == 1 ? "\(hour)" + " " + "hour ago" :
        "\(hour)" + " " + "hours ago"
    }else if let minute = interval.minute, minute > 0{
        return minute == 1 ? "\(minute)" + " " + "minute ago" :
        "\(minute)" + " " + "minutes ago"
    } else {
        return "just now"

    }

}
    

        func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {

            let currentCalendar = Calendar.current

            guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
            guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }

            return end - start
        }
    
}
