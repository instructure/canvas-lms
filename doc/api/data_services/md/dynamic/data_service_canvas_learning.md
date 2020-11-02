Learning
==============

<h2 id="learning_outcome_created">learning_outcome_created</h2>

**Definition:** The event is emitted anytime a outcome is created in the account by an end user or API request.

**Trigger:** Triggered when a new learning outcome is created.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "learning_outcome_created",
    "event_time": "2019-11-05T10:03:37.526Z",
    "job_id": "1020020528469291",
    "job_tag": "Canvas::Migration::Worker::CourseCopyWorker#perform",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "calculation_int": 65,
    "calculation_method": "highest",
    "context_id": "1234",
    "context_type": "Course",
    "description": "Develop understanding of molecular and cell biology.",
    "display_name": "Learn molecular biology",
    "learning_outcome_id": "12345",
    "short_description": "Molecular biology knowledge",
    "title": "Molecular biology knowledge",
    "vendor_guid": "1",
    "workflow_state": "active",
    "rubric_criterion": {
      "description": "Molecular biology knowledge",
      "mastery_points": 2,
      "points_possible": 3,
      "ratings": [
        {
          "description": "The student shows fluency.",
          "points": 3
        },
        {
          "description": "The student shows proficiency.",
          "points": 2
        },
        {
          "description": "The student understands the fundamentals.",
          "points": 1
        },
        {
          "description": "The student does not meet the requirements.",
          "points": 0
        }
      ]
    }
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **calculation_int** | Defines the variable value used by the calculation_method. Included only if calculation_method uses it. |
| **calculation_method** | The method used to calculate student score. |
| **context_id** | The ID of the context the learning_outcome is used in. |
| **context_type** | The type of context the learning_outcome is used in. |
| **description** | Description of the outcome. |
| **display_name** | Optional friendly name for reporting. |
| **learning_outcome_id** | The local Canvas ID of the learning outcome. |
| **short_description** | Also the title of the outcome. |
| **title** | The title of the learning outcome or learning outcome group. |
| **vendor_guid** | A custom GUID for the learning standard. |
| **workflow_state** | Workflow status of the learning outcome (e.g. active, deleted). |
| **rubric_criterion** | {"description"=>"Also the title of the outcome.", "mastery_points"=>"The number of points necessary for a rating to be considered mastery.", "points_possible"=>"The maximum level of points of any rating.", "ratings"=>"Array of objects with (points, description) describing each of the outcoming ratings."} |



<h2 id="learning_outcome_group_created">learning_outcome_group_created</h2>

**Definition:** The event is emitted anytime a new outcome group is created in the account by an end user or API request.

**Trigger:** Triggered when a new group of learning outcomes is created.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "learning_outcome_group_created",
    "event_time": "2019-11-01T18:42:34.373Z",
    "job_id": "1020020528469291",
    "job_tag": "OutcomeImport#run",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "context_id": "32054",
    "context_type": "Course",
    "description": "<h3>Outcome</h3>Hello outcome",
    "learning_outcome_group_id": "75033",
    "parent_outcome_group_id": "75032",
    "title": "Official Standards for K-12 Math Education",
    "vendor_guid": "123",
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The ID of the context the learning outcome is used in. |
| **context_type** | The type of context the learning outcome is used in, usually Course. |
| **description** | Description of the learnning outcome group. |
| **learning_outcome_group_id** | The local Canvas ID of the learning outcome group. |
| **parent_outcome_group_id** | The local Canvas ID of the group's parent outcome group. |
| **title** | Title of the learning outcome group. |
| **vendor_guid** | A custom GUID for the learning standard. |
| **workflow_state** | Workflow status of the learning outcome group, defaults to active. |



<h2 id="learning_outcome_group_updated">learning_outcome_group_updated</h2>

