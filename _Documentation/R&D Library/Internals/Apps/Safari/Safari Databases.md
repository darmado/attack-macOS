# Safari Databases Reference

This document provides an overview of the database structures used by Safari on macOS.

## CloudExtensions.db

### cloud_extension_devices

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| device_uuid | TEXT | Yes | Yes | |
| system_fields | BLOB | Yes | | |
| device_name | TEXT | | | |
| last_modified | REAL | Yes | | |
| new_tab_page_composed_identifier | TEXT | | | |
| new_tab_page_set_by_user_gesture | BOOLEAN | | | 0 |
| new_tab_page_last_modified | REAL | Yes | | |

### cloud_extension_states

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| record_name | TEXT | Yes | Yes | |
| composed_identifier | TEXT | Yes | | |
| system_fields | BLOB | Yes | | |
| owning_device_uuid | TEXT | Yes | | |
| containing_app_adam_id | TEXT | | | |
| display_name | TEXT | Yes | | |
| is_enabled | BOOLEAN | | | 0 |
| was_enabled_by_user_gesture | BOOLEAN | | | 0 |
| ios_app_bundle_identifier | TEXT | | | |
| ios_extension_bundle_identifier | TEXT | | | |
| mac_app_bundle_identifier | TEXT | | | |
| mac_extension_bundle_identifier | TEXT | | | |
| last_modified | REAL | Yes | | |

### metadata

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| key | TEXT | Yes | | |
| value | | | | |

## CloudTabs.db

### cloud_tab_close_requests

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| close_request_uuid | TEXT | Yes | Yes | |
| system_fields | BLOB | Yes | | |
| destination_device_uuid | TEXT | Yes | | |
| url | TEXT | Yes | | |
| tab_uuid | TEXT | Yes | | |

### cloud_tabs

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| tab_uuid | TEXT | Yes | Yes | |
| system_fields | BLOB | Yes | | |
| device_uuid | TEXT | Yes | | |
| position | BLOB | Yes | | |
| title | TEXT | | | |
| url | TEXT | Yes | | |
| is_showing_reader | BOOLEAN | | | 0 |
| is_pinned | BOOLEAN | | | 0 |
| reader_scroll_position_page_index | INTEGER | | | |
| scene_id | TEXT | | | |

### cloud_tab_devices

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| device_uuid | TEXT | Yes | Yes | |
| system_fields | BLOB | Yes | | |
| device_name | TEXT | | | |
| has_duplicate_device_name | BOOLEAN | | | 0 |
| is_ephemeral_device | BOOLEAN | | | 0 |
| last_modified | REAL | Yes | | |

### metadata

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| key | TEXT | Yes | | |
| value | | | | |

## SafariTabs.db

### bookmark_title_words

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| bookmark_id | INTEGER | Yes | | |
| word | TEXT | | | |
| word_index | INTEGER | | | |

### generations

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| generation | INTEGER | Yes | | |

### windows

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| active_tab_group_id | INTEGER | | | NULL |
| date_closed | REAL | | | NULL |
| extra_attributes | BLOB | | | NULL |
| is_last_session | INTEGER | | | 0 |
| local_tab_group_id | INTEGER | | | NULL |
| private_tab_group_id | INTEGER | | | NULL |
| scene_id | TEXT | | | NULL |
| uuid | TEXT | Yes | | |

### bookmarks

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| special_id | INTEGER | | | 0 |
| parent | INTEGER | | | |
| type | INTEGER | | | |
| title | TEXT | | | |
| url | TEXT | | | |
| num_children | INTEGER | | | 0 |
| editable | INTEGER | | | 1 |
| deletable | INTEGER | | | 1 |
| hidden | INTEGER | | | 0 |
| hidden_ancestor_count | INTEGER | | | 0 |
| order_index | INTEGER | Yes | | |
| external_uuid | TEXT | | | |
| read | INTEGER | | | NULL |
| last_modified | REAL | | | NULL |
| server_id | TEXT | | | |
| sync_key | TEXT | | | |
| sync_data | BLOB | | | |
| added | INTEGER | | | 1 |
| deleted | INTEGER | | | 0 |
| extra_attributes | BLOB | | | NULL |
| local_attributes | BLOB | | | NULL |
| fetched_icon | BOOL | | | 0 |
| icon | BLOB | | | NULL |
| dav_generation | INTEGER | | | 0 |
| locally_added | BOOL | | | 0 |
| archive_status | INTEGER | | | 0 |
| syncable | BOOL | | | 1 |
| web_filter_status | INTEGER | | | 0 |
| modified_attributes | UNSIGNED BIG INT | | | 0 |
| date_closed | REAL | | | NULL |
| last_selected_child | INTEGER | | | NULL |
| subtype | INTEGER | | | 0 |

### participant_presence

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| participant_id | TEXT | | | |
| tab_group_server_id | TEXT | | | |
| tab_server_id | TEXT | | | |

### windows_tab_groups

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| active_tab_id | INTEGER | | | NULL |
| tab_group_id | INTEGER | Yes | | |
| window_id | INTEGER | Yes | | |

### folder_ancestors

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| id | INTEGER | | Yes | |
| folder_id | INTEGER | Yes | | |
| ancestor_id | INTEGER | Yes | | |

### sync_properties

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| key | TEXT | Yes | | |
| value | TEXT | Yes | | |

## SandboxExtensions.db

### sandbox_extensions

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| path_id | INTEGER | | Yes | |
| path | TEXT | Yes | | |
| extension | BLOB | Yes | | |
| permissions | INTEGER | Yes | | |

### sandbox_references

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| reference_id | INTEGER | | Yes | |
| category | INTEGER | Yes | | |
| foreign_id | TEXT | | | |
| date | REAL | | | |

### sandbox_extensions_for_references

| Column | Type | Not Null | Primary Key | Default |
|--------|------|----------|-------------|---------|
| path_id | INTEGER | | | |
| reference_id | INTEGER | | | |