Plank
=====

What is Plank?
--------------
Plank is a lightweight logging framework for the Swift programming language that allows gating of log messages as a function of build configuration.  Plank provides a hook to filter logs based on level.
```swift
var logger = Plank(tag: "Tag")

logger.thresholdLevel = .Warning

logger.logWarning("This log should appear because it is at the minimum threshold and no visible tags are defined.")
logger.logInfo("This log shouldn't appear because it is set below minimum threshold.")
```

Set the desired threshold log level, by default it is set to .Warn.  With this example all logs will be recorded.
```swift
logger.thresholdLevel = .Warning
```

Turn off all logs by setting the enabled property to false:
```swift
logger.enabled = false
```

All loggers are asynchronous by default, but one can change to synchronous by setting this aptly named property:
```swift
logger.synchronous = true
```

One can execute code after asynchronous logs by attaching a trailing closure.
```swift
logger.logError(message) {
    // Do something on logging queue immediately after log is written.
}
```
**Note:** All logs are written on a serial queue.

Set the desired format of log output by setting the formatter property:
```swift
logger.formatter = { (message: String, tag: String, levelString: String, function: String, file: String, line: Int) in
    return "\(message)\(tag)\(levelString)"
}
logger.logError(message)
```

There are built in notifications broadcast before and after every log message which attached the original message and the formatted body to the userInfo:
```swift
/// The name of the notification is fired on the serial logging queue before log is written.
public let PlankWillLogNotification = "PlankWillLogNotification"

/// The name of the notification is fired on the serial logging queue after log is written.
public let PlankDidLogNotification = "PlankDidLogNotification"

/// The name of the key for the value holding the unaltered log message in the notification userInfo dictionary.
public let PlankLogMessageKey = "PlankLogMessageKey"

/// The name of the key for the value holding the formatted log message in the notification userInfo dictionary.
public let PlankLogBodyKey = "PlankLogBodyKey"
```