**Definition:** The event is emitted anytime an existing outcome group  is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a group of learning outcomes is modified.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "learning_outcome_group_updated",
    "event_time": "2019-11-01T13:49:07.504Z",
    "job_id": "1020020528469291",
    "job_tag": "OutcomeImport#run",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "context_id": "32054",
    "context_type": "Course",
    "description": "<h3>Outcome</h3>Hello outcome",
    "learning_outcome_group_id": "75033",
    "parent_outcome_group_id": "75032",
    "title": "Official Standards for K-12 Math Education",
    "updated_at": "2019-11-05T13:38:00.218Z",
    "vendor_guid": "123",
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The ID of the context the learning outcome is used in. |
| **context_type** | The type of context the learning outcome is used in, usually Course. |
| **description** | Description of the learnning outcome group. |
| **learning_outcome_group_id** | The local Canvas ID of the learning outcome group. |
| **parent_outcome_group_id** | The local Canvas ID of the group's parent outcome group. |
| **title** | Title of the learning outcome group. |
| **updated_at** | The time at which this group was last modified in any way. |
| **vendor_guid** | A custom GUID for the learning standard. |
| **workflow_state** | Workflow status of the learning outcome group, defaults to active. |



<h2 id="learning_outcome_link_created">learning_outcome_link_created</h2>

**Definition:** The event is emitted anytime an outcome is linked to a context by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when an outcome is linked inside of a context.




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
    "event_name": "learning_outcome_link_created",
    "event_time": "2019-11-01T19:12:01.333Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/outcomes",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Sao_Paulo",
    "url": "https://oxana.instructure.com/api/v1/courses/565/outcome_groups/123456/outcomes",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "learning_outcome_group_id": "123456",
    "learning_outcome_id": "1201234",
    "learning_outcome_link_id": "12345678",
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The Canvas ID of the context the learning outcome is used in. |
| **context_type** | The type of context the learning outcome is used in, usually Course. |
| **learning_outcome_group_id** | The local Canvas id of the related learning outcome group. |
| **learning_outcome_id** | The local Canvas id of the related learning outcome. |
| **learning_outcome_link_id** | The local Canvas id of the new learning outcome link. |
| **workflow_state** | The workflow status of the learning outcome link, by default active. |



<h2 id="learning_outcome_link_updated">learning_outcome_link_updated</h2>

**Definition:** The event is emitted anytime an outcome context link is changed by an end user or API request.

**Trigger:** Triggered when an outcome link is changed inside of a context.




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
    "event_name": "learning_outcome_link_updated",
    "event_time": "2019-11-01T19:12:12.060Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/outcomes",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Sao_Paulo",
    "url": "https://oxana.instructure.com/api/v1/courses/565/outcome_groups/1001/outcomes",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "learning_outcome_group_id": "1001",
    "learning_outcome_id": "1234",
    "learning_outcome_link_id": "12345",
    "updated_at": "2019-11-01T19:12:12.060Z",
    "workflow_state": "active"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The Canvas ID of the context the learning outcome is used in. |
| **context_type** | The type of context the learning outcome is used in, usually Course. |
| **learning_outcome_group_id** | The local Canvas id of the related learning outcome group. |
| **learning_outcome_id** | The local Canvas id of the related learning outcome. |
| **learning_outcome_link_id** | The local Canvas id of the learning outcome link that was updated. |
| **updated_at** | The time that the learning outcome link was last modified. |
| **workflow_state** | The workflow status of the learning outcome link (e.g. active, deleted) |



<h2 id="learning_outcome_result_created">learning_outcome_result_created</h2>

**Definition:** The event is emitted anytime a submission is assessed against an outcome. The following setup should be enabled in Canvas in order for the event to be triggered:
1. Administrator has set up learning outcomes at the account/sub-account level
2. Instructor has added outcome to assignment rubric
3. Student submitted a rubric based assignment
4. Instructor graded a rubric based assignment at the outcome level => there is a result associated with assignment outcome

**Trigger:** Triggered when a submission is rated against an outcome.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "learning_outcome_result_created",
    "event_time": "2019-08-09T21:35:05Z",
    "job_id": "1020020528469291",
    "job_tag": "Quizzes::SubmissionGrader#update_outcomes",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "assessed_at": "2019-08-09T21:35:05Z",
    "attempt": 1,
    "created_at": "2019-08-09T21:35:05Z",
    "learning_outcome_id": "1",
    "mastery": true,
    "original_mastery": false,
    "original_possible": 5,
    "original_score": 5,
    "percent": 1,
    "possible": 5,
    "score": 5,
    "title": "oxana Student 2, Test Outcome"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assessed_at** | The date when the outcome was last assessed. |
