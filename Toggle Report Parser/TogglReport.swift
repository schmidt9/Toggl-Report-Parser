//
//  TogglReport.swift
//  Toggle Report Parser
//
//  Created by Alexander Kormanovsky on 28.02.2023.
//

import Foundation

class TogglReport {
    
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
    
    static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .gmt
        return calendar
    }
    
    var periodStartDate: Date!
    var periodEndDate: Date!
    var totalHoursInterval: Int = 0
    
    // MARK: Helpers
    
    var totalPeriodInterval: TimeInterval {
        periodEndDate.timeIntervalSince(periodStartDate)
    }
    
    var totalHours: DateComponents {
        let date1 = Date()
        let date2 = Date(timeInterval: TimeInterval(totalHoursInterval), since: date1)
        return Self.calendar.dateComponents([.hour, .minute, .second], from: date1, to: date2)
    }
    
    var totalDecimalHours: Double {
        Double(totalHoursInterval) / 3600.0
    }
    
    var totalHoursString: String {
        Self.hoursFormatter.string(from: totalHours)!
    }
    
    var periodStartDateComponents: DateComponents {
        return Self.calendar.dateComponents([.year, .month, .day], from: periodStartDate)
    }
    
    var periodEndDateComponents: DateComponents {
        return Self.calendar.dateComponents([.year, .month, .day], from: periodEndDate)
    }
    
    var belongsToOneMonth: Bool {
        periodStartDateComponents.month! == periodEndDateComponents.month! &&
        periodStartDateComponents.year! == periodEndDateComponents.year!
    }
    
    var periodStartString: String {
        Self.formatter.string(from: periodStartDate)
    }
    
    var periodEndString: String {
        Self.formatter.string(from: periodEndDate)
    }
    
    func belongsToOneMonth(with otherReport: TogglReport) -> Bool {
        belongsToOneMonth &&
        otherReport.belongsToOneMonth &&
        periodStartDateComponents.month! == otherReport.periodStartDateComponents.month! &&
        periodStartDateComponents.year! == otherReport.periodStartDateComponents.year!
    }
    
    func setTotalHoursInterval(with hours: Int, minutes: Int, seconds: Int) {
        totalHoursInterval = hours * 3600 + minutes * 60 + seconds
    }
    
}

extension TogglReport: CustomStringConvertible {
    
    var description: String {
        return "Period: \(periodStartString) - \(periodEndString), total hours: \(totalHoursString)"
    }
    
}

class CombinedTogglReport: TogglReport {
    
    private (set) var reports = [TogglReport]()
    
    init(with report: TogglReport) {
        super.init()
        
        reports.append(report)
        
        periodStartDate = report.periodStartDate
        periodEndDate = report.periodEndDate
        totalHoursInterval = report.totalHoursInterval
    }
    
    func addReport(_ report: TogglReport) {
        reports.append(report)
        
        
        
        totalHoursInterval += report.totalHoursInterval
    }
    
}
