//
//  Logger.swift
//  Plank
//
//  Created by Patrick Hogan on 6/7/14.
//  Copyright (c) 2014 Patrick Hogan. All rights reserved.
//

import Foundation

public protocol LoggerDelegate {
    func logger(logger: Logger, didLog message: String, body: String)
}

public class Logger {
    // MARK:- Public properties
    
    /// Toggle to enable/disable logging.
    public var enabled = true
    
    /// Toggle to enable/disable system logging.
    public var systemLogEnabled = true
    
    /// Messages that fall below the threshold level will not be logged.
    public var thresholdLevel: Level = .Warning
    
    /// By default logs are asynchronous but can be performed synchronously.  This property can be used to change this behavior.
    public var synchronous: Bool = false
    
    /// Assignable closure that allows caller to set the format of logged messages.  The closure should return the formatted string that one wishes to log based on the passed parameters.
    public var formatter: ((message: String, tag: String, levelString: String, function: String, file: String, line: Int) -> String)?

    // MARK:- Cleanup/Initialization

    /**
       Default constructor for class
    
       :param: tag A tag that is attached to logs output by this instance
       :param: delegate Fields delegate callbacks for this instance
       :returns: A Plank logger instance.
    */
    public init(tag: NSString, delegate: LoggerDelegate? = nil) {
        self.tag = tag
        self.delegate = delegate
    }

    // MARK:- Level enumeration

    /**
       Messages that fall below the threshold level will not be logged.
    
       - Error: Highest level, use to log unexepected/undesired outcomes during program execution.
       - Warning: Use to log non-critical issues during program execution, for instance failed HTTP requests.
       - Info: Use to log important information during program execution, for instance responses for successful HTTP requests.
       - Verbose: Lowest level, use to log debug information during program execution.
    */
    public enum Level: Int, Printable {
        case Verbose = 0
        case Info = 1
        case Warning = 2
        case Error = 3
        
        public var description: String {
            switch self {
                case Verbose:
                    return "Verbose"
                case Info:
                    return "Info"
                case Warning:
                    return "Warning"
                case Error:
                    return "Error"
                default:
                    return ""
            }
        }
    }
    
    // MARK:- Public logging
    
    /**
       Log message at the error level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    public func logError(message: String?, _ completion: (() -> ())? = nil, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__) {
        log(message, .Error, completion, function, file, line)
    }
    
    /**
       Log message at the warn level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    public func logWarning(message: String?, _ completion: (() -> ())? = nil, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__) {
        log(message, .Warning, completion, function, file, line)
    }
    
    /**
       Log message at the info level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    public func logInfo(message: String?, _ completion: (() -> ())? = nil, function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__) {
        log(message, .Info, completion, function, file, line)
    }
    
    /**
       Log message at the verbose level
    
       :param: message Message to log
       :param: completion Closure that fires after log is complete.  This will be fired on the logging queue.
    */
    public func logVerbose(message: String?, _ completion: (() -> ())? = nil, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int = __LINE__) {
        log(message, .Verbose, completion, function, file, line)
    }
    
    // MARK:- Private properties

    private let delegate: LoggerDelegate?
    
    private var tag: NSString
    private let queue = Shared.queue

    private lazy var systemLogger: BDSystemLogger = {
        return BDSystemLogger()
    }()
    
    // MARK:- Private logging

    private func log(message: String?, _ level: Level, _ completion: (() -> ())? = nil, _ function: String, _ file: String, _ line: Int) {
        if !self.shouldLog(tag, level) {
            return
        }

        var handler: (Void) -> Void = {
            let formattedMessage = message ?? "(null)"
            let logText = self.logText(formattedMessage, level, function, file, line)

            println(logText)
            
            if self.systemLogEnabled {
                self.systemLogger.logMessage(logText, level: level.rawValue)
            }
            
            if self.delegate != nil {
                self.delegate?.logger(self, didLog: formattedMessage, body: logText)
            }
            
            if completion != nil {
                completion!()
            }
        }
        
        if synchronous {
            dispatch_sync(queue) {
                handler()
            }
        } else {
            dispatch_async(queue) {
                handler()
            }
        }
    }

    private func logText(message: String, _ level: Level, _ function: String, _ file: String, _ line: Int) -> String {
        if formatter != nil {
            return formatter!(message: message, tag: tag, levelString: level.description, function: function, file: file, line: line)
        }
        
        var formattedFileName = (file as NSString).componentsSeparatedByString("/").last as? String
        if formattedFileName == nil {
            formattedFileName = file
        }
        return "\(Shared.dateFormatter.stringFromDate(NSDate())) [\(Shared.bundleExecutableName)|Plank] [\(tag)|\(level)] [\(formattedFileName!) \(function):\(line.description)]\n\(message)\n"
    }
    
    private func shouldLog(tag: String?, _ level: Level) -> Bool {
        if !self.enabled || level.rawValue < self.thresholdLevel.rawValue {
            return false
        }
        
        return true
    }
    
    // MARK:- Private shared

    private struct Shared {
        static let bundleExecutableName: NSString = (NSBundle.mainBundle().infoDictionary?[kCFBundleExecutableKey] ?? "Unknown") as NSString
        static let queue = dispatch_queue_create(Logger.queueName().UTF8String, DISPATCH_QUEUE_SERIAL)
        static let dateFormatter: NSDateFormatter = Logger.dateFormatter();
    }

    private class func queueName() -> NSString {
        var bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? "Unknown"
        return ("\(NSBundle.mainBundle().bundleIdentifier).logging" as NSString)
    }
    
    private class func dateFormatter() -> NSDateFormatter {
        var dateFormatter = NSDateFormatter()
        dateFormatter.formatterBehavior = .Behavior10_4
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-dd-MM HH:mm:ss:SSS (z)"
        return dateFormatter
    }
}

