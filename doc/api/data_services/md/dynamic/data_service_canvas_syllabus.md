Syllabus
==============

<h2 id="syllabus_updated">syllabus_updated</h2>

**Definition:** The event is emitted anytime a syllabus is changed in a course by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a course syllabus gets updated.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "syllabus_updated",
    "event_time": "2019-11-01T19:11:14.519Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/assignments/syllabus",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/courses/565",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "course_id": "21070000000000565",
    "old_syllabus_body": "<p><iframe style=\"width: 800px; height: 880px;\" src=\"/courses/565/external_tools/retrieve?display=borderless&amp;url=https%3A%2F%2Foxana.instructuremedia.com%2F...",
    "syllabus_body": "<p><iframe style=\"width: 800px; height: 880px;\" src=\"/courses/565/external_tools/retrieve?display=borderless&amp;url=https%3A%2F%2Foxana.instructuremedia.com%2F..."
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **course_id** | The Canvas id of the updated course. |
| **old_syllabus_body** | The old syllabus content. NOTE: This field will be truncated to only include the first 8192 characters. NOTE: This field will be truncated to only include the first 8192 characters. |
| **syllabus_body** | The new syllabus content. NOTE: This field will be truncated to only include the first 8192 characters. |



