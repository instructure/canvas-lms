Attachment
==============

<h2 id="attachment_created">attachment_created</h2>

**Definition:** The event is emitted anytime a new file is uploaded by an end user or API request.

**Trigger:** Triggered anytime a file is uploaded into a course or user file directory.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "attachment_created",
    "event_time": "2019-11-01T19:11:00.830Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "url": "https://oxana.instructure.com/api/v1/files/capture",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36"
  },
  "body": {
    "attachment_id": "21070000000000632",
    "content_type": "text/csv",
    "context_id": "21070000000002329",
    "context_type": "Course",
    "display_name": "enrollments (1).csv",
    "filename": "enrollments+%281%29.csv",
    "folder_id": "21070000000001359",
    "lock_at": "2018-10-09T20:44:45Z",
    "unlock_at": "2018-10-12T20:44:45Z",
    "updated_at": "2018-10-09T20:44:45Z",
    "user_id": "210700001234567"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **attachment_id** | The Canvas id of the attachment. |
| **content_type** | The attached files mime-type. |
| **context_id** | The id of the context the attachment is used in. |
| **context_type** | The type of context the attachment is used in. |
| **display_name** | The display name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **filename** | The file name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **folder_id** | The id of the folder where the attachment was saved. |
| **lock_at** | The lock date (attachment is locked after this date). |
| **unlock_at** | The unlock date (attachment is unlocked after this date). |
| **updated_at** | The time at which this attachment was last modified in any way. |
| **user_id** | The Canvas id of the user associated with the attachment. |



<h2 id="attachment_deleted">attachment_deleted</h2>

**Definition:** The event is emitted anytime a file is removed by an end user or API request.

**Trigger:** Triggered anytime a file is deleted from a course or user file directory.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "attachment_deleted",
    "event_time": "2019-11-01T04:00:46.918Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/files",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/files/606",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000123456",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "attachment_id": "21070000000000606",
    "content_type": "text/csv",
    "context_id": "21070000000000565",
    "context_type": "Course",
    "display_name": "enrollments.csv",
    "filename": "enrollments.csv",
    "folder_id": "21070000000001344",
    "lock_at": "2018-10-08T20:32:48Z",
    "unlock_at": "2018-10-12T20:32:48Z",
    "updated_at": "2018-10-11T20:32:48Z",
    "user_id": "21070000000123456"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **attachment_id** | The Canvas id of the attachment. |
| **content_type** | The attached files mime-type. |
| **context_id** | The id of the context the attachment is used in. |
| **context_type** | The type of context the attachment is used in. |
| **display_name** | The display name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **filename** | The file name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **folder_id** | The id of the folder where the attachment was saved. |
| **lock_at** | The lock date (attachment is locked after this date). |
| **unlock_at** | The unlock date (attachment is unlocked after this date). |
| **updated_at** | The time at which this attachment was last modified in any way. |
| **user_id** | The Canvas id of the user associated with the attachment. |



<h2 id="attachment_updated">attachment_updated</h2>

**Definition:** The event is emitted anytime a file is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered anytime a file is updated in a course or user file directory.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "attachment_updated",
    "event_time": "2019-11-01T19:11:18.234Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/files",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Chicago",
    "url": "https://oxana.instructure.com/api/v1/files/606",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000123456",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "attachment_id": "21070000000000606",
    "content_type": "text/csv",
    "context_id": "21070000000000565",
    "context_type": "Course",
    "display_name": "enrollments.csv",
    "filename": "enrollments.csv",
    "folder_id": "21070000000001344",
    "lock_at": "2018-10-08T20:32:48Z",
    "unlock_at": "2018-10-12T20:32:48Z",
    "updated_at": "2018-10-11T20:32:48Z",
    "user_id": "21070000000123456",
    "old_display_name": "lsa_flyer_v3-0-4.pdf"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **attachment_id** | The Canvas id of the attachment. |
| **content_type** | The attached files mime-type. |
| **context_id** | The id of the context the attachment is used in. |
| **context_type** | The type of context the attachment is used in. |
| **display_name** | The display name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **filename** | The file name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **folder_id** | The id of the folder where the attachment was saved. |
| **lock_at** | The lock date (attachment is locked after this date). |
| **unlock_at** | The unlock date (attachment is unlocked after this date). |
| **updated_at** | The time at which this attachment was last modified in any way. |
| **user_id** | The Canvas id of the user associated with the attachment. |
| **old_display_name** | The old display name of the attachment. NOTE: This field will be truncated to only include the first 8192 characters. |



