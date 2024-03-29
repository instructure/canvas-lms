Rubric
==============

<h2 id="rubric_assessed">rubric_assessed</h2>

**Definition:** The event is emitted anytime a rubric is assessed that is aligned to an active rubric association.

**Trigger:** Triggered anytime a rubric is assessed that is aligned to an active rubric association.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "rubric_assessed",
    "event_time": "2023-10-25T19:09:09.137Z",
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
    "producer": "canvas"
  },
  "body": {
    "id": "20",
    "aligned_to_outcomes": true,
    "artifact_id": "77",
    "artifact_type": "Submission",
    "assessment_type": "grading",
    "context_uuid": "eXFLLA43CbEg5A8biA87cEPjcpByVw64ULmEsRM5",
    "submitted_at": "2023-10-25T18:09:09.137Z",
    "created_at": "2023-10-25T18:09:09.137Z",
    "updated_at": "2023-10-25T19:01:21.137Z",
    "attempt": 1
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **id** | The ID of the Rubric Assessment object. |
| **aligned_to_outcomes** | Boolean value that indicates if the rubric is aligned with learning outcomes. values will be true if the rubric is aligned to learning outcomes or false if the rubric is not aligned to learning outcomes. |
| **artifact_id** | The ID of the artifact object aligned to the Rubric Assessment object. |
| **artifact_type** | The type of the artifact object aligned to the Rubric Assessment object. Values will be either 'Submission', 'ModeratedGrading::ProvisionalGrade', or 'Assignment'. |
| **assessment_type** | The type of assessment. Values will be either 'grading', 'peer_review', or 'provisional_grade'. |
| **context_uuid** | The unique id of the Context object associated with the Rubric Association object. If this value is not present on the context, it will not be present in the live event body. |
| **submitted_at** | The date and time the student submitted the assignment that the rubric is aligned to or the date time the instructor assessed the rubric. |
| **created_at** | The date and time the initial rubric assessment was created. |
| **updated_at** | The date and time the rubric assessment was updated. |
| **attempt** | The integer representation of the number of attempts made by the student on the rubric aligned Artifact. The value will be nil if the Artifact aligned is not a Submission or if the assignment has yet to be submitted by the student. |



