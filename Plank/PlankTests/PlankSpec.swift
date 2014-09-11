//
//  PlankSpec.swift
//  Plank
//
//  Created by Patrick Hogan on 9/7/14.
//  Copyright (c) 2014 bandedo. All rights reserved.
//

import Quick
import Nimble

import Foundation
import XCTest

class PlankSpec: QuickSpec {
    var willLogNotificationListener: NotificationListener?
    var didLogNotificationListener: NotificationListener?

    private func expectNotificationMessage(message: String, synchronously: Bool) {
        var expectation1 = expect(self.willLogNotificationListener!.userInfoElement(0, key: PlankLogMessageKey) as? String)
        var expectation2 = expect(self.didLogNotificationListener!.userInfoElement(0, key: PlankLogMessageKey) as? String)
        if (synchronously) {
            expectation1.to(equal(message))
            expectation2.to(equal(message))
        } else {
            expectation1.toEventually(equal(message));
            expectation1.toEventually(equal(message));
        }
    }

    private func expectNotificationBody(bodyPart: String, synchronously: Bool) {
        var expectation1 = expect((self.willLogNotificationListener!.userInfoElement(0, key: PlankLogBodyKey) as? String) ?? "")
        var expectation2 = expect((self.didLogNotificationListener!.userInfoElement(0, key: PlankLogBodyKey) as? String) ?? "")
        if (synchronously) {
            expectation1.to(contain(bodyPart))
            expectation2.to(contain(bodyPart))
        } else {
            expectation1.toEventually(contain(bodyPart))
            expectation2.toEventually(contain(bodyPart))
        }
    }

    private func expectNotification(count: Int, synchronously: Bool) {
        if synchronously {
            expect(self.willLogNotificationListener!.notifications.count).to(equal(count))
            expect(self.didLogNotificationListener!.notifications.count).to(equal(count))
        } else {
            expect(self.willLogNotificationListener!.notifications.count).toEventually(equal(count))
            expect(self.didLogNotificationListener!.notifications.count).toEventually(equal(count))
        }
    }

    override func spec() {
        describe("a logger") {
            let message = "Test"
            let tag = "Tag"
            var logger = Plank(tag: tag)
            
            beforeEach {
                logger = Plank(tag: tag)
                self.willLogNotificationListener = NotificationListener(name: PlankWillLogNotification, object: logger)
                self.didLogNotificationListener = NotificationListener(name: PlankDidLogNotification, object: logger)
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

                self.expectNotification(1, synchronously: false)
            }
            
            it("will log synchronously") {
                logger.synchronous = true
                logger.logError(message)
                
                self.expectNotification(1, synchronously: true)
            }
            
            it("will log when over log threshold") {
                logger.thresholdLevel = .Verbose;
                logger.logError(message)
                
                self.expectNotification(1, synchronously: false)
            }

            it("will not log when under log threshold") {
                logger.thresholdLevel = .Error;
                logger.logWarning(message)
                
                self.expectNotification(0, synchronously: false)
            }

            it("will not log when disabled") {
                logger.enabled = false
                logger.logError(message)
                
                self.expectNotification(0, synchronously: false)
            }
            
            it("will not log when under log threshold") {
                logger.thresholdLevel = .Error;
                logger.logVerbose(message)
                
                self.expectNotification(0, synchronously: false)
            }
            
            it("will obey formatting") {
                logger.formatter = { (message: NSString, tag: NSString, levelString: NSString, dateFormatter: NSDateFormatter,  queue: dispatch_queue_t) in
                    return "\(message)\(tag)\(levelString)"
                }
                logger.logError(message)
                
                self.expectNotificationBody("\(message)\(tag)\(Plank.Level.Error.description)", synchronously: false)
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
}
