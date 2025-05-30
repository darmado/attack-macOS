# CoreServices API: MDQuery for TCC Permission Checking

## Overview
The MDQuery API, part of the CoreServices framework, can be used to indirectly check for TCC (Transparency, Consent, and Control) permissions, particularly Full Disk Access (FDA).

## Key Functions

### MDQueryCreate
Creates a query that can search for files based on metadata attributes.

Syntax:
```javascript
$.MDQueryCreate($(), $(queryString), $(), $())
```

### MDQueryExecute
Executes the created query.

Syntax:
```javascript
$.MDQueryExecute(query, options)
```

### MDQueryGetResultCount
Returns the number of results found by the query.

Syntax:
```javascript
$.MDQueryGetResultCount(query)
```

## TCC Permission Checking Behavior

When using MDQuery to search for TCC database files:

1. If the script has Full Disk Access:
   - MDQueryGetResultCount will return 2 (both user and system TCC databases are visible)

2. If the script does not have Full Disk Access:
   - MDQueryGetResultCount will return 0 (no TCC databases are visible)

This behavior can be used as a reliable method to check for Full Disk Access without directly accessing the TCC database files.

## Example Usage

```javascript
function checkFullDiskAccess() {
    const queryString = "kMDItemDisplayName = *TCC.db";
    let query = $.MDQueryCreate($(), $(queryString), $(), $());
    
    if ($.MDQueryExecute(query, 1)) {
        let resultCount = $.MDQueryGetResultCount(query);
        return resultCount === 2;
    }
    return false;
}
```

## Security Considerations

Using MDQuery for TCC permission checking is less likely to trigger security alerts compared to direct file access attempts. However, be aware that frequent or unusual query patterns may still be detectable by security software.

