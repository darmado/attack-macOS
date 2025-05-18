ObjC.import('Foundation');

// Base64-encoded plist string (replace it with your actual string)
const base64String = ``;

// Step 1: Decode Base64 string to NSData
const decodedData = $.NSData.alloc.initWithBase64EncodedStringOptions(base64String, 0);

// Step 2: Deserialize NSData to NSDictionary or NSArray
const plist = $.NSPropertyListSerialization.propertyListWithDataOptionsFormatError(
    decodedData,
    0,
    null,
    null
);

// Step 3: Convert to JavaScript object
const jsObject = ObjC.deepUnwrap(plist);

// Output the JavaScript object to see its content
console.log(JSON.stringify(jsObject, null, 2));
