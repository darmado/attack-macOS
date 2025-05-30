# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-05-29

### Added
- **T1087.003 Email Discovery** (`ttp/discovery/accounts/emails.yml`)
  - `discover_messages_emails()` - Queries Messages Database chat.db for email addresses
  - `discover_entities_emails()` - Extracts emails from entities.db contactDetails and emailMetadata
  - `discover_whatsapp_emails()` - Finds email addresses in WhatsApp ChatStorage.sqlite ZTEXT content
  - Returns 164+ unique email addresses from 3 verified database sources

- **Build System Enhancements** (`tools/build_shell_procedure.py`)
  - Fixed IndentationError at line 239
  - Added YAML validation for 'procedure' field requirement
  - GUID lowercase enforcement for schema compliance

### Changed
- **Email Discovery Database Queries**
  - Optimized SQL queries to SELECT DISTINCT email_address only
  - Removed metadata columns causing duplicate results
  - Changed echo to printf for proper \n handling

### Fixed
- **YAML Schema Validation**
  - Fixed missing 'procedure' field (was 'procedures')
  - Fixed uppercase GUID validation (changed to lowercase)
  - Fixed path expansion (~/ to $HOME/)
  - Removed duplicate procedure sections

- **Output Formatting**
  - Fixed literal \n characters in email discovery output
  - Standardized printf usage following browser_history.yml pattern

### Technical Notes
- Database paths use $HOME/Library/... format for portability
- All queries use native SQLite3 with error handling
- Build system validates YAML against procedure.schema.json 