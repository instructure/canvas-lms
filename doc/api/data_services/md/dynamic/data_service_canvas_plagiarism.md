Plagiarism
==============

<h2 id="plagiarism_resubmit">plagiarism_resubmit</h2>

**Definition:** The event is emitted anytime a submission is created for an assignment with plagiarism settings turned on.

**Trigger:** Triggered when a submission is resubmitted.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_role": "TaEnrollment",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Course",
    "event_name": "plagiarism_resubmit",
    "event_time": "2019-11-05T21:52:21.127Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/27745/gradebook/speed_grader?assignment_id=154394&student_id=90175",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/courses/565/assignments/1234567/submissions/98765/turnitin/resubmit",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "assignment_id": "21070000001234567",
    "attempt": 1,
    "body": "This is my submission to the assignment",
    "grade": "F",
    "graded_at": "2019-11-05T21:52:21.127Z",
    "group_id": "21070000000000099",
    "lti_assignment_id": "a1b2c3c4-z9x8-a1s2-q5w6-p9o8i7u6y5t6",
    "lti_user_id": "a1b2c3c4z9x8a1s2q5w6p9o8i7u6y5t6a2s3d4f5",
    "score": 99.5,
    "submission_id": "21070000000112233",
    "submission_type": "online_text_entry",
    "submitted_at": "2019-11-04T21:52:21.127Z",
    "updated_at": "2019-11-05T21:52:21.127Z",
    "url": null,
    "user_id": "21070000000098765",
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
| **graded_at** | The timestamp when the assignment was graded. |
| **group_id** | The submissions’s group ID if the assignment is a group assignment. |
| **lti_assignment_id** | The LTI assignment guid of the submission's assignment |
| **lti_user_id** | The LTI id of the user associated with the submission. |
| **score** | The raw score. |
| **submission_id** | The Canvas id of the new submission. |
| **submission_type** | The type of submission (online_text_entry, online_url, online_upload, media_recording) |
| **submitted_at** | The timestamp when the assignment was submitted. |
| **updated_at** | The time at which this assignment was last modified in any way. |
| **url** | The URL of the submission (for 'online_url' submissions). |
| **user_id** | The Canvas id of the user associated with the submission. |
| **workflow_state** | The state of the submission, such as 'submitted' |



