# Bash Script Code Guide for MacOS Security Tools

### Description
This document outlines the coding guide and best practices for developing Bash scripts for MacOS security tools. It provides guidelines to ensure consistency, readability, and maintainability across the project.

> **Note:** The code in `util/_templates/utility.sh` serves as a template and should not be modified. The guide below apply to new scripts created from this template.

##

### Purpose
The purpose of these guide is to:
1. Standardize coding practices across the project
2. Improve code readability and maintainability
3. Enhance security and reliability of the scripts
4. Facilitate easier collaboration among team members

##

### Assumptions
- Developers have basic knowledge of Bash scripting
- Scripts are intended for use on MacOS systems
- The project uses MITRE ATT&CK framework for technique classification

##

### Guide


### JXA and Swift Code Guide

1. Prioritize API Usage:
   Always use the native macOS APIs as the first choice, followed by POSIX-compliant methods. Avoid command-line tools whenever possible.

   Rationale: Native APIs provide better performance, reliability, and integration with the macOS ecosystem. They also reduce the risk of detection by security software that may monitor command-line activities.

   Example (JXA):
   ```javascript
   // Preferred: Using NSFileManager API
   var fileManager = $.NSFileManager.defaultManager;
   var homeDirectory = fileManager.homeDirectoryForCurrentUser.path.js;

   // Avoid: Using shell command
   // var homeDirectory = $.NSString.stringWithString('echo $HOME').js;
   ```

   Example (Swift):
   ```swift
   // Preferred: Using FileManager API
   let fileManager = FileManager.default
   let homeDirectory = fileManager.homeDirectoryForCurrentUser.path

   // Avoid: Using shell command
   // let homeDirectory = shell("echo $HOME")
   ```

2. Leverage Objective-C Bridge:
   In JXA, make extensive use of the Objective-C bridge to access powerful macOS frameworks.

   Example:
   ```javascript
   ObjC.import('Foundation')
   
   // Using NSProcessInfo to get system information
   var processInfo = $.NSProcessInfo.processInfo;
   var osVersion = processInfo.operatingSystemVersionString.js;
   var processorCount = processInfo.processorCount;
   ```

3. Use Swift for Performance-Critical Tasks:
   When performance is crucial, consider implementing those parts in Swift and bridging them to JXA.

   Example:
   ```swift
   // Swift function for intensive computation
   @objc class Compute: NSObject {
       @objc func intensiveTask(_ input: String) -> String {
           // Perform intensive computation
           return result
       }
   }
   ```

   JXA:
   ```javascript
   ObjC.import('Compute')
   var compute = $.Compute.alloc.init
   var result = compute.intensiveTaskWithString('input')
   ```

4. Prefer Asynchronous Operations:
   Use asynchronous operations when dealing with I/O or network operations to keep the script responsive.

   Example (JXA):
   ```javascript
   function fetchDataAsync(url, callback) {
       var request = $.NSURLRequest.requestWithURL($.NSURL.URLWithString(url));
       var queue = $.NSOperationQueue.mainQueue;
       $.NSURLConnection.sendAsynchronousRequestQueueCompletionHandler(request, queue, function(response, data, error) {
           if (error) {
               callback(null, error);
           } else {
               var result = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
               callback(result, null);
           }
       });
   }
   ```

5. Handle Errors Gracefully:
   Implement robust error handling to gracefully manage unexpected situations and provide meaningful feedback.

   Example (Swift):
   ```swift
   do {
       let data = try Data(contentsOf: fileURL)
       // Process data
   } catch let error as NSError {
       print("Error reading file: \(error.localizedDescription)")
   }
   ```

These guide aim to leverage the full power of macOS while maintaining efficiency, reliability, and stealth in your JXA and Swift code for security tools.





### References
1. MITRE ATT&CK Framework: https://attack.mitre.org/
