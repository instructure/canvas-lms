Grade
==============

<h2 id="course_grade_change">course_grade_change</h2>

**Definition:** The event gets emitted anytime any of the course scores are changed for a student.

**Trigger:** Triggered when anything (a user or asynchronous job) updates the final_score, course_score, unposted_current_score, or unposted_final_score columns in the scores table in the database.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "44fJ44GgJ29gJBsl43JLKgljsBIOTsbnKT48932g",
    "root_account_id": "10000000000001",
    "root_account_lti_guid": "794d72b707af6ea82cfe3d5d473f16888a8366c7.canvas.docker",
    "user_login": "oxana@instructure.com",
    "user_account_id": "10000000000002",
    "user_sis_id": null,
    "user_id": "21070000000000001",
    "time_zone": "America/Denver",
    "context_type": "Course",
    "context_id": "21070000000000002",
    "context_sis_source_id": "194387",
    "context_account_id": "21070000000000003",
    "context_role": "TeacherEnrollment",
    "request_id": "98e1b771-fe22-4481-8264-d523dadb16b1",
    "session_id": "242872453a9d69f7ccddeb4788d22506",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "http://oxana.instructure.com/courses/2/gradebook/update_submission",
    "referrer": "http://oxana.instructure.com/courses/2/gradebook/speed_grader?assignment_id=39&student_id=2",
    "producer": "canvas",
    "event_name": "course_grade_change",
    "event_time": "2019-12-11T16:26:34.552Z"
  },
  "body": {
    "user_id": "2",
    "course_id": "2",
    "workflow_state": "active",
    "created_at": "2019-12-04T13:32:21Z",
    "updated_at": "2019-12-11T16:26:34Z",
    "current_score": 17.31,
    "old_current_score": 13.46,
    "final_score": 12.5,
    "old_final_score": 9.72,
    "unposted_current_score": 17.31,
    "old_unposted_current_score": 13.46,
    "unposted_final_score": 12.5,
    "old_unposted_final_score": 9.72
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **user_id** | The Canvas user ID of the student. |
| **course_id** | The Canvas ID of the course. |
| **workflow_state** | The state of the score record in the database, could be "active" or "deleted". |
| **created_at** | The time when the row in the scores table (representing the course grade) was created. The score row is created as a result of some grade calculation, even if there are not yet any graded submissions for a student, i.e. when a student is enrolled in the class. |
| **updated_at** | The time when the row in the scores table was last updated -- that is, when the event is emitted. |
| **current_score** | The user's current score in the class. |
| **old_current_score** | The user's current score in the class before it was changed. This field will not be available until a student submits the first assignment in the  class. |
| **final_score** | The user's final score for the class. |
| **old_final_score** | The user's final score for the class before it was changed. This field will be set to 0.0 until a student submits the first assignment in the class. |
| **unposted_current_score** | The user's current grade in the class including unposted assignments. |
| **old_unposted_current_score** | The user's current grade in the class including unposted assignments, before it was changed. This field will not be available until a student submits the first assignment in the class. |
| **unposted_final_score** | The user's final grade for the class including unposted assignments. |
| **old_unposted_final_score** | The user's final grade for the class including unposted assignments, before it was changed. This field will not be available when a student submits the first assignment in the class. |



<h2 id="grade_change">grade_change</h2>

**Definition:** The event is emitted anytime when a submission is graded. These can happen as the result of a teacher changing a grade in the gradebook or speedgrader, a quiz being automatically scored, or changing an assignment's points possible or grade type. In the case of a quiz being scored, the `grade_change` event will be emitted as the result of a student turning in a quiz, and the `user_id` in the message attributes will be the student's user ID.

**Trigger:** Triggered anytime a grade is created or modified.




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
    "event_name": "grade_change",
    "event_time": "2019-11-01T19:11:05.222Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/gradebook",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Denver",
    "url": "https://oxana.instructure.com/api/v1/courses/565/assignments/355/submissions/48?include%5B%5D=visibility",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000987",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_id": "21070000000000355",
    "grade": "5",
    "grader_id": "21070000000000987",
    "grading_complete": true,
    "muted": false,
    "old_grade": "4",
    "old_points_possible": 1,
    "old_score": 4,
    "points_possible": 1,
    "score": 5,
    "student_id": "21070000000000048",
    "student_sis_id": "ABC.123",
    "submission_id": "21070000000011086",
    "user_id": "21070000000000048"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_id** | The Canvas id of the assignment associated with the submission. |
| **grade** | The new grade. |
| **grader_id** | The Canvas id of the user making the grade change. Null if this was the result of automatic grading. |
| **grading_complete** | The boolean state that the submission is completely graded.  False if the assignment is only partially graded, for example a quiz with automatically and manuall... |
| **muted** | The boolean muted state of the submissions's assignment.  Muted grade changes should not be published to students. |
| **old_grade** | The previous grade, if there was one. |
| **old_points_possible** | The maximum points possible for the previous grade. |
| **old_score** | The previous score. |
| **points_possible** | The maximum points possible for the submission's assignment. |
| **score** | The new score. |
| **student_id** | Same as the user_id. |
| **student_sis_id** | The SIS ID of the student. |
| **submission_id** | The Canvas id of the submission that the grade is changing on. |
| **user_id** | The Canvas id of the user associated with the submission with the change. |



<h2 id="grade_override">grade_override</h2>

**Definition:** The event is emitted anytime a student course grade is overriden. Typically grade override feature is used to edit student course grade

**Trigger:** Triggered when the final grade override has been changed. Only triggered when the override changes the existing score.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000001",
    "context_id": "21070000000000123",
    "context_role": "TeacherEnrollment",
    "context_sis_source_id": "194837",
    "context_type": "Course",
    "event_name": "grade_change",
    "event_time": "2019-11-15T07:46:18.697Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/123/gradebook/speed_grader?assignment_id=8188213&student_id=3541",
    "request_id": "392c325f-cba1-423f-ad2c-d213cabce732",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "V3kdo4kgu3F4Kf4fK109DSFkdso432950GKSOJNj:canvas-lms",
    "root_account_uuid": "V3kdo4kgu3F4Kf4fK109DSFkdso432950GKSOJNj",
    "session_id": "4e032912e321a243163232941f435324",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/courses/46/gradebook/update_submission",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000003541",
    "user_login": "oxana",
    "user_sis_id": "0119359"
  },
  "body": {
    "score_id": "43",
    "enrollment_id": "44",
    "user_id": "45",
    "course_id": "46",
    "grading_period_id": "47",
    "override_score": 90,
    "old_override_score": 85,
    "updated_at": "2019-11-15T07:46:18.697Z"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **score_id** | Canvas Id of Score record |
| **enrollment_id** | Canvas Id of Employment record |
| **user_id** | Canvas Id of User attached to this enrollment |
| **course_id** | Canvas Id of Course attached to this enrollment |
| **grading_period_id** | Canvas Id of Grading Period |
| **override_score** | New value of score after override |
| **old_override_score** | Previous value of score before override |
| **updated_at** | Date/Time the override occurred |



