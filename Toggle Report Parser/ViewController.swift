//
//  ViewController.swift
//  Toggle Report Parser
//
//  Created by Alexander Kormanovsky on 27.02.2023.
//

import Cocoa
import Quartz
import Charts

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

// MARK: Formatters

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

class ViewController: NSViewController {
    
    @IBOutlet var barChartView: BarChartView!
    
    var reports = [TogglReport]()
    
    
    // MARK: Chart
    
    func outputChart() {
        
        let entries = reports.enumerated().map { i, report in
            return BarChartDataEntry(x: Double(i), y: Double(report.totalSeconds), data: report)
        }
        
        let dataSet = BarChartDataSet(entries: entries, label: "Total Hours")
        dataSet.colors = [NSUIColor.red]
        dataSet.valueFormatter = HoursValueFormatter()
        
        let data = BarChartData()
        data.append(dataSet)
        
        barChartView.xAxis.valueFormatter = DatesAxisValueFormatter(reports: reports)
        barChartView.xAxis.forceLabelsEnabled = true
        barChartView.xAxis.labelCount = entries.count
        barChartView.leftAxis.valueFormatter = LeftAndRightHoursValueFormatter()
        barChartView.rightAxis.valueFormatter = LeftAndRightHoursValueFormatter()
        barChartView.data = data
        barChartView.gridBackgroundColor = NSUIColor.white
    }
    
    // MARK: Reports
    
    func parseReports(_ urls: [URL]) {
        
        func processReport(at url: URL) {
            print("Processing report at\n\(url.path(percentEncoded: false))")
            
            guard let report = parseReport(at: url) else {
                return
            }
            
            reports.append(report)
        }
        
        reports = []
        
        for url in urls {
            if url.hasDirectoryPath { // directory
                do {
                    let fileUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [])
                    
                    for fileUrl in fileUrls {
                        
                        if fileUrl.hasDirectoryPath {
                            print("'\(fileUrl.path(percentEncoded: false))' is directory, skipping nested files")
                            continue
                        }
                        
                        processReport(at: fileUrl)
                    }
                } catch {
                    showAlert(with: error.localizedDescription)
                    break
                }
                
            } else { // file
                processReport(at: url)
            }
        }
        
