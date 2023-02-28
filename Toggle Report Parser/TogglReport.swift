//
//  TogglReport.swift
//  Toggle Report Parser
//
//  Created by Alexander Kormanovsky on 28.02.2023.
//

import Foundation

struct TogglReport : CustomStringConvertible {
    
    static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    static var hoursFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }
    
    var periodStartDate: Date?
    var periodEndDate: Date?
    var totalHours: DateComponents?
    
    var totalSeconds: Int {
        guard let totalHours = totalHours else { return 0 }
        return (totalHours.hour ?? 0) * 3600 + (totalHours.minute ?? 0) * 60 + (totalHours.second ?? 0)
    }
    
    var totalDecimalHours: Double {
        Double(totalSeconds) / 3600.0
    }
    
    var totalHoursString: String {
        (totalHours == nil) ? "Undefined" : Self.hoursFormatter.string(from: totalHours!)!
    }
    
    var periodStartString: String {
        (periodStartDate == nil)
        ? "Start date undefined"
        : Self.formatter.string(from: periodStartDate!)
    }
    
    var periodEndString: String {
        (periodStartDate == nil)
        ? "End date undefined"
        : Self.formatter.string(from: periodEndDate!)
    }
    
    var description: String {
        return "Period: \(periodStartString) - \(periodEndString), total hours: \(totalHoursString)"
    }
    
}
