Plank
=====

What is Plank?
--------------
Plank is a lightweight logging framework for the Swift programming language that allows gating of log messages as a function of build configuration.

## Requirements

- iOS 7.0+ / Mac OS X 10.10+
- Xcode 6.1

## Installation

_Due to the current lack of [proper infrastructure](http://cocoapods.org) for Swift dependency management, using Plank in your project requires the following steps:_

1. Add Plank as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the command `git submodule add https://github.com/banDedo/Plank`
2. Open the `Plank` folder, and drag `Plank.xcodeproj` into the file navigator of your Xcode project.
3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
4. In the tab bar at the top of that window, open the "Build Phases" panel.
5. Expand the "Link Binary with Libraries" group, and add `Plank.framework`.
6. Click on the `+` button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `Plank.framework`.

## Usage

  Plank provides a hook to filter logs based on level.
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



