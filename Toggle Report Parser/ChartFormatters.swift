//
//  ChartFormatters.swift
//  Toggle Report Parser
//
//  Created by Alexander Kormanovsky on 28.02.2023.
//

import Foundation
import Charts

class DatesAxisValueFormatter : AxisValueFormatter {
    
    var reports: [TogglReport]
    
    init(reports: [TogglReport]) {
        self.reports = reports
    }
    
    func stringForValue(_ value: Double, axis: Charts.AxisBase?) -> String {
        let report = reports[Int(value)]
        return "\(report.periodStartString)\n\(report.periodEndString)"
    }
    
}

class LeftAndRightHoursValueFormatter : AxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: Charts.AxisBase?) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        
        return formatter.string(from: value)!
    }
    
}

class HoursValueFormatter: ValueFormatter {
    
    func stringForValue(_ value: Double,
                        entry: Charts.ChartDataEntry,
                        dataSetIndex: Int,
                        viewPortHandler: Charts.ViewPortHandler?) -> String {
        let report = entry.data as! TogglReport
        return "\(report.totalHoursString)"
    }
    
}
