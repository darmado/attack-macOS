# Lessons Learned: Working with JXA

Working with JavaScript for Automation (JXA) can be an enjoyable experience, but it comes with its own set of challenges and nuances. Here are some key lessons learned:

## Specific Differences

### CFMakeCollectable Usage

- **Correct:** `let item_o_c = $.CFMakeCollectable(items[0]);`
- **Incorrect:** `let item_o_c = $.CFMakeCollectable(items[0]).js;`

### Array Access

- **Correct:** `item_o_c.count()` and `item_o_c.objectAtIndex(i)`
- **Incorrect:** `item_o_c.length` and `item_o_c[i]`

## Why It Matters

1. **Memory Access:** Treating Core Foundation (CF) objects as JavaScript arrays can lead to invalid memory access, potentially causing a segmentation fault.

2. **Object Methods:** Using the correct methods ensures that the script interacts with the underlying CF objects properly, respecting their memory layout and access patterns.

## Resolution

By aligning the handling of CF objects in `keychain.js` with the correct approach used in `locksmith.js`, we successfully resolved the segmentation fault issue.