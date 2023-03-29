Assignment
==============

<h2 id="assignment_created">assignment_created</h2>

**Definition:** The event is emitted anytime a new assignment is created by an end user or API request.

**Trigger:** Triggered when a new assignment is created in a course.




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
    "developer_key_id": "170000000056",
    "event_name": "assignment_created",
    "event_time": "2019-11-01T19:11:11.323Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/api/v1/courses/565/assignments",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_group_id": "210700000000101907",
    "assignment_id": "21070000000000371",
    "context_id": "21070000000000565",
    "context_type": "Course",
    "context_uuid": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "created_on_blueprint_sync": false,
    "description": "<p>test assignment</p>",
    "due_at": "2018-10-01T05:59:59Z",
    "lock_at": "2018-10-01T05:59:59Z",
    "lti_assignment_id": "8b81d12c-fda4-4317-8d83-e987a6d2014a",
    "lti_resource_link_id": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d8h9",
    "lti_resource_link_id_duplicated_from": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d8h9",
    "assignment_id_duplicated_from": "21070000000000420",
    "domain_duplicated_from": "oxana.instructure.com",
    "domain": "oxana.instructure.com",
    "points_possible": 100,
    "submission_types": "online_url,online_upload",
    "title": "add_new_assignment_3",
    "unlock_at": "2018-09-24T06:00:00Z",
    "updated_at": "2018-10-03T14:50:31Z",
    "workflow_state": "created"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_group_id** | The Canvas id of the assignment group. |
| **assignment_id** | The Canvas id of the new assignment. |
| **context_id** | The type of context the assignment is used in. |
| **context_type** | The type of context the assignment is used in. |
| **context_uuid** | The uuid of the context associated with the assignment. |
| **created_on_blueprint_sync** | Whether or not the assignment was created in the context of a blueprint sync. |
| **description** | The description of the assignment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **due_at** | The due date for the assignment. |
| **lock_at** | The lock date (assignment is locked after this date). |
| **lti_assignment_id** | The LTI assignment guid for the assignment. |
| **lti_resource_link_id** | The unique identifier of the assignment resource in the LTI specification. Unique per Canvas shard. |
| **lti_resource_link_id_duplicated_from** | The LTI resource link ID of the original assignment. Present if new assigment is a copy. |
| **assignment_id_duplicated__from** | The Canvas id of the original assignment.  Present if new assigment is a copy. |
| **domain_duplicated_from** | The Canvas domain of the root account of the original assignment. Present if new assigment is a copy. |
| **domain** | The Canvas domain of the root account of the assignment. |
| **points_possible** | The maximum points possible for the assignment. |
| **submission_types** | Valid methods for submitting the assignment, may include multiple comma separated options of: discussion_topic, external_tool, media_recording, none, not_graded, online_quiz, online_text_entry, online_upload, online_url, on_paper. |
| **title** | The title of the assignment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **unlock_at** | The unlock date (assignment is unlocked after this date). |
| **updated_at** | The time at which this assignment was last modified in any way. |
| **workflow_state** | Workflow state of the assignment. E.g duplicating, fail_to_import, failed_to_duplicate, published, unpublished. See API documentation for more details.  |



<h2 id="assignment_group_created">assignment_group_created</h2>

**Definition:** The event is emitted anytime a new assignment group is created by an end user or API request.

**Trigger:** Triggered when a new assignment group is created in a course.




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
    "event_name": "assignment_group_created",
    "event_time": "2019-11-01T19:11:42.910Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Denver",
    "url": "https://oxana.instructure.com/api/v1/courses/565/assignment_groups",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_group_id": "642",
    "context_id": "565",
    "context_type": "Course",
    "group_weight": 0,
    "integration_data": null,
    "name": "test_assignment_group",
    "position": 10,
    "rules": "drop_lowest:1\\n",
    "sis_source_id": "SIS_ID_234",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_group_id** | The Canvas id of the new assignment group. |
