Course
==============

<h2 id="course_completed">course_completed</h2>

**Definition:** The event is emitted when all of the module requirements in a course are met.

**Trigger:** Triggered when all the module requirements of a course have been met. Also gets triggered when a module has a set completion time or when the completion time gets updated.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_role": "StudentEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "developer_key_id": "170000000056",
    "event_name": "course_completed",
    "event_time": "2019-11-01T19:11:26.615Z",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/565/modules?include%5B%5D=items&per_page=99",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000123",
    "user_login": "inewton@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "course": {
      "account_id": "79",
      "id": "565",
      "name": "Computer Science I",
      "sis_source_id": "2017.100.101.101-1"
    },
    "progress": {
      "completed_at": "2019-11-05T13:38:00.218Z",
      "next_requirement_url": "http://oxana.instructure.com/courses/565/modules/items/12345",
      "requirement_completed_count": 6,
      "requirement_count": 6
    },
    "user": {
      "email": "inewton@example.com",
      "id": "123",
      "name": "Isaac Newton"
    }
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **course** | {"account_id"=>"The local Canvas id of the course's account.", "id"=>"The local Canvas id of the course.", "name"=>"The name of the course.", "sis_source_id"=>"The SIS identifier for the course, if defined."} |
| **progress** | {"completed_at"=>"Timestamp when the course module progress item was completed. ", "next_requirement_url"=>"Next module item on the module requirements list. Typically is null if student meets all requirements but also could have a value if there are more optional requirements left on the list.", "requirement_completed_count"=>"Count of those requirements that are done. E.g. 7 total, 5 completed.", "requirement_count"=>"Count of all the requirements in the course as a number"} |
| **user** | {"email"=>"The students email", "id"=>"The Canvas id of the student completing the course.", "name"=>"The name of the student."} |



<h2 id="course_created">course_created</h2>

**Definition:** The event is emitted anytime a new course is created by an end user or API request.

**Trigger:** Triggered when a new course is created (or copied).




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "developer_key_id": "170000000056",
    "event_name": "course_created",
    "event_time": "2019-11-05T13:38:00.218Z",
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
    "url": "https://oxana.instructure.com/api/v1/accounts/438/courses",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "account_id": "21070000000000438",
    "course_id": "21070000000000056",
    "created_at": "2019-11-05T13:38:00.218Z",
    "name": "Linear Algebra",
    "updated_at": "2019-11-05T13:38:00.218Z",
    "uuid": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_id** | The Account id of the updated course. |
| **course_id** | The Canvas id of the updated course. |
| **created_at** | The time at which this course was created. |
| **name** | The name the updated course. |
| **updated_at** | The time at which this course was last modified in any way. |
| **uuid** | The unique id of the course. |
| **workflow_state** | The state of the course (available, claimed, completed, created, deleted). |



<h2 id="course_progress">course_progress</h2>

**Definition:** The event is emitted when a course module requirement is met.

**Trigger:** Triggered when a user makes progress in a course by completing a module requirement, unless the completed requirement is the last remaining requirement in the course (in this case, a `course_completed` event is emitted). The following setup should be enabled in Canvas in order for this event to get triggered:
1. Module is set to be published
2. Module has at least one requirement enabled
3. Student completed at least one requirement in Module

Note that these events have a 2-minute debounce, meaning that a single `course_progress` event will be emitted per student per course 2 minutes after the student has finished completing requirements.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "course_progress",
    "event_time": "2019-11-01T19:11:13.590Z",
    "job_id": "1020020528469291",
    "job_tag": "ContextModuleProgression#evaluate!",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "course": {
      "account_id": "1",
      "id": "1234567",
      "name": "Diff Equations",
      "sis_source_id": "2017.102.102.102-2"
    },
    "progress": {
      "completed_at": null,
      "next_requirement_url": "http:/oxana.instructure.com/courses/1234567/modules/items/12345",
      "requirement_completed_count": 101,
      "requirement_count": 123
    },
    "user": {
      "email": "user@domain.tld",
      "id": "1122",
      "name": "Gottfried Leibniz"
    }
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **course** | {"account_id"=>"The local Canvas id of the course's account.", "id"=>"The local Canvas id of the course.", "name"=>"The name of the course.", "sis_source_id"=>"The SIS identifier for the course, if defined."} |
| **progress** | {"completed_at"=>"If the course has been completed, the timestamp (in ISO8601 format) when all requirements have been completed.", "next_requirement_url"=>"Link to the module item that is next in the order of requirements to complete.", "requirement_completed_count"=>"The count of those requirements that are done.", "requirement_count"=>"Count of all the requirements in the course as a number."} |
| **user** | {"email"=>"The student's email.", "id"=>"The Canvas id of the student completing the course.", "name"=>"The name of the student."} |



<h2 id="course_section_created">course_section_created</h2>

**Definition:** The event is emitted anytime a new course section is created by an end user or API request.

