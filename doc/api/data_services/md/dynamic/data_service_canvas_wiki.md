Wiki
==============

<h2 id="wiki_page_created">wiki_page_created</h2>

**Definition:** The event is emitted anytime a new wiki page is created by an end user or API request.

**Trigger:** Triggered when a new wiki page is created.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "wiki_page_created",
    "event_time": "2019-11-01T19:11:05.861Z",
    "job_id": "1020020528469291",
    "job_tag": "Canvas::Migration::Worker::CCWorker#perform",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "body": "<p>page 1</p>",
    "title": "Page 1 Created",
    "wiki_page_id": "21070000000000009"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **body** | The body of the new page. NOTE: This field will be truncated to only include the first 8192 characters. |
| **title** | The title of the new page. NOTE: This field will be truncated to only include the first 8192 characters. |
| **wiki_page_id** | The Canvas id of the new wiki page. |



<h2 id="wiki_page_deleted">wiki_page_deleted</h2>

**Definition:** The event is emitted anytime a wiki page is deleted by an end user or API request.

**Trigger:** Triggered when a wiki page is deleted.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_role": "TeacherEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "event_name": "wiki_page_deleted",
    "event_time": "2019-11-01T19:11:13.729Z",
    "hostname": "oxana.instructure.com",
    "http_method": "DELETE",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/1013182/pages/ccs-online-logo-instructions?module_item_id=9653761",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/api/v1/courses/1499839/pages/ccs-online-logo-instructions",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "title": "Page 1 Updated",
    "wiki_page_id": "21070000000000009"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **title** | The title of the deleted wiki page. NOTE: This field will be truncated to only include the first 8192 characters. |
| **wiki_page_id** | The Canvas id of the deleted wiki page. |



<h2 id="wiki_page_updated">wiki_page_updated</h2>

**Definition:** The event is emitted anytime a wiki page is altered by an end user or API request.

**Trigger:** Triggered when title or body of wiki page is altered.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "wiki_page_updated",
    "event_time": "2019-11-01T19:11:25.788Z",
    "job_id": "1020020528469291",
    "job_tag": "ContentMigration#import_content",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "body": "<p>page 1 - updated</p>",
    "old_body": "<p>page 1</p>",
    "old_title": "Page 1 Created",
    "title": "Page 1 Updated",
    "wiki_page_id": "21070000000000009"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **body** | The new page body. NOTE: This field will be truncated to only include the first 8192 characters. |
| **old_body** | The old page body. NOTE: This field will be truncated to only include the first 8192 characters. |
| **old_title** | The old title. NOTE: This field will be truncated to only include the first 8192 characters. |
| **title** | The new title. NOTE: This field will be truncated to only include the first 8192 characters. |
| **wiki_page_id** | The Canvas id of the changed wiki page. |



