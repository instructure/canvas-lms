Enrollment
==============

<h2 id="enrollment_created">enrollment_created</h2>

**Definition:** The event is emitted anytime a new enrollment is added to a course by an end user or API request.

**Trigger:** Triggered when a new course enrollment is created.




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
    "event_name": "enrollment_created",
    "event_time": "2018-10-09T21:07:33Z",
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
    "url": "https://oxana.instructure.com/api/v1/sections/4811/enrollments?enrollment[user_id]=20064&amp;enrollment[type]=StudentEnrollment&amp;enrollment[enrollment_state]=invited&amp;enrollment[limit_privileges_to_course_section]=true&amp;enrollment[notify]=true",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "associated_user_id": "21070000000000562",
    "course_id": "21070000000000565",
    "course_section_id": "21070000000004811",
    "created_at": "2018-10-09T21:07:33Z",
    "enrollment_id": "21070000000046825",
    "limit_privileges_to_course_section": false,
    "type": "StudentEnrollment",
    "updated_at": "2018-10-09T21:07:33Z",
    "user_id": "21070000000020064",
    "user_name": "Isaac Newton",
    "workflow_state": "invited"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **associated_user_id** | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
| **course_id** | The Canvas id of the course for this enrollment. |
| **course_section_id** | The id of the section of the course for the new enrollment. |
| **created_at** | The time at which this enrollment was created. |
| **enrollment_id** | The Canvas id of the new enrollment. |
| **limit_privileges_to_course_section** | Whether students can only talk to students within their course section. |
| **type** | The type of enrollment; e.g. StudentEnrollment, TeacherEnrollment, ObserverEnrollment, etc. |
| **updated_at** | The time at which this enrollment was last modified in any way. |
| **user_id** | The Canvas id of the user for this enrollment. |
| **user_name** | The user's name. |
| **workflow_state** | The state of the enrollment (active, completed, creation_pending, deleted, inactive, invited) |



<h2 id="enrollment_state_created">enrollment_state_created</h2>

**Definition:** The event is emitted anytime a new enrollment record is added to a course.

**Trigger:** Triggered when a new course enrollment is created with a new workflow_state.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "event_name": "enrollment_state_created",
    "event_time": "2019-11-01T19:11:09.910Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/accounts/1?enrollment_term_id=83&search_term=hsw",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Chicago",
    "url": "https://oxana.instructure.com/courses/565/enroll_users",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "access_is_current": true,
    "enrollment_id": "21070000000000143",
    "restricted_access": false,
    "state": "pending_invited",
    "state_is_current": true,
    "state_started_at": "2019-10-05 05:38:00 -0800",
    "state_valid_until": "2019-11-05T13:38:00.218Z"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **access_is_current** | If this enrollment_state access is upto date. |
| **enrollment_id** | The Canvas id of the new enrollment. |
| **restricted_access** | True if this enrollment_state is restricted. |
| **state** | The state of the enrollment. |
| **state_is_current** | If this enrollment_state is uptodate |
| **state_started_at** | The time when this enrollment state starts. |
| **state_valid_until** | The time at which this enrollment is no longer valid. |



<h2 id="enrollment_state_updated">enrollment_state_updated</h2>

**Definition:** The event is emitted anytime an enrollment record workflow state changes.

**Trigger:** Triggered when a course enrollment workflow_state changes.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "enrollment_state_updated",
    "event_time": "2019-11-01T19:11:00.802Z",
    "job_id": "1020020528469291",
    "job_tag": "EnrollmentState.process_account_states_in_ranges",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "access_is_current": true,
    "enrollment_id": "21070000000001533",
    "restricted_access": false,
    "state": "pending_invited",
    "state_is_current": true,
    "state_started_at": "2018-11-05 05:38:00 -0800",
    "state_valid_until": "2019-11-05T13:38:00.218Z"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **access_is_current** | If this enrollment_state access is upto date. |
| **enrollment_id** | The Canvas id of the new enrollment. |
| **restricted_access** | True if this enrollment_state is restricted. |
| **state** | The state of the enrollment. |
| **state_is_current** | If this enrollment_state is uptodate |
| **state_started_at** | The time when this enrollment state starts. |
| **state_valid_until** | The time at which this enrollment is no longer valid. |



<h2 id="enrollment_updated">enrollment_updated</h2>

**Definition:** The event is emitted anytime an enrollment record is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a course enrollment is modified.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "enrollment_updated",
    "event_time": "2019-11-01T19:11:12.546Z",
    "job_id": "1020020528469291",
    "job_tag": "SIS::CSV::ImportRefactored#run_parallel_importer",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "associated_user_id": "21070000000000562",
    "course_id": "21070000000000565",
    "course_section_id": "21070000000000598",
    "created_at": "2018-10-09T21:07:33Z",
    "enrollment_id": "21070000000046825",
    "limit_privileges_to_course_section": false,
    "type": "StudentEnrollment",
    "updated_at": "2018-10-09T21:07:33Z",
    "user_id": "21070000000020064",
    "user_name": "Isaac Netwon",
    "workflow_state": "invited"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **associated_user_id** | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
| **course_id** | The Canvas id of the course for this enrollment. |
| **course_section_id** | The id of the section of the course for the new enrollment. |
| **created_at** | The time at which this enrollment was created. |
| **enrollment_id** | The Canvas id of the new enrollment. |
| **limit_privileges_to_course_section** | Whether students can only talk to students within their course section. |
| **type** | The type of enrollment; e.g. StudentEnrollment, TeacherEnrollment, ObserverEnrollment, etc. |
| **updated_at** | The time at which this enrollment was last modified in any way. |
| **user_id** | The Canvas id of the user for this enrollment. |
| **user_name** | The user's name. |
| **workflow_state** | The state of the enrollment (active, completed, creation_pending, deleted, inactive, invited) |