| **attempt** | The submission attempt number. |
| **created_at** | Time when the result was created. |
| **learning_outcome_id** | The local Canvas ID of the learning outcome. |
| **mastery** | True if student achieved mastery. |
| **original_mastery** | True if student achieved mastery on the first attempt. |
| **original_possible** | Possible points on the first attempt. |
| **original_score** | Score on the first attempt. |
| **percent** | Percent of maximum points possible for an outcome, scaled to reflect any custom mastery levels that differ from the learning outcome. |
| **possible** | Total number of points possible. |
| **score** | The student's score. |
| **title** | Title of the learning outcome. |



<h2 id="learning_outcome_result_updated">learning_outcome_result_updated</h2>

**Definition:** The event is emitted anytime a existing outcome rating for a submission is updated. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a submission outcome rating is updated.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "learning_outcome_result_updated",
    "event_time": "2019-08-09T21:35:05Z",
    "job_id": "1020020528469291",
    "job_tag": "RubricAssessment#update_outcomes_for_assessment",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "assessed_at": "2019-08-09T21:35:05Z",
    "attempt": 1,
    "created_at": "2019-08-09T21:35:05Z",
    "learning_outcome_id": "1",
    "mastery": true,
    "original_mastery": false,
    "original_possible": 5,
    "original_score": 5,
    "percent": 1,
    "possible": 5,
    "score": 5,
    "title": "oxana Student 2, Test Outcome",
    "updated_at": "2019-11-01T00:21:24Z"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **assessed_at** | The date when the outcome was last assessed. |
| **attempt** | The submission attempt number. |
| **created_at** | Time when the result was created. |
| **learning_outcome_id** | The local Canvas ID of the learning outcome. |
| **mastery** | True if student achieved mastery. |
| **original_mastery** | True if student achieved mastery on the first attempt. |
| **original_possible** | Possible points on the first attempt. |
| **original_score** | Score on the first attempt. |
| **percent** | Percent of maximum points possible for an outcome, scaled to reflect any custom mastery levels that differ from the learning outcome. |
| **possible** | Total number of points possible. |
| **score** | The student's score. |
| **title** | Title of the learning outcome. |
| **updated_at** | Time the learning outcome result was updated at. |



<h2 id="learning_outcome_updated">learning_outcome_updated</h2>

**Definition:** The event is emitted anytime an outcome is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when an outcome is updated.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "learning_outcome_updated",
    "event_time": "2019-11-01T21:42:55.950Z",
    "hostname": "oxana.instructure.com",
    "http_method": "PUT",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/1234/outcomes",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Denver",
    "url": "https://oxana.instructure.com/api/v1/outcomes/12345",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "calculation_int": 65,
    "calculation_method": "highest",
    "context_id": "1234",
    "context_type": "Course",
    "description": "Develop understanding of molecular and cell biology.",
    "display_name": "Learn molecular biology",
    "learning_outcome_id": "12345",
    "short_description": "Molecular biology knowledge",
    "title": "Molecular biology knowledge",
    "updated_at": "2019-11-01T21:42:55Z",
    "vendor_guid": "1",
    "workflow_state": "active",
    "rubric_criterion": {
      "description": "Molecular biology knowledge",
      "mastery_points": 3,
      "points_possible": 5,
      "ratings": [
        {
          "description": "Exceeds Expectations",
          "points": 5
        },
        {
          "description": "Proficient",
          "points": 4
        },
        {
          "description": "Meets Expectations",
          "points": 3
        },
        {
          "description": "Nearing Expectations",
          "points": 2
        },
        {
          "description": "Developing",
          "points": 1
        },
        {
          "description": "Does Not Meet Expectations",
          "points": 0
        }
      ]
    }
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **calculation_int** | Defines the variable value used by the calculation_method. Included only if calculation_method uses it. |
| **calculation_method** | The method used to calculate student score. |
| **context_id** | The ID of the context the learning_outcome is used in. |
| **context_type** | The type of context the learning_outcome is used in. |
| **description** | Description of the outcome. |
| **display_name** | Optional friendly name for reporting. |
| **learning_outcome_id** | The local Canvas ID of the learning outcome. |
| **short_description** | Also the title of the outcome. |
| **title** | The title of the learning outcome or learning outcome group. |
| **updated_at** | The time at which this outcome was last modified in any way. |
| **vendor_guid** | A custom GUID for the learning standard. |
| **workflow_state** | Workflow status of the learning outcome. Defaults to active |
| **rubric_criterion** | {"description"=>"Also the title of the outcome.", "mastery_points"=>"The number of points necessary for a rating to be considered mastery.", "points_possible"=>"The maximum level of points of any rating.", "ratings"=>"Array of objects with (points, description) describing each of the outcoming ratings."} |