**Trigger:** Triggered when a new section is created in a course.




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
    "event_name": "course_section_created",
    "event_time": "2019-11-05T20:42:54.587Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000011",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/courses/2198496/sections?grant_type=authorization_code&access_token=111~sGvKF4Yzr2AqdwShKj7CwwopgwJuMFONBqWu44Upk1F4jgkFvpXc9HY20PCU5r0&course_section%5Bname%5D=Winter%185572%4Business%1Writing&course_section%5Bsis_section_id%5D=WRIT-684-L0_16169&course_section%5Bstart_at%5D=1326-0-2T0.15510549083388048%3A0.38873681067928767%3A0.039724554014499924&course_section%5Bend_at%5D=766-2-2T0.7605609524181581%3A0.995511619163594%3A0.013954836230862355&course_section%5Brestrict_enrollments_to_section_dates%5D=true&enable_sis_reactivation=false",
    "user_account_id": "21070000000000011",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "accepting_enrollments": true,
    "can_manually_enroll": null,
    "course_id": "565",
    "course_section_id": "1234567",
    "default_section": true,
    "end_at": "2020-06-17T04:00:00Z",
    "enrollment_term_id": "1234",
    "integration_id": "1234",
    "name": "Winter 2020 Linear Algebra",
    "nonxlist_course_id": "1234",
    "restrict_enrollments_to_section_dates": true,
    "root_account_id": "121",
    "sis_batch_id": "1234",
    "sis_source_id": "MATH-123-A12_12345",
    "start_at": "2020-01-03T05:00:00Z",
    "stuck_sis_fields": [
      "[\"course_id\"",
      " \"name\"]"
    ],
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **accepting_enrollments** | True if this section is open for enrollment. False or null otherwise. |
| **can_manually_enroll** | Deprecated, will always be null. |
| **course_id** | The Canvas id of the course that this section belongs to. |
| **course_section_id** | The local Canvas id of the created course section. |
| **default_section** | True if this is the default section for the course. False or null otherwise. |
| **end_at** | Section end date in ISO8601 format. |
| **enrollment_term_id** | The Canvas id of the enrollment term. |
| **integration_id** | The integration id of the section. |
| **name** | The name of this section. |
| **nonxlist_course_id** | The unique identifier of the original course of a cross-listed section. |
| **restrict_enrollments_to_section_dates** | True when 'Users can only participate in the course between these dates' is checked. |
| **root_account_id** | Canvas id of the root account that this section is in. |
| **sis_batch_id** | The SIS Batch id of the section. |
| **sis_source_id** | Correlated id for the record for this course in the SIS system (assuming SIS integration is configured). |
| **start_at** | Section start date in ISO8601 format. |
| **stuck_sis_fields** | Array of strings of field names with the SIS stickiness field set, indicating they will not be replaced by SIS imports. |
| **workflow_state** | The workflow state of the section. |



<h2 id="course_section_updated">course_section_updated</h2>

**Definition:** The event is emitted anytime a course section is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a course section has been modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000001234567",
    "context_sis_source_id": "MATH-123-A12_12345",
    "context_type": "CourseSection",
    "developer_key_id": "170000000056",
    "event_name": "course_section_updated",
    "event_time": "2019-11-01T19:11:15.599Z",
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
    "url": "https://oxana.instructure.com/api/v1/sections/sis_section_id:MATH-123-A12_12345/crosslist/sis_course_id:AAOE190823",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "accepting_enrollments": true,
    "can_manually_enroll": null,
    "course_id": "1234560",
    "course_section_id": "1234567",
    "default_section": true,
    "end_at": "2020-06-17T04:00:00Z",
    "enrollment_term_id": "1234",
    "integration_id": "1234",
    "name": "Winter 2020 Linear Algebra",
    "nonxlist_course_id": "1234",
    "restrict_enrollments_to_section_dates": true,
    "root_account_id": "1",
    "sis_batch_id": "1234",
    "sis_source_id": "MATH-123-A12_12345",
    "start_at": "2020-01-03T05:00:00Z",
    "stuck_sis_fields": [
      "course_id",
      "name"
    ],
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **accepting_enrollments** | True if this section is open for enrollment. False or null otherwise. |
| **can_manually_enroll** | Deprecated, will always be null. |
| **course_id** | The Canvas id of the course that this section belongs to. |
| **course_section_id** | The local Canvas id of the created course section. |
| **default_section** | True if this is the default section for the course. |
| **end_at** | Section end date in ISO8601 format. |
| **enrollment_term_id** | The Canvas id of the enrollment term. |
| **integration_id** | The integration id of the section. |
| **name** | The name of this section. |
| **nonxlist_course_id** | The unique identifier of the original course of a cross-listed section. |
| **restrict_enrollments_to_section_dates** | True when 'Users can only participate in the course between these dates' is checked. |
| **root_account_id** | Canvas id of the root account that this section is in. |
| **sis_batch_id** | The SIS Batch id of the section. |
| **sis_source_id** | Correlated id for the record for this course in the SIS system (assuming SIS integration is configured). |
| **start_at** | Section start date in ISO8601 format. |
| **stuck_sis_fields** | Array of strings of field names with the SIS stickiness field set, indicating they will not be replaced by SIS imports. |
| **workflow_state** | The workflow state of the section. |



<h2 id="course_updated">course_updated</h2>

**Definition:** The event is emitted anytime a course is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when the course is renamed, deleted, or other properties (except for syllabus) of a course are modified.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "course_updated",
    "event_time": "2019-11-05 07:38:00 -0800",
    "job_id": "1020020528469291",
    "job_tag": "SIS::CSV::ImportRefactored#run_parallel_importer",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "account_id": "12340000000012",
    "course_id": "12340000000056",
    "created_at": "2019-11-05T13:38:00.218Z",
    "name": "Linear Algebra",
    "updated_at": "2019-11-05 07:38:00 -0800",
    "uuid": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_id** | The Account id of the updated course. |
| **course_id** | The Canvas id of the updated course. |
| **created_at** | The time at which this course was created. |
| **name** | The name the updated course. |
| **updated_at** | The time at which this course was last modified in any way. |
| **uuid** | The unique id of the course. |
| **workflow_state** | The state of the course (available, claimed, completed, created, deleted). |



