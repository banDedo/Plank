//
//  Plank.swift
//  Plank
//
//  Created by Patrick Hogan on 6/7/14.
//  Copyright (c) 2014 Patrick Hogan. All rights reserved.
//

import Foundation

/// The name of the notification is fired on the serial logging queue before log is written.
public let PlankWillLogNotification = "PlankWillLogNotification"

/// The name of the notification is fired on the serial logging queue after log is written.
public let PlankDidLogNotification = "PlankDidLogNotification"

/// The name of the key for the value holding the unaltered log message in the notification userInfo dictionary.
public let PlankLogMessageKey = "PlankLogMessageKey"

/// The name of the key for the value holding the formatted log message in the notification userInfo dictionary.
public let PlankLogBodyKey = "PlankLogBodyKey"

@objc protocol Logger {
    var formatter: ((message: NSString, tag: NSString, levelString: NSString, dateFormatter: NSDateFormatter,  queue: dispatch_queue_t) -> NSString)? {get set}

    func logError(message: String?);
    func logWarning(message: String?);
    func logInfo(message: String?);
    func logVerbose(message: String?);
    func logError(message: String?, completion: () -> ());
    func logWarning(message: String?, completion: () -> ());
    func logInfo(message: String?, completion: () -> ());
    func logVerbose(message: String?, completion: () -> ());
}

class Plank: NSObject, Logger {
    // MARK:- Public properties
    
    /// Toggle to enable/disable logging.
    var enabled = true
    
    /// Messages that fall below the threshold level will not be logged.
    var thresholdLevel: Level = .Warning
    
    /// By default logs are asynchronous but can be performed synchronously.  This property can be used to change this behavior.
    var synchronous: Bool = false
    
    /// Assignable closure that allows caller to set the format of logged messages.  The closure should return the formatted string that one wishes to log based on the passed parameters.
    var formatter: ((message: NSString, tag: NSString, levelString: NSString, dateFormatter: NSDateFormatter,  queue: dispatch_queue_t) -> NSString)?

    // MARK:- Cleanup/Initialization

    /**
       Default constructor for class
    
       :param: tag A tag that is attached to logs output by this instance
       :returns: A Plank logger instance.
    */
    init(tag: NSString) {
        self.tag = tag
    }

    // MARK:- Level enumeration

    /**
       Messages that fall below the threshold level will not be logged.
    
       - Error: Highest level, use to log unexepected/undesired outcomes during program execution.
       - Warning: Use to log non-critical issues during program execution, for instance failed HTTP requests.
       - Info: Use to log important information during program execution, for instance responses for successful HTTP requests.
       - Verbose: Lowest level, use to log debug information during program execution.
    */
    enum Level: UInt, Printable {
        case Verbose = 0
        case Info = 1
        case Warning = 2
        case Error = 3
        
        var description: String {
            switch self {
                case Verbose:
                    return "VERBOSE"
                case Info:
                    return "INFO"
                case Warning:
                    return "WARNING"
                case Error:
                    return "ERROR"
                default:
                    return ""
            }
        }
    }
    
    // MARK:- Public logging
    
    /**
    Log message at the error level
    
    :param: message Message to log
    */
    func logError(message: String?) {
        log(message, .Error)
    }
    
    /**
    Log message at the warn level
    
    :param: message Message to log
    */
    func logWarning(message: String?) {
        log(message, .Warning)
    }
    
    /**
    Log message at the info level
    
    :param: message Message to log
    */
    func logInfo(message: String?) {
        log(message, .Info)
    }
    
    /**
    Log message at the verbose level
    
    :param: message Message to log
    */
    func logVerbose(message: String?) {
        log(message, .Verbose)
    }

    /**
       Log message at the error level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    func logError(message: String?, completion: () -> ()) {
        log(message, .Error, completion)
    }
    
    /**
       Log message at the warn level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    func logWarning(message: String?, completion: () -> ()) {
        log(message, .Warning, completion)
    }
    
    /**
       Log message at the info level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    func logInfo(message: String?, completion: () -> ()) {
        log(message, .Info, completion)
    }
    
    /**
       Log message at the verbose level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    func logVerbose(message: String?, completion: () -> ()) {
        log(message, .Verbose, completion)
    }
    
    // MARK:- Private properties

    private var tag: NSString
    private let queue = Shared.queue
    
    // MARK:- Private logging

    private func log(message: String?, _ level: Level, _ completion: (() -> ())? = nil) {
        if !self.shouldLog(tag, level) {
            return
        }

        var handler: (Void) -> Void = {
            let formattedMessage = message ?? "(null)"
            let logText = self.logText(formattedMessage, level)
            let userInfo = [ PlankLogMessageKey: formattedMessage, PlankLogBodyKey: logText ]

            NSNotificationCenter.defaultCenter().postNotificationName(PlankWillLogNotification, object: self, userInfo: userInfo)
            println(logText)
            NSNotificationCenter.defaultCenter().postNotificationName(PlankDidLogNotification, object: self, userInfo: userInfo)
            
            if completion != nil {
                completion!()
            }
        }
        
        if (synchronous) {
            dispatch_sync(queue) {
                handler()
            }
        } else {
            dispatch_async(queue) {
                handler()
            }
        }
    }

    private func logText(message: String, _ level: Level) -> String {
        if formatter != nil {
            return formatter!(message: message, tag: tag, levelString: level.description, dateFormatter: Shared.dateFormatter, queue: Shared.queue)
        }
        
        return "\(Shared.dateFormatter.stringFromDate(NSDate())) [Plank|\(Shared.bundleExecutableName)] [\(tag)|\(level)]\n\(message)\n"
    }
    
    private func shouldLog(tag: String?, _ level: Level) -> Bool {
        if !self.enabled || level.toRaw() < self.thresholdLevel.toRaw() {
            return false
        }
        
        return true
    }
    
    // MARK:- Private shared

    private struct Shared {
        static let bundleExecutableName: NSString = (NSBundle.mainBundle().infoDictionary[kCFBundleExecutableKey] ?? "Unknown") as NSString
        static let queue = dispatch_queue_create(Plank.queueName().UTF8String, DISPATCH_QUEUE_SERIAL)
        static let dateFormatter: NSDateFormatter = Plank.dateFormatter();
    }

    private class func queueName() -> NSString {
        var bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? "Unknown"
        return ("\(NSBundle.mainBundle().bundleIdentifier).logging" as NSString)
    }
    
    private class func dateFormatter() -> NSDateFormatter {
        var dateFormatter = NSDateFormatter()
        dateFormatter.formatterBehavior = .Behavior10_4
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss:SSS Z"
        return dateFormatter
    }
}

