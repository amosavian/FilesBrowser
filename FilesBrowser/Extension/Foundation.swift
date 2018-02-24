//
//  Foundation.swift
//  FilesBrowser
//
//  Created by Amir Abbas on 12/5/1396 AP.
//  Copyright © 1396 AP Mousavian. All rights reserved.
//

import Foundation

extension Int64 {
    var formatByte: String {
        if self < 0 {
            return NSLocalizedString("Unknown size", comment: "unknown file size")
        }
        return ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
    
    var formatByteFull: String {
        if self < 0 {
            return NSLocalizedString("Unknown size", comment: "unknown file size")
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.includesActualByteCount = true
        return formatter.string(fromByteCount: self)
    }
    
    var formatBinaryByte: String {
        if self < 0 {
            return NSLocalizedString("Unknown size", comment: "unknown file size")
        }
        return ByteCountFormatter.string(fromByteCount: self, countStyle: .binary)
    }
}

extension Date {
    init ? (string: String, withFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") {
        let dateFor: DateFormatter = DateFormatter()
        dateFor.dateFormat = withFormat
        dateFor.locale = Locale(identifier: "en_US")
        if let date = dateFor.date(from: string) {
            self.init(timeIntervalSince1970: date.timeIntervalSince1970)
        } else {
            return nil
        }
    }
    
    func format(_ dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss:SSS") -> String {
        let dateFor: DateFormatter = DateFormatter()
        dateFor.dateFormat = dateFormat
        return dateFor.string(from: self)
    }
    
    func format(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, separator: String = ", ") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
        let date = formatter.string(from: self)
        formatter.dateStyle = .none
        formatter.timeStyle = timeStyle
        let time = formatter.string(from: self)
        return "\(date)\(separator)\(time)"
    }
}

extension TimeInterval {
    func format(timeStyle: DateComponentsFormatter.UnitsStyle) -> String {
        var result = NSLocalizedString("Unknown interval", comment: "unknown interval")
        guard self.isFinite, self < Double(Int.max) else {
            return result
        }
        var time = DateComponents()
        time.second = Int(self)
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.calendar = Locale.current.calendar
        dateComponentsFormatter.unitsStyle = timeStyle
        dateComponentsFormatter.allowedUnits = [.day, .hour, .minute, .second]
        result = dateComponentsFormatter.string(from: self) ?? ""
        return result
    }
    
    var formatshort: String {
        var result = "0:00"
        if self < TimeInterval(Int32.max) {
            result = ""
            var time = DateComponents()
            time.hour   = Int(self / 3600)
            time.minute = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
            time.second = Int(self.truncatingRemainder(dividingBy: 60))
            let formatter = NumberFormatter()
            formatter.paddingCharacter = "0"
            formatter.minimumIntegerDigits = 2
            formatter.maximumFractionDigits = 0
            formatter.locale = Locale.current
            let formatterFirst = NumberFormatter()
            formatterFirst.maximumFractionDigits = 0
            formatterFirst.locale = Locale.current
            if time.hour! > 0 {
                result = "\(formatterFirst.string(from: NSNumber(value: time.hour!))!):\(formatter.string(from: NSNumber(value: time.minute!))!):\(formatter.string(from: NSNumber(value: time.second!))!)"
            } else {
                result = "\(formatterFirst.string(from: NSNumber(value: time.minute!))!):\(formatter.string(from: NSNumber(value: time.second!))!)"
            }
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
        return result
    }
}