| **context_id** | The Canvas context id of the new assignment group. |
| **context_type** | The context type of the new assignment group. |
| **group_weight** | The group weight of the new assignment group. |
| **integration_data** | Integration data for the new assignment group. |
| **name** | The name of the new assignment group. |
| **position** | The position of the new assignment group on the assignments page. |
| **rules** | Rules for the new assignment group. |
| **sis_source_id** | The SIS source id of the new assignment group. |
| **workflow_state** | Workflow state of the assignment group. |



<h2 id="assignment_group_updated">assignment_group_updated</h2>

**Definition:** The event is emitted anytime an assignment group is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a user or asynchronous job updates a new assignment group in a course context.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_role": "Training Teacher",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "event_name": "assignment_group_updated",
    "event_time": "2019-11-01T00:09:05.961Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/assignments",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Mexico_City",
    "url": "https://oxana.instructure.com/api/v1/courses/565/assignment_groups/642",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_group_id": "642",
    "context_id": "565",
    "context_type": "Course",
    "group_weight": 0,
    "integration_data": null,
    "name": "test_assignment_group1",
    "position": 10,
    "rules": "never_drop:123",
    "sis_source_id": "SIS_ID123",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_group_id** | The Canvas id of the updated assignment group. |
| **context_id** | The Canvas context id of the updated assignment group. |
| **context_type** | The context type of the updated assignment group. |
| **group_weight** | The group weight of the updated assignment group. |
| **integration_data** | Integration data for the updated assignment group. |
| **name** | The name of the updated assignment group. |
| **position** | The position of the updated assignment group. |
| **rules** | Rules for the updated assignment group. |
| **sis_source_id** | The SIS source id of the updated assignment group. |
| **workflow_state** | Workflow state of the assignment group. |



<h2 id="assignment_override_created">assignment_override_created</h2>

**Definition:** The event is emitted anytime an assignment override is created by an end user or API request.

**Trigger:** Triggered when an assignment override is created.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000001279362",
    "context_role": "TeacherEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "developer_key_id": "170000000056",
    "event_name": "assignment_override_created",
    "event_time": "2019-11-01T19:11:14.005Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/1279362/assignments/2030605",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_override_id": 1,
    "assignment_id": 1,
    "due_at": "2019-08-10T12:35:54Z",
    "all_day": true,
    "all_day_date": "2019-08-10T00:00:00Z",
    "unlock_at": "2019-08-01T00:00:00Z",
    "lock_at": "2019-08-21T00:00:00Z",
    "type": "CourseSection",
    "course_section_id": 1,
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_override_id** | The Canvas id of the assignment override. |
| **assignment_id** | The Canvas id of the assignment linked to the override. |
| **due_at** | The override due_at timestamp, or nil if not overridden. |
| **all_day** | The overridden all_day flag, or nil if not overridden. |
| **all_day_date** | The overridden all_day_date, or nil if not overridden. |
| **unlock_at** | The overridden unlock_at timestamp, or nil if not overridden. |
| **lock_at** | The overridden lock_at timestamp, or nil if not overridden. |
| **type** | Override type - `ADHOC` (list of Students), `CourseSection`, or `Group`. |
| **course_section_id** | (if `type='CourseSection'`) Canvas section id that this override applies to. |
| **group_id** | (if `type='Group'`) Canvas group id that this override applies to. |
| **workflow_state** | Workflow state of the override. (active, deleted) |



<h2 id="assignment_override_updated">assignment_override_updated</h2>

