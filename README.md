Plank
=====

What is Plank?
--------------
Plank is a lightweight logging framework for the Swift programming language that allows gating of log messages as a function of build configuration.  Plank provides a hook to filter logs based on level.
```swift
let logger = Plank.Logger(tag: "Tag")

logger.thresholdLevel = .Warning

logger.logWarning("This log should appear because it is at the minimum threshold.")
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

For the given log statement:
```swift
let logger = Plank.Logger(tag: "JSON")
logger.logError("{\"foo\":\"bar\"}")
```
the console output will look something like this:
```
2014-14-09 18:54:11:424 (GMT) [Test|Plank] [JSON|Error] [ViewController.swift viewDidLoad():18]
{"foo":"bar"}
```

You can change the format of log output by setting the formatter property, *e.g.*:
```swift
logger.formatter = { (message: String, tag: String, levelString: String, function: String, file: String, line: Int) in
    return "[\(tag)|\(levelString)]\n\(message)"
}
logger.logError(message)
```

Optionally, one can pass a delegate to the logger in its constructor.  The delegate can be used to monitor logging activity.  This is useful for keeping a buffer of recently logged messages or writing to a file when necessary.
```swift
public protocol LoggerDelegate {
    func logger(logger: Logger, didLog message: String, body: String)
}

var loggerDelegate: LoggerDelegate?
loggerDelegate = ...
let logger = Logger(tag: tag, delegate: loggerDelegate!)

```



