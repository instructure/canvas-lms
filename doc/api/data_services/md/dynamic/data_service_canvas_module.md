Module
==============

<h2 id="module_created">module_created</h2>

**Definition:** The event is emitted anytime a new module is created by an end user or API request.

**Trigger:** Triggered when a new module is created.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "module_created",
    "event_time": "2019-11-01T19:11:05.880Z",
    "job_id": "1020020528469291",
    "job_tag": "Canvas::Migration::Worker::CCWorker#perform",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "context_id": "1234560",
    "context_type": "Course",
    "module_id": "1234567",
    "name": "Module 3",
    "position": 101,
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The local Canvas id of the context. |
| **context_type** | The type of module's context. |
| **module_id** | The Canvas id of the module. |
| **name** | The name of the module. |
| **position** | The position of the module in the course. |
| **workflow_state** | The workflow state of the module. |



<h2 id="module_item_created">module_item_created</h2>

**Definition:** The event is emitted anytime a new module item is added to a module by an end user or API request.

**Trigger:** Triggered when a new module item is created.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "developer_key_id": "170000000056",
    "event_name": "module_item_created",
    "event_time": "2019-11-01T19:11:07.287Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/sis_course_id:syllabus-registry-F9-HSS/modules/61660/items",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "module_id": "14",
    "module_item_id": "19587",
    "position": 1,
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The local Canvas id of the context. |
| **context_type** | The type of module's context, usually "Course". |
| **module_id** | The Canvas id of the module. |
| **module_item_id** | The Canvas id of the module item. |
| **position** | The position of the module item in the module. |
| **workflow_state** | The workflow state of the module item. |



<h2 id="module_item_updated">module_item_updated</h2>

**Definition:** The event is emitted anytime a module item is updated in a module by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a new module item is updated.




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
    "event_name": "module_item_updated",
    "event_time": "2019-11-01T19:11:01.676Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/modules",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Chicago",
    "url": "https://oxana.instructure.com/api/v1/courses/565/modules/14/items/19587",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "module_id": "14",
    "module_item_id": "19587",
    "position": 1,
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The local Canvas id of the context. |
| **context_type** | The type of module's context. |
| **module_id** | The Canvas id of the module. |
| **module_item_id** | The Canvas id of the module item. |
| **position** | The position of the module item in the module. |
| **workflow_state** | The workflow state of the module item (active, deleted, unpublished). |



<h2 id="module_updated">module_updated</h2>

**Definition:** The event is emitted anytime a module is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a new module is updated.




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
    "event_name": "module_updated",
    "event_time": "2019-11-01T19:11:03.000Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/modules",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/courses/565/modules/reorder",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "module_id": "14",
    "name": "Module 4",
    "position": 3,
    "workflow_state": "unpublished"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The local Canvas id of the context. |
| **context_type** | The type of module's context. |
| **module_id** | The Canvas id of the module. |
| **name** | The name of the module. |
| **position** | The position of the module in the course. |
| **workflow_state** | The workflow state of the module (active, deleted, unpublished). |



