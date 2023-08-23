Submission
==============

<h2 id="submission_comment_created">submission_comment_created</h2>

**Definition:** The event is emitted anytime an end user or API request comments on a submission.

**Trigger:** Triggered when a new comment is added to a submission.




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
    "event_name": "submission_comment_created",
    "event_time": "2019-11-01T19:11:13.216Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/gradebook/speed_grader?assignment_id=2974715&student_id=1740548",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/courses/410200/assignments/3964323/submissions/986036.text",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000012345",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "attachment_ids": [
      "54417187",
      "54417188"
    ],
    "body": "See the attached files",
    "created_at": "2019-11-01T19:11:13.216Z",
    "submission_comment_id": "19811981",
    "submission_id": "9987654",
    "user_id": "12345"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **attachment_ids** | Array of Canvas ids (as strings) of attachments for this comment. |
| **body** | The text of the comment. NOTE: This field will be truncated to only include the first 8192 characters. |
| **created_at** | The timestamp when the comment was created. |
| **submission_comment_id** | The Canvas id of the new comment. |
| **submission_id** | The Canvas id of the new submission. |
| **user_id** | The Canvas id of the user who authored the comment. |



<h2 id="submission_created">submission_created</h2>

**Definition:** The event is emitted anytime an end user or API request submits or re-submits an assignment. This applies to assignments and new quizzes, not classic quizzes. Use quiz_submitted for classic quiz submissions.

**Trigger:** Triggered when an assignment or new quizzes submission gets updated and has not yet been submitted.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "submission_created",
    "event_time": "2019-11-01T19:11:21.419Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "url": "https://oxana.instructure.com/api/lti/v1/tools/453919/grade_passback",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36"
  },
  "body": {
    "assignment_id": "21070000001234012",
    "attempt": 12,
    "body": "Test Submission Data",
    "grade": "Missing",
    "graded_at": "2019-11-01T19:11:21.419Z",
    "group_id": "120123",
    "late": false,
    "lti_assignment_id": "a1b2c3c4-z9x8-a1s2-q5w6-p9o8i7u6y5t6",
    "lti_user_id": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "missing": false,
    "score": 99.5,
    "submission_id": "21070000012345567",
    "submission_type": "online_text_entry",
    "submitted_at": "2019-11-01T19:11:21.419Z",
    "updated_at": "2019-11-01T19:11:21.419Z",
    "url": "https://test.submission.net",
    "user_id": "21070000000014012",
    "workflow_state": "submitted"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_id** | The Canvas id of the assignment being submitted. |
| **attempt** | This is the submission attempt number. |
| **body** | The content of the submission, if it was submitted directly in a text field. NOTE: This field will be truncated to only include the first 8192 characters. |
| **grade** | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example) |
| **graded_at** | The timestamp when the assignment was graded, if it was graded. |
| **group_id** | The submissions’s group ID if the assignment is a group assignment. |
| **late** | Whether the submission was made after the applicable due date. |
| **lti_assignment_id** | The LTI assignment guid of the submission's assignment |
| **lti_user_id** | The Lti id of the user associated with the submission. |
| **missing** | Whether the submission is missing, which generally means past-due and not yet submitted. |
| **score** | The raw score |
| **submission_id** | The Canvas id of the new submission. |
| **submission_type** | The types of submission (basic_lti_launch, discussion_topic, media_recording, online_quiz, online_text_entry, online_upload, online_url) |
| **submitted_at** | The timestamp when the assignment was submitted. |
| **workflow_state** | The state of the submission: normally 'submitted' or 'pending_review'. |
| **updated_at** | The time at which this assignment was last modified in any way |
| **url** | The URL of the submission (for 'online_url' submissions) |
| **user_id** | The Canvas id of the user associated with the submission. |



<h2 id="submission_updated">submission_updated</h2>

**Definition:** The event is emitted anytime an end user or API request modifies a submitted assignment or when a Teacher grades an assignment.

**Trigger:** Triggered when a submission gets updated.




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
    "event_name": "submission_updated",
    "event_time": "2019-11-01T19:11:11.325Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/1465707/gradebook/speed_grader?assignment_id=21868751&student_id=8026013",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Los_Angeles",
    "url": "https://oxana.instructure.com/courses/2176632/gradebook/update_submission",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_id": "21070000000000396",
    "attempt": 1,
    "body": "user: 47, quiz: 78, score: 0.0, time: 2018-10-09 21:29:57 +0000",
    "grade": "S",
    "graded_at": "2018-10-09T21:29:57Z",
    "group_id": "120120",
    "late": false,
    "lti_assignment_id": "f7d76a11-95be-485b-8827-dbe8fdca3332",
    "lti_user_id": null,
    "missing": false,
    "score": 99.5,
    "submission_id": "21070000000011176",
    "submission_type": "online_quiz",
    "submitted_at": "2018-10-09T21:29:57Z",
    "updated_at": "2018-10-09T21:29:57Z",
    "url": null,
    "user_id": "21070000000000047",
    "workflow_state": "submitted"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assignment_id** | The Canvas id of the assignment being submitted. |
| **attempt** | This is the submission attempt number. |
| **body** | The content of the submission, if it was submitted directly in a text field. NOTE: This field will be truncated to only include the first 8192 characters. |
| **grade** | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example) |
| **graded_at** | The timestamp when the assignment was graded, if it was graded. |
| **group_id** | The submissions’s group ID if the assignment is a group assignment. |
| **late** | Whether the submission was made after the applicable due date. |
| **lti_assignment_id** | The LTI assignment guid of the submission's assignment |
| **lti_user_id** | The Lti id of the user associated with the submission. |
| **missing** | Whether the submission is missing, which generally means past-due and not yet submitted. |
| **score** | The raw score |
| **submission_id** | The Canvas id of the new submission. |
| **submission_type** | The types of submission (online_text_entry, online_url, online_upload, media_recording) |
| **submitted_at** | The timestamp when the assignment was submitted. |
| **workflow_state** | The state of the submission, such as 'submitted' or 'graded'. |
| **updated_at** | The time at which this assignment was last modified in any way |
| **url** | The URL of the submission (for 'online_url' submissions) |
| **user_id** | The Canvas id of the user associated with the submission. |