        outputChart()
    }
    
    func parseReport(at url: URL) -> TogglReport? {
        let pdf = PDFDocument(url: url)
        
        guard let contents = pdf?.string else {
            print("could not get string from pdf: \(String(describing: pdf))")
            return nil
        }
        
        var report = TogglReport()
        
        // Parse dates
        
        // variant 1: 2015-11-01 - 2015-11-30
        
        var dates = parseDates(reportString: contents,
                               pattern: "(\\d{4}-\\d{2}-\\d{2}) - (\\d{4}-\\d{2}-\\d{2})",
                               dateFormat: "yyyy-MM-dd",
                               localeIdentifier: "en_US_POSIX",
                               useLocalizedDateFormat: false)
        
        if dates == nil {
            // variant 2: October 01, 2019 – October 15, 2019
            
            dates = parseDates(reportString: contents,
                               // note "–" is "en dash", not a "-" minus sign
                               pattern: "([A-Za-z]+ \\d{2}, \\d{4}) – ([A-Za-z]+ \\d{2}, \\d{4})",
                               dateFormat: "yMMMMd",
                               localeIdentifier: "en_US",
                               useLocalizedDateFormat: true)
        }
        
        if dates == nil {
            // variant 3: 03/16/2020 – 03/31/2020
            
            dates = parseDates(reportString: contents,
                               pattern: "(\\d{2}/\\d{2}/\\d{4}) – (\\d{2}/\\d{2}/\\d{4})",
                               dateFormat: "MM-dd-yyyy",
                               localeIdentifier: "en_US_POSIX",
                               useLocalizedDateFormat: false)
        }
        
        if dates == nil {
            // variant 4: 16-07-2021 - 31-07-2021
            
            dates = parseDates(reportString: contents,
                               pattern: "(\\d{2}-\\d{2}-\\d{4}) – (\\d{2}-\\d{2}-\\d{4})",
                               dateFormat: "dd-MM-yyyy",
                               localeIdentifier: "en_US_POSIX",
                               useLocalizedDateFormat: false)
        }
        
        report.periodStartDate = dates?.startDate
        report.periodEndDate = dates?.endDate
        
        if dates == nil {
            showAlert(with: "Unable to parse period dates in \(url.path(percentEncoded: false))")
            return nil
        }
        
        // Parse hours
        
        var totalHours = parseHours(reportString: contents,
                                    pattern: "Total (\\d+) h (\\d+) min")
        
        if totalHours == nil {
            totalHours = parseHours(reportString: contents,
                                    pattern: "TOTAL HOURS: (\\d+):(\\d+):(\\d+)")
        }
        
        report.totalHours = totalHours
        
        if totalHours == nil {
            showAlert(with: "Unable to parse hours in \(url.path(percentEncoded: false))")
            return nil
        }
        
        return report
    }
    
    func parseDates(reportString: String,
                    pattern: String,
                    dateFormat: String,
                    localeIdentifier: String,
                    useLocalizedDateFormat: Bool) -> (startDate: Date, endDate: Date)? {
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(reportString.startIndex..<reportString.endIndex, in: reportString)
        
        if let firstMatch = regex.firstMatch(in: reportString, range: range) {
            let startDateRange = firstMatch.range(at: 1)
            let endDateRange = firstMatch.range(at: 2)
            
            let nsString = reportString as NSString
            let startDateString = nsString.substring(with: startDateRange)
            let endDateString = nsString.substring(with: endDateRange)
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: localeIdentifier)
            
            if useLocalizedDateFormat {
                dateFormatter.setLocalizedDateFormatFromTemplate(dateFormat)
            } else {
                dateFormatter.dateFormat = dateFormat
            }
            
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let startDate = dateFormatter.date(from: startDateString)!
            let endDate = dateFormatter.date(from: endDateString)!
            
            return (startDate, endDate)
        }
        
        return nil
    }
    
    func parseHours(reportString: String,
                    pattern: String) -> DateComponents? {
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(reportString.startIndex..<reportString.endIndex, in: reportString)
        
        if let firstMatch = regex.firstMatch(in: reportString, range: range) {
            let hoursRange = firstMatch.range(at: 1)
            let minutesRange = firstMatch.range(at: 2)
            let secondsRange = (firstMatch.numberOfRanges == 4)
            ? firstMatch.range(at: 3)
            : NSMakeRange(0, 0)
            
            let nsString = reportString as NSString
            let hoursString = nsString.substring(with: hoursRange)
            let minutesString = nsString.substring(with: minutesRange)
            let secondsString = nsString.substring(with: secondsRange)
            
            var dateComponents = DateComponents()
            dateComponents.hour = Int(hoursString) ?? 0
            dateComponents.minute = Int(minutesString) ?? 0
            dateComponents.second = Int(secondsString) ?? 0
            
            return dateComponents
        }
        
        return nil
    }
    
    // MARK: Helpers
    
    func showAlert(with message: String) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = message
        alert.runModal()
    }
    
    // MARK: CSV Export
    
    /// https://stackoverflow.com/a/55870521/3004003
    func createCSV(from reports: [TogglReport]) -> String {
        let separator = ";"
        
        var csvString = "Period\(separator)Total Hours\(separator)Decimal Hours\n\n"
        
        for record in reports {
            csvString.append("\(record.periodStartString) - \(record.periodEndString)\(separator)\(record.totalHoursString)\(separator)\(record.totalDecimalHours)\n")
        }
        
        return csvString
    }
    
    func saveCSV(_ csvString: String) {
        let fileName = "Toggle Reports.csv"
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = fileName
        
        savePanel.begin { response in
            if response == .OK {
                do {
                    try csvString.write(to: savePanel.url!, atomically: true, encoding: .utf8)
                } catch {
                    self.showAlert(with: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: UI Events
    
    @IBAction func openPDFsButtonAction(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { response in
            if response == .OK {
                self.parseReports(openPanel.urls)
            }
        }
    }
    
    @IBAction func exportAsCSVButtonAction(_ sender: NSButton) {
        if reports.isEmpty {
            showAlert(with: "Open PDFs first")
            return
        }
        
        let csvString = createCSV(from: reports)
        saveCSV(csvString)
    }
    
    
}