**Definition:** The event is emitted anytime an assignment override is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when an assignment override has been modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000001279362",
    "context_role": "TeacherEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "developer_key_id": "170000000056",
    "event_name": "assignment_override_updated",
    "event_time": "2019-11-01T19:11:14.005Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/1279362/assignments/2030605",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_override_id": 1,
    "assignment_id": 1,
    "due_at": "2019-08-10T12:35:54Z",
    "all_day": true,
    "all_day_date": "2019-08-10T00:00:00Z",
    "unlock_at": "2019-08-01T00:00:00Z",
    "lock_at": "2019-08-21T00:00:00Z",
    "type": "CourseSection",
    "course_section_id": 1,
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_override_id** | The Canvas id of the assignment override. |
| **assignment_id** | The Canvas id of the assignment linked to the override. |
| **due_at** | The override due_at timestamp, or nil if not overridden. |
| **all_day** | The overridden all_day flag, or nil if not overridden. |
| **all_day_date** | The overridden all_day_date, or nil if not overridden. |
| **unlock_at** | The overridden unlock_at timestamp, or nil if not overridden. |
| **lock_at** | The overridden lock_at timestamp, or nil if not overridden. |
| **type** | Override type - `ADHOC` (list of Students), `CourseSection`, or `Group`. |
| **course_section_id** | (if `type='CourseSection'`) Canvas section id that this override applies to. |
| **group_id** | (if `type='Group'`) Canvas group id that this override applies to. |
| **workflow_state** | Workflow state of the override. (active, deleted) |



<h2 id="assignment_updated">assignment_updated</h2>

**Definition:** The event is emitted anytime an assignment is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when an assignment has been modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000001279362",
    "context_role": "TeacherEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "developer_key_id": "170000000056",
    "event_name": "assignment_updated",
    "event_time": "2019-11-01T19:11:14.005Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/1279362/assignments/2030605",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_group_id": "21070000001234567",
    "assignment_id": "21070000002030605",
    "context_id": "21070000001279362",
    "context_type": "Course",
    "context_uuid": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "created_on_blueprint_sync": false,
    "description": "<h3>Assignment Description<h3/> This is your tasks, students:...",
    "due_at": "2019-11-05T13:38:00.218Z",
    "lock_at": "2019-11-05T13:38:00.218Z",
    "lti_assignment_id": "a1b2c3c4-z9x8-a1s2-q5w6-p9o8i7u6y5t6",
    "lti_resource_link_id": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "lti_resource_link_id_duplicated_from": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "assignment_id_duplicated__from": "21070000000000420",
    "domain_duplicated_from": "oxana.instructure.com",
    "domain": "oxana.instructure.com",
    "points_possible": 100,
    "submission_types": "discussion_topic, external_tool, media_recording, none, not_graded, on_paper, online_quiz, online_text_entry, online_upload, online_url, wiki_page",
    "title": "A New Assignment For Today",
    "unlock_at": "2019-11-05T13:38:00.218Z",
    "updated_at": "2019-11-05T13:38:00.218Z",
    "workflow_state": "published"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_group_id** | The Canvas id of the assignment group. |
| **assignment_id** | The Canvas id of the new assignment. |
| **context_id** | The Canvas id for the context the assignment is used in. |
| **context_type** | The type of context the assignment is used in (usually Course). |
| **context_uuid** | The uuid of the context associated with the assignment. |
| **created_on_blueprint_sync** | Whether or not the assignment was created in the context of a blueprint sync. |
| **description** | The description of the assignment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **due_at** | The due date for the assignment. |
| **lock_at** | The lock date (assignment is locked after this date). |
| **lti_assignment_id** | The LTI assignment guid for the assignment. |
| **lti_resource_link_id** | The unique identifier of the assignment resource in the LTI specification. Unique per Canvas shard. |
| **lti_resource_link_id_duplicated_from** | The LTI resource link ID of the original assignment. Present if new assigment is a copy. |
| **assignment_id_duplicated__from** | The Canvas id of the original assignment.  Present if new assigment is a copy. |
| **domain_duplicated_from** | The Canvas domain of the root account of the original assignment. Present if new assigment is a copy. |
| **domain** | The Canvas domain of the root account of the assignment. |
| **points_possible** | The maximum points possible for the assignment. |
| **submission_types** | Valid methods for submitting the assignment, may include multiple comma separated options. |
| **title** | The title of the assignment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **unlock_at** | The unlock date (assignment is unlocked after this date), or null if not applicable. |
| **updated_at** | The time at which this assignment was last modified in any way. |
| **workflow_state** | Workflow state of the assignment (deleted, duplicating, failed_to_import, failed_to_duplicate, failed_to_migrate, importing, published, unpublished). |



