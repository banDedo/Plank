//
//  LoggerSpec.swift
//  Plank
//
//  Created by Patrick Hogan on 9/7/14.
//  Copyright (c) 2014 bandedo. All rights reserved.
//

import Quick
import Nimble

import Foundation
import XCTest

var loggerDelegate: LoggerTestDelegate!
var logger: Logger!

let message = "Test"
let tag = "Tag"

class LoggerSpec: QuickSpec {
    override func spec() {
        describe("a logger") {
            beforeEach {
                loggerDelegate = LoggerTestDelegate()
                logger = Logger(tag: tag, delegate: loggerDelegate)
            }
            
            it("will log verbose") {
                logger.thresholdLevel = .Verbose
                logger.logVerbose(message)
                
                self.expectNotificationMessage(message, synchronously: false)
            }

            it("will log info") {
                logger.thresholdLevel = .Info
                logger.logInfo(message)
                
                self.expectNotificationMessage(message, synchronously: false)
            }

            it("will log warning") {
                logger.thresholdLevel = .Warning
                logger.logWarning(message)
                
                self.expectNotificationMessage(message, synchronously: false)
            }

            it("will log error") {
                logger.thresholdLevel = .Error
                logger.logError(message)
                
                self.expectNotificationMessage(message, synchronously: false)
            }

            it("will include tag in log") {
                logger.synchronous = true
                logger.logError(message)
                
                self.expectNotificationBody(tag, synchronously: true)
            }

            it("will log asynchronously") {
                logger.synchronous = false
                logger.logError(message)
                
                self.expectNotification(0, synchronously: true)
                self.expectNotification(1, synchronously: false)
            }
            
            it("will log synchronously") {
                logger.synchronous = true
                logger.logError(message)
                
                self.expectNotification(1, synchronously: true)
            }
            
            it("will log when over log threshold") {
                logger.thresholdLevel = .Verbose
                logger.logError(message)
                
                self.expectNotification(1, synchronously: false)
            }

            it("will not log when under log threshold") {
                logger.thresholdLevel = .Error
                logger.logWarning(message)
                
                self.expectNotification(0, synchronously: false)
            }

            it("will not log when disabled") {
                logger.enabled = false
                logger.logError(message)
                
                self.expectNotification(0, synchronously: false)
            }
            
            it("will not log when under log threshold") {
                logger.thresholdLevel = .Error
                logger.logVerbose(message)
                
                self.expectNotification(0, synchronously: false)
            }
            
            it("will obey formatting") {
                logger.formatter = { (message: String, tag: String, levelString: String, function: String, file: String, line: Int) in
                    return "\(message)\(tag)\(levelString)"
                }
                logger.logError(message)
                
                self.expectNotificationBody("\(message)\(tag)\(Logger.Level.Error.description)", synchronously: false)
            }
            
            it("post notifications indicating that it will and did log messages, including message in body") {
                logger.logError(message)
                
                self.expectNotification(1, synchronously: false)
                self.expectNotificationMessage(message, synchronously: false)
                self.expectNotificationBody(message, synchronously: false)
            }

            it("will call completion handler on synchronous logs") {
                var called = false
                logger.synchronous = true
                logger.logError(message) {
                    called = true
                }
                expect(called).to(equal(true))
            }

            it("will call completion handler on asynchronous logs") {
                var called = false
                logger.synchronous = false
                logger.logError(message) {
                    called = true
                }
                expect(called).toEventually(equal(true))
            }
        }
    }
    
    private func expectNotificationMessage(message: String, synchronously: Bool) {
        var expectation = expect(loggerDelegate.message)
        if synchronously {
            expectation.to(equal(message))
        } else {
            expectation.toEventually(equal(message))
        }
    }
    
    private func expectNotificationBody(bodyPart: String, synchronously: Bool) {
        var expectation = expect(loggerDelegate.body ?? "")
        if synchronously {
            expectation.to(contain(bodyPart))
        } else {
            expectation.toEventually(contain(bodyPart))
        }
    }
    
    private func expectNotification(count: Int, synchronously: Bool) {
        var expectation = expect(loggerDelegate.fireCount)
        if synchronously {
            expectation.to(equal(count))
        } else {
            expectation.toEventually(equal(count))
        }
    }
}

class LoggerTestDelegate: LoggerDelegate {
    var fireCount: Int?
    var message: String?
    var body: String?
    
    init() {
        fireCount = 0
    }
    
    func logger(logger: Logger, didLog message: String, body: String) {
        self.message = message
        self.body = body
        fireCount!++
    }
}
