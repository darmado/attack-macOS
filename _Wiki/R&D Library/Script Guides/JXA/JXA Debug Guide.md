
# Debugging JXA

This document outlines the standard approach for implementing debugging in our JXA (JavaScript for Automation) scripts. These practices ensure consistent, scalable, and informative debugging across all our JXA implementations.

## 1. Debug Flag

All scripts should support a `--debug` flag to enable debug output.

```javascript
let DEBUG = false;

// In the argument parsing section:
if (args.containsObject("--debug")) {
    DEBUG = true;
}
```

## 2. Debug Function

Implement a standard `debug` function:

```javascript
function debug(message) {
    if (DEBUG) {
        console.log("[DEBUG] " + message);
    }
}
```

## 3. Function Entry and Exit Logging

Log the entry and exit of each function:

```javascript
function exampleFunction() {
    debug("Entering exampleFunction");
    
    // Function body
    
    debug("Exiting exampleFunction");
}
```

## 4. Variable and Object Logging

Log important variables and objects:

```javascript
debug("Variable value: " + variableName);
debug("Object contents: " + ObjC.deepUnwrap(objectName));
```

## 5. API Call Logging

Log before and after significant API calls:

```javascript
debug("Calling SecItemCopyMatching");
let status = $.SecItemCopyMatching(query, items);
debug("SecItemCopyMatching status: " + status);
```

## 6. Error Logging

Log detailed information for error conditions:

```javascript
if (status !== 0) {
    debug("Error in SecItemCopyMatching. Status: " + status);
    console.log("[-] Operation failed with error: " + status);
}
```

## 7. Object Type Logging

Log the types of important objects:

```javascript
debug("Result type: " + typeof result);
```

## 8. Conditional Debugging

Use conditional debugging for verbose output:

```javascript
if (DEBUG) {
    for (let key in complexObject) {
        debug("Key: " + key + ", Value: " + complexObject[key]);
    }
}
```

## 9. Performance Logging

For performance-critical sections, log timestamps:

```javascript
let startTime = new Date().getTime();
// ... performance-critical code ...
let endTime = new Date().getTime();
debug("Operation took " + (endTime - startTime) + " ms");
```

## 10. Consistent Formatting

Maintain consistent formatting for debug messages:

- Use square brackets to denote the debug nature: `[DEBUG]`
- Use colons to separate message parts: `"[DEBUG] Key: value"`
- Use clear, descriptive messages

## Implementation

When implementing these debugging standards:

1. Add the debug flag check in the main function or argument parsing section.
2. Implement the `debug` function at the top of the script.
3. Add debug logs throughout the script, focusing on:
   - Function entry/exit
   - Important variable values
   - API calls and their results
   - Error conditions
   - Performance-critical sections

By following these standards, we ensure that our JXA scripts have consistent, informative, and scalable debugging capabilities, making it easier to troubleshoot issues and understand script behavior.