<h2 id="outcome_proficiency_created">outcome_proficiency_created</h2>

**Definition:** The event is emitted anytime a new outcome_proficiency is created by an end user or API request.

**Trigger:** Triggered when a new outcome_proficiency is saved.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "user_login": "oxana@instructure.com",
    "user_account_id": "21070000000000001",
    "user_sis_id": "456-T45",
    "user_id": "21070000000000001",
    "time_zone": "America/Denver",
    "context_type": "Account",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/accounts/1/outcome_proficiency",
    "referrer": null,
    "producer": "canvas",
    "event_name": "outcome_proficiency_created",
    "event_time": "2020-08-18T23:28:24.396Z"
  },
  "body": {
    "outcome_proficiency_id": "1",
    "context_type": "Account",
    "context_id": "1",
    "workflow_state": "active",
    "outcome_proficiency_ratings": [
      {
        "outcome_proficiency_rating_id": "1",
        "description": "Exceeds Mastery",
        "points": 4.0,
        "mastery": false,
        "color": "127A1B",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "2",
        "description": "Mastery",
        "points": 3.0,
        "mastery": true,
        "color": "00AC18",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "3",
        "description": "Near Mastery",
        "points": 2.0,
        "mastery": false,
        "color": "FAB901",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "4",
        "description": "Below Mastery",
        "points": 1.0,
        "mastery": false,
        "color": "FD5D10",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "5",
        "description": "Well Below Mastery",
        "points": 0.0,
        "mastery": false,
        "color": "EE0612",
        "workflow_state": "active"
      }
    ]
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **outcome_proficiency_id** | The Canvas id of the outcome proficiency. |
| **context_type** | The type of context the outcome proficiency is used in. |
| **context_id** | The id of the context the outcome proficiency is used in. |
| **workflow_state** | Workflow state of the outcome proficiency. E.g active, deleted. |
| **outcome_proficiency_ratings** | An array of the associated ratings with this proficiency. Description, points, mastery, color, workflow_state, and outcome_proficiency_rating_id are required keys. |



<h2 id="outcome_proficiency_updated">outcome_proficiency_updated</h2>

**Definition:** The event is emitted anytime an outcome_proficiency is updated or its associated ratings are updated by an end user or API request.

**Trigger:** Triggered when an outcome_proficiency is saved.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "user_login": "oxana@instructure.com",
    "user_account_id": "21070000000000001",
    "user_sis_id": "456-T45",
    "user_id": "21070000000000001",
    "time_zone": "America/Denver",
    "context_type": "Account",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/accounts/1/outcome_proficiency",
    "referrer": null,
    "producer": "canvas",
    "event_name": "outcome_proficiency_updated",
    "event_time": "2020-08-18T23:28:24.396Z"
  },
  "body": {
    "outcome_proficiency_id": "1",
    "context_type": "Account",
    "context_id": "1",
    "workflow_state": "active",
    "updated_at": "2020-08-18T17:24:46-06:00",
    "outcome_proficiency_ratings": [
      {
        "outcome_proficiency_rating_id": "1",
        "description": "Exceeds Mastery",
        "points": 4.0,
        "mastery": false,
        "color": "127A1B",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "2",
        "description": "Mastery",
        "points": 3.0,
        "mastery": true,
        "color": "00AC18",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "3",
        "description": "Near Mastery",
        "points": 2.0,
        "mastery": false,
        "color": "FAB901",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "4",
        "description": "Below Mastery",
        "points": 1.0,
        "mastery": false,
        "color": "FD5D10",
        "workflow_state": "active"
      },
      {
        "outcome_proficiency_rating_id": "5",
        "description": "Well Below Mastery",
        "points": 0.0,
        "mastery": false,
        "color": "EE0612",
        "workflow_state": "active"
      }
    ]
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **outcome_proficiency_id** | The Canvas id of the outcome proficiency. |
| **context_type** | The type of context the outcome proficiency is used in. |
| **context_id** | The id of the context the outcome proficiency is used in. |
| **workflow_state** | Workflow state of the outcome proficiency. E.g active, deleted. |
| **updated_at** | The time at which this proficiency was last modified in any way. |
| **outcome_proficiency_ratings** | An array of the associated ratings with this proficiency. Description, points, mastery, color, workflow_state, and outcome_proficiency_rating_id are required keys. |



