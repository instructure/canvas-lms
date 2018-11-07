Live Events (experimental)
==============

Live Events allows you to receive a set of real-time events happening in
your Canvas instance. The events are delivered to a queue which you are
then responsible for consuming. Supported events are described below.

Events are delivered in a "best-effort" fashion. In order to not slow
down web requests, events are sent asynchronously from web requests.
That means that there's a window where an event may happen, but the
process responsible for sending the request to the queue is not able to
queue it.

The currently supported queue is <a href="https://aws.amazon.com/sqs/">Amazon SQS</a>.

Live Events is currently an invite-only, experimental feature.


Additional Documentation can be viewed at
[Live Events Services Table of Contents](https://community.canvaslms.com/docs/DOC-15740-live-events-services-table-of-contents)


### Live Events - Canvas Raw Format

The events, fields, and data in this document are specific to the Canvas Raw format.

[See Caliper v1.1 formatted events here](https://canvas.instructure.com/doc/api/file.caliper_live_events.html)

#### Event Attributes

Events are delivered with attributes and a message. The attributes are:

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `event_name` | String | The name of the event. | `submission_created`, `asset_accessed` |
| `event_time` | String.timestamp | The time, in ISO 8601 format. | `2015-03-18T15:15:54Z` |


#### Message (Metadata)

The message is a JSON-formatted string with two keys: `metadata` and `body`.
`metadata` will be any or all of the following keys and values, if the
event originated as part of a web request:

| Name | Type | Description |
| ---- | ---- | ----------- |
| `context_id` | String | The Canvas id of the current context. Always use the `context_type` when using this id to lookup the object. |
| `context_role` | String | The role of the current user in the current context.  |
| `context_type` | String | The type of context where the event happened. |
| `event_name` | String | The name of the event. |
| `event_time` | String.timestamp | The time, in ISO 8601 format. |
| `hostname` | String | The hostname of the current request |
| `producer` | String | The name of the producer of an event. Will always be 'canvas' when an event is originating in canvas. |
| `real_user_id` | String | If the current user is being masqueraded, this is the Canvas id of the masquerading user. |
| `request_id` | String | The identifier for this request. |
| `root_account_id` | String | The Canvas id of the root account associated with the current user. |
| `root_account_lti_guid` | String | The Canvas lti_guid of the root account associated with the current user. |
| `root_account_uuid` | String | The Canvas uuid of the root account associated with the current user. |
| `session_id` | String | The session identifier for this request. Can be used to correlate events in the same session for a user. |
| `user_account_id` | String | The Canvas id of the account that the current user belongs to. |
| `user_agent` | String | The User-Agent sent by the browser making the request. |
| `user_id`    | String | The Canvas id of the currently logged in user. |
| `user_login` | String | The login of the current user. |
| `user_sis_id` | String | The SIS id of the user. |


For events originating as part of an asynchronous job, the following
fields may be set:

| Name | Type | Description |
| ---- | ---- | ----------- |
| `job_id` | String | The identifier for the asynchronous job. |
| `job_tag` | String | A string identifying the type of job being performed. |
| `root_account_uuid` | String | The Canvas uuid of the root account associated with the context of the job. |
| `root_account_id` | String | The Canvas id of the root account associated with the context of the job. |
| `root_account_lti_guid` | String | The Canvas lti_guid of the root account associated with the context of the job. |


#### Message (Body)

The `body` object will have key/value pairs with information specific to
each event, as described below.

Note that the actual bodies of events may include more fields than
what's described in this document. Those fields are subject to change.

For more message payload examples see
https://community.canvaslms.com/docs/DOC-15741-event-type-by-format

Note: All Canvas ids are "global" identifiers, returned as strings.
However, some context_id's sent in the body of the message will be the local id.

### Supported Events

#### `account_notification_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `account_notification_id` | bigint | The Canvas id of the account notification. |
| `subject` | varchar | The subject of the notification. |
| `message` | varchar | The message to be sent in the notification. |
| `icon` | varchar | The icon to display with the message. Defaults to warning. |
| `start_at` | datetime | When to send out the notification. |
| `end_at` | datetime | When to expire the notification. |


#### `asset_accessed`

`asset_accessed` events are triggered for viewing various objects in
Canvas. Viewing a quiz, a wiki page, the list of quizzes, etc, all
generate `asset_access` events. The item being accessed is identified by
`asset_type`, `asset_id`, and `asset_subtype`. If `asset_subtype` is
set, then it refers to a list of items in the asset. For example, if
`asset_type` is `course`, and `asset_subtype` is `quizzes`, then this is
referring to viewing the list of quizzes in the course.

If `asset_subtype` is not set, then the access is on the asset described
by `asset_type` and `asset_id`.


| Name | Type | Description |
| ---- | ---- | ----------- |
| `asset_id` | bigint | The Canvas id of the asset. |
| `asset_type` | varchar | The type of asset being accessed. |
| `asset_subtype` | varchar | See above. |
| `category` | varchar | Basically nagivation routes like Announcements, Assignments, Calendar, Pages, Quizzes, Roster, Syllabus |
| `level` | varchar | eventfielddescription |
| `role` | varchar | The role of the user accessing the asset. |


#### `assignment_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `assignment_id` | bigint | The Canvas id of the new assignment. |
| `title` | varchar | The title of the assignment (possibly truncated). |
| `description` | varchar | The description of the assignment (possibly truncated). |
| `due_at` | datetime | The due date for the assignment. |
| `unlock_at` | datetime | The unlock date (assignment is unlocked after this date). |
| `lock_at` | datetime | The lock date (assignment is locked after this date). |
| `updated_at` | datetime | The time at which this assignment was last modified in any way. |
| `points_possible` | double precision | The maximum points possible for the assignment. |
| `workflow_state` | varchar | Workflow state of the assignment. |
| `lti_assignment_id` | varchar | The LTI assignment guid for the assignment. |
| `lti_resource_link_id` | varchar | eventfielddescription |
| `lti_resource_link_id_duplicated_from` | varchar | eventfielddescription |


#### `assignment_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `assignment_id` | bigint | The Canvas id of the new assignment. |
| `title` | varchar | The title of the assignment (possibly truncated). |
| `description` | varchar | The description of the assignment (possibly truncated). |
| `due_at` | datetime | The due date for the assignment. |
| `unlock_at` | datetime | The unlock date (assignment is unlocked after this date). |
| `lock_at` | datetime | The lock date (assignment is locked after this date). |
| `updated_at` | datetime | The time at which this assignment was last modified in any way. |
| `points_possible` | double precision | The maximum points possible for the assignment. |
| `workflow_state` | varchar | Workflow state of the assignment. |
| `lti_assignment_id` | varchar | The LTI assignment guid for the assignment. |
| `lti_resource_link_id` | varchar | eventfielddescription |
| `lti_resource_link_id_duplicated_from` | varchar | eventfielddescription |


#### `attachment_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint | The Canvas id of the user associated with the attachment. |
| `attachment_id` | bigint | The Canvas id of the attachment. |
| `display_name` | varchar | The display name of the attachment (possibly truncated). |
| `filename` | varchar | The file name of the attachment (possibly truncated). |
| `folder_id` | bigint | The id of the folder where the attachment was saved. |
| `unlock_at` | datetime | The unlock date (attachment is unlocked after this date). |
| `lock_at` | datetime | The lock date (attachment is locked after this date). |
| `updated_at` | datetime | The time at which this attachment was last modified in any way .|
| `context_type` | varchar | The type of context the attachment is used in. |
| `context_id` | varchar | The id of the context the attachment is used in. |
| `content_type` | varchar | The content type of the attachment. |


#### `attachment_deleted`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint | The Canvas id of the user associated with the attachment. |
| `attachment_id` | bigint | The Canvas id of the attachment. |
| `display_name` | varchar | The display name of the attachment (possibly truncated). |
| `filename` | varchar | The file name of the attachment (possibly truncated). |
| `folder_id` | bigint | The id of the folder where the attachment was saved. |
| `unlock_at` | datetime | The unlock date (attachment is unlocked after this date). |
| `lock_at` | datetime | The lock date (attachment is locked after this date). |
| `updated_at` | datetime | The time at which this attachment was last modified in any way. |
| `context_type` | varchar | The type of context the attachment is used in. |
| `context_id` | varchar | The id of the context the attachment is used in. |
| `content_type` | varchar | The content type of the attachment. |


#### `attachment_updated`

`attachment_updated` events are triggered when an attachment's `display_name` is updated.

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint | The Canvas id of the user associated with the attachment. |
| `attachment_id` | bigint | The Canvas id of the attachment. |
| `display_name` | varchar | The old display name of the attachment (possibly truncated). |
| `old_display_name` | varchar | The new display name of the attachment (possibly truncated). |
| `filename` | varchar | The file name of the attachment (possibly truncated). |
| `folder_id` | bigint | The id of the folder where the attachment was saved. |
| `unlock_at` | datetime | The unlock date (attachment is unlocked after this date). |
| `lock_at` | datetime | The lock date (attachment is locked after this date). |
| `updated_at` | datetime | The time at which this attachment was last modified in any way. |
| `context_type` | varchar | The type of context the attachment is used in. |
| `context_id` | varchar | The id of the context the attachment is used in. |
| `content_type` | varchar | The content type of the attachment. |


#### `content_migration_completed`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `content_migration_id` | bigint | The Canvas id of the content migration |
| `context_id` | bigint | The Canvas id of the context associated with the content migration. |
| `context_type` | varchar | The type of context associated with the content migration. |
| `lti_context_id` | varchar | The lti context id of the context associated with the content migration.  |
| `context_uuid` | varchar | The uuid of the context associated with the content migration. |
| `import_quizzes_next` | boolean | Indicates whether the user requested that the quizzes in the content migration be created in Quizzes.Next (true) or in native Canvas (false). |


#### `course_completed`

The body fields for this event are nested.

| Name | Type | Description |
| ---- | ---- | ----------- |
| `progress['requirement_count']` | int | Count of all the requirements in the course as a number. |
| `progress['requirement_completed_count']` | int | The count of those requirements that are done. |
| `progress['next_requirement_url']` | varchar |  Link to the module item that is next in the order of requirements to complete. |
| `progress['completed_at']` | datetime | Timestamp when the course was completed. |
| `user['email']` | varchar | The students email. |
| `user['id']` | varchar | The Canvas id of the student completing the course. |
| `user['name']` | varchar | The name of the student. |
| `course['id']` | int | The local Canvas id of the course. |
| `course['name']` | varchar | The name of the course. |

```javascript
"body": {
  "progress": {
    "requirement_count": 99,
    "requirement_completed_count": 99,
    "next_requirement_url": nil,
    "completed_at": "2018-10-18T20:50:35Z"
  },
  "user": {
    "id": "1234567",
    "name": "Sheldon Cooper",
    "email": "sheldon@caltech.example.com"
  },
  "course": {
    "id": "123456",
    "name": "Computer Science I"
  }
}
```

#### `course_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `course_id` | bigint | The Canvas id of the created course. |
| `uuid` | varchar | The unique id of the course. |
| `account_id` | bigint | The Account id of the created course. |
| `name` | varchar | The name the created course. |
| `created_at` | datetime | The time at which this course was created. |
| `updated_at` | datetime | The time at which this course was last modified in any way. |
| `workflow_state` | varchar | The state of the course.  |


#### `course_section_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `course_section_id` | integer | The local Canvas id of the section. |
| `sis_source_id` | varchar | Correlated id for the record for this course in the SIS system (assuming SIS integration is configured). |
| `sis_batch_id` | varchar | The batch id of the sis import. |
| `course_id` | integer | The local Canvas id of the course. |
| `enrollment_term_id` | varchar | The Canvas if of the enrollment term. |
| `name` | varchar | The name of the course. |
| `default_section` | boolean | eventfielddescription |
| `accepting_enrollments` | varchar | eventfielddescription |
| `can_manually_enroll` | varchar | eventfielddescription |
| `start_at` | datetime | Section start date in ISO8601 format. |
| `end_at` | datetime | Section end date in ISO8601 format. |
| `workflow_state` | varchar | The workflow state of the section. |
| `restrict_enrollments_to_section_dates` | boolean | eventfielddescription |
| `nonxlist_course_id` | varchar | The unique identifier of the original course of a cross-listed section. |
| `stuck_sis_fields` | varchar | eventfielddescription |
| `integration_id` | varchar | eventfielddescription |


#### `course_section_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `course_section_id` | integer | The local Canvas id of the section. |
| `sis_source_id` | varchar | Correlated id for the record for this course in the SIS system (assuming SIS integration is configured). |
| `sis_batch_id` | varchar | The batch id of the sis import. |
| `course_id` | integer | The local Canvas id of the course. |
| `enrollment_term_id` | varchar | The Canvas if of the enrollment term. |
| `name` | varchar | The name of the course. |
| `default_section` | boolean | eventfielddescription |
| `accepting_enrollments` | varchar | eventfielddescription |
| `can_manually_enroll` | varchar | eventfielddescription |
| `start_at` | datetime | Section start date in ISO8601 format. |
| `end_at` | datetime | Section end date in ISO8601 format. |
| `workflow_state` | varchar | The workflow state of the section. |
| `restrict_enrollments_to_section_dates` | boolean | eventfielddescription |
| `nonxlist_course_id` | varchar | The unique identifier of the original course of a cross-listed section. |
| `stuck_sis_fields` | varchar | eventfielddescription |
| `integration_id` | varchar | eventfielddescription |


#### `course_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `course_id` | bigint | The Canvas id of the updated course. |
| `account_id` | bigint | The Account id of the updated course. |
| `uuid` | varchar | The unique id of the course. |
| `name` | varchar | The name the updated course. |
| `created_at` | datetime | The time at which this course was created. |
| `updated_at` | datetime | The time at which this course was last modified in any way. |
| `workflow_state` | varchar | The state of the course. |


#### `discussion_entry_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `discussion_entry_id` | bigint | The Canvas id of the newly added entry. |
| `parent_discussion_entry_id` | bigint | If this was a reply, the Canvas id of the parent entry. |
| `parent_discussion_entry_author_id` | bigint | If this was a reply, the Canvas id of the parent entry author. |
| `discussion_topic_id` | bigint | The Canvas id of the topic the entry was added to. |
| `text` | text | The (possibly truncated) text of the post. |


#### `discussion_topic_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `discussion_topic_id` | bigint | The Canvas id of the new discussion topic. |
| `is_announcement` | boolean | `true` if this topic was posted as an announcement, `false` otherwise. |
| `title` | varchar | Title of the topic (possibly truncated). |
| `body` | text | Body of the topic (possibly truncated). |


#### `enrollment_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `enrollment_id` | bigint | The Canvas id of the new enrollment. |
| `course_id` | bigint | The Canvas id of the course for this enrollment. |
| `user_id` | bigint | The Canvas id of the user for this enrollment. |
| `user_name` | varchar | The user's name. |
| `type` | varchar | The type of enrollment; e.g. 'StudentEnrollment', 'TeacherEnrollment', etc. |
| `created_at` | datetime | The time at which this enrollment was created. |
| `updated_at` | datetime | The time at which this enrollment was last modified in any way. |
| `limit_privileges_to_course_section` | boolean | Whether students can only talk to students within their course section. |
| `course_section_id` | bigint | The id of the section of the course for the new enrollment. |
| `associated_user_id` | bigint | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
| `workflow_state` | varchar | The state of the enrollment. |


#### `enrollment_state_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `enrollment_id` | bigint | The Canvas id of the new enrollment. |
| `state` | varchar |  The state of the enrollment. |
| `state_started_at` | datetime | The time when this enrollment state starts. |
| `state_is_current` | boolean | If this enrollment_state is uptodate. |
| `state_valid_until` | datetime | The time at which this enrollment is no longer valid. |
| `restricted_access` | boolean | True if this enrollment_state is restricted. |
| `access_is_current` | boolean |  If this enrollment_state access is uptodate. |
| `state_invalidated_at` | datetime | Time enrollment_state was invalidated. |
| `state_recalculated_at` | datetime | Time enrollment_state was created. |
| `access_invalidated_at` | datetime | Time enrollment_state access was invalidated. |
| `access_recalculated_at` | datetime | Time enrollment_state access was created. |


#### `enrollment_state_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `enrollment_id` | bigint | The Canvas id of the new enrollment. |
| `state` | varchar |  The state of the enrollment. |
| `state_started_at` | datetime | The time when this enrollment state starts. |
| `state_is_current` | boolean | If this enrollment_state is uptodate. |
| `state_valid_until` | datetime | The time at which this enrollment is no longer valid. |
| `restricted_access` | boolean | True if this enrollment_state is restricted. |
| `access_is_current` | boolean |  If this enrollment_state access is uptodate. |
| `state_invalidated_at` | datetime | Time enrollment_state was invalidated. |
| `state_recalculated_at` | datetime | Time enrollment_state was created. |
| `access_invalidated_at` | datetime | Time enrollment_state access was invalidated. |
| `access_recalculated_at` | datetime | Time enrollment_state access was created. |


#### `enrollment_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `enrollment_id` | bigint | The Canvas id of the new enrollment. |
| `course_id` | bigint | The Canvas id of the course for this enrollment. |
| `user_id` | bigint | The Canvas id of the user for this enrollment. |
| `user_name` | varchar | The user's name. |
| `type` | varchar | The type of enrollment; e.g. 'StudentEnrollment', 'TeacherEnrollment', etc. |
| `created_at` | datetime | The time at which this enrollment was created. |
| `updated_at` | datetime | The time at which this enrollment was last modified in any way. |
| `limit_privileges_to_course_section` | boolean | Whether students can only talk to students within their course section. |
| `course_section_id` | bigint | The id of the section of the course for the new enrollment. |
| `associated_user_id` | bigint | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
| `workflow_state` | varchar | The state of the enrollment. |


#### `grade_change`

`grade_change` events are posted every time a grade changes. These can
happen as the result of a teacher changing a grade in the gradebook or
speedgrader, a quiz being automatically scored, or changing an assignment's
points possible or grade type. In the case of a quiz being scored, the
`grade_change` event will be fired as the result of a student turning in a
quiz, and the `user_id` in the message attributes will be of the student. In
these cases, `grader_id` should be null in the body.

| Name | Type | Description |
| ---- | ---- | ----------- |
| `submission_id` | bigint | The Canvas id of the submission that the grade is changing on. |
| `assignment_id` | bigint | The Canvas id of the assignment associated with the submission. |
| `grade` | varchar | The new grade. |
| `old_grade` | varchar | The previous grade, if there was one.  |
| `score` | double precision | The new score. |
| `old_score` | double precision | The previous score. |
| `points_possible` | double precision | The maximum points possible for the submission's assignment. |
| `old_points_possible` | double precision | The maximum points possible for the previous grade. |
| `grader_id` | bigint | The Canvas id of the user making the grade change. Null if this was the result of automatic grading. |
| `user_id` | bigint | The Canvas id of the user associated to the submission with the change. |
| `student_id` | bigint | Same as the user_id. |
| `student_sis_id` | varchar | The SIS ID of the student. |
| `muted` | boolean | The boolean muted state of the submissions's assignment. Muted grade changes should not be published to students. |
| `grading_complete` | boolean | The boolean state that the submission is completely graded. False if the assignment is only partially graded, for example a quiz with automatically and manually graded sections. Incomplete grade changes should not be published to students. |


#### `group_category_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_category_id` | bigint | The Canvas id of the newly created group category. |
| `group_category_name` | varchar | The name of the newly created group category. |
| `group_limit` | integer | The cap of the number of users in each group. |
| `context_id` | integer | The Canvas id of the group's context. |
| `context_type` | varchar | The type of the group's context ('Account' or 'Course') |


#### `group_category_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_category_id` | varchar |  The Canvas id of the newly created group category. |
| `group_category_name` | varchar | The name of the newly created group category. |
| `group_limit` | varchar | The cap of the number of users in each group. |
| `context_id` | integer | The Canvas id of the group's context. |
| `context_type` | varchar | The type of the group's context ('Account' or 'Course') |


#### `group_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_id` | bigint | The Canvas id of the group. |
| `group_name` | varchar | The name of the group. |
| `group_category_id` | bigint | The Canvas id of the group category. |
| `group_category_name` | varchar | The name of the group category. |
| `context_type` | varchar |  The type of the group's context ('Account' or 'Course'). |
| `context_id` | varchar | The Canvas id of the group's context. |
| `uuid` | varchar | The unique id of the group. |
| `account_id` | bigint | The Canvas id of the group's account. |
| `workflow_state` | varchar | The state of the group. |
| `max_membership` | integer | The maximum membership cap for the group |


#### `group_membership_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_membership_id` | bigint | The Canvas id of the group membership. |
| `user_id` | bigint | The Canvas id of the user being assigned to a group. |
| `group_id` | bigint | The Canvas id of the group the user is assigned to. |
| `group_name` | varchar | The name of the group the user is being assigned to. |
| `group_category_id` | bigint | The Canvas id of the group category. |
| `group_category_name` | varchar | The name of the group category. |
| `workflow_state` | varchar | The state of the group membership. |


#### `group_membership_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_membership_id` | bigint | The Canvas id of the group membership. |
| `user_id` | bigint | The Canvas id of the user assigned to a group. |
| `group_id` | bigint | The Canvas id of the group the user is assigned to. |
| `group_name` | varchar | The name of the group the user is assigned to. |
| `group_category_id` | bigint | The Canvas id of the group category. |
| `group_category_name` | varchar | The name of the group category. |
| `workflow_state` | varchar | The state of the group membership. |


#### `group_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `group_id` | bigint | The Canvas id of the group. |
| `group_name` | varchar | The name of the group. |
| `group_category_id` | bigint | The Canvas id of the group category. |
| `group_category_name` | varchar | The name of the group category. |
| `context_type` | varchar |  The type of the group's context ('Account' or 'Course'). |
| `context_id` | varchar | The Canvas id of the group's context. |
| `uuid` | varchar | The unique id of the group. |
| `account_id` | bigint | The Canvas id of the group's account. |
| `workflow_state` | varchar | The state of the group. |
| `max_membership` | integer | The maximum membership cap for the group |


#### `logged_in`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `redirect_url` | text | The URL the user was redirected to after logging in. Is set when the user logs in after clicking a deep link into Canvas. |


#### `logged_out`

No extra data.

#### `module_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `module_id` | integer | The Canvas id of the module. |
| `context_id` | varchar | The local Canvas id of the context. |
| `context_type` | varchar | The type of module's context ('Course'). |
| `name` | varchar | The name of the module. |
| `position` | integer | The position of the module in the course. |
| `workflow_state` | varchar | The workflow state of the module. |


#### `module_item_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `module_item_id` | integer | The Canvas id of the module item. |
| `module_id` | integer | The Canvas id of the module. |
| `context_id` | varchar | The local Canvas id of the context. |
| `context_type` | varchar | The type of module's context ('Course'). |
| `position` | integer | The position of the module item in the module. |
| `workflow_state` | varchar | The workflow state of the module item. |


#### `module_item_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `module_item_id` | integer | The Canvas id of the module item. |
| `module_id` | integer | The Canvas id of the module. |
| `context_id` | varchar | The local Canvas id of the context. |
| `context_type` | varchar | The type of module's context ('Course'). |
| `position` | integer | The position of the module item in the module. |
| `workflow_state` | varchar | The workflow state of the module item. |


#### `module_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `module_id` | integer | The Canvas id of the module. |
| `context_id` | varchar | The local Canvas id of the context. |
| `context_type` | varchar | The type of module's context ('Course'). |
| `name` | varchar | The name of the module. |
| `position` | integer | The position of the module in the course. |
| `workflow_state` | varchar | The workflow state of the module. |


#### `plagiarism_resubmit`

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the new submission. |
| `assignment_id` | The Canvas id of the assignment being submitted. |
| `user_id` | The Canvas id of the user associated with the submission. |
| `lti_user_id` | The Lti id of the user associated with the submission. |
| `submitted_at` | The timestamp when the assignment was submitted. |
| `updated_at` | The time at which this assignment was last modified in any way |
| `score` | The raw score |
| `grade` | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example)|
| `submission_type` | The types of submission ex: ('online_text_entry'\|'online_url'\|'online_upload'\|'media_recording') |
| `body` | The content of the submission, if it was submitted directly in a text field. (possibly truncated) |
| `url` | The URL of the submission (for 'online_url' submissions) |
| `attempt` | This is the submission attempt number. |
| `lti_assignment_id` | The LTI assignment guid of the submission's assignment |
| `group_id` | The submissions’s group ID if the assignment is a group assignment. |


#### `quiz_export_complete`

The body fields for this event are nested.

| Name | Type | Description |
| ---- | ---- | ----------- |
| `assignment['resource_link_id']` | varchar | eventfielddescription |
| `assignment['title']` | varchar | Title of the quiz |
| `assignment['context_title']` | varchar | Title of the course |
| `assignment['course_uuid']` | varchar | The unique id of the course for this association.|
| `qti_export['url']` | varchar | The URL of the exported quiz, zip file |

```javascript
"body": {
  "assignment": {
    "resource_link_id": "9b8a57aa143083d824fae97a79d15525dafedc9d",
    "title": "Quiz Title",
    "context_title": "Course Title",
    "course_uuid": "nXSr0rA8dAbC5vWe1evjOLMhYV9nxyzSXszT1U6T"
  },
  "qti_export": {
    "url": "https://instructure-uploads.s3.amazonaws.com/account_100000000123456/attachments/123456/course-name-quiz-export.zip?[...]"
  }
}
```

#### `quiz_submitted`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `submission_id` | bigint | The Canvas id of the quiz submission |
| `quiz_id` | bigint | The Canvas id of the quiz. |


#### `submission_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `submission_id` | bigint | The Canvas id of the new submission. |
| `assignment_id` | bigint | The Canvas id of the assignment being submitted. |
| `user_id` | bigint | The Canvas id of the user associated with the submission. |
| `lti_user_id` | varchar | The LTI id of the user associated with the submission. |
| `lti_assignment_id` | varchar | The LTI assignment guid of the submission's assignment |
| `submitted_at` | datetime | The timestamp when the assignment was submitted. |
| `graded_at` | datetime | The timestamp when the assignment was graded, if it was graded. |
| `updated_at` | datetime | The time at which this assignment was last modified in any way |
| `score` | double precision | The raw score |
| `grade` | varchar | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example) |
| `submission_type` | varchar | The types of submission ex: ('online_text_entry'\|'online_url'\|'online_upload'\|'media_recording') |
| `body` | text | The content of the submission, if it was submitted directly in a text field. (possibly truncated) |
| `url` | varchar | The URL of the submission (for 'online_url' submissions) |
| `attempt` | integer | This is the submission attempt number. |
| `group_id` | integer | The submissions’s group ID if the assignment is a group assignment. |


#### `submission_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `submission_id` | bigint | The Canvas id of the new submission. |
| `assignment_id` | bigint | The Canvas id of the assignment being submitted. |
| `user_id` | bigint | The Canvas id of the user associated with the submission. |
| `lti_user_id` | varchar | The LTI id of the user associated with the submission. |
| `lti_assignment_id` | varchar | The LTI assignment guid of the submission's assignment |
| `submitted_at` | datetime | The timestamp when the assignment was submitted. |
| `graded_at` | datetime | The timestamp when the assignment was graded, if it was graded. |
| `updated_at` | datetime | The time at which this assignment was last modified in any way |
| `score` | double precision | The raw score |
| `grade` | varchar | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example) |
| `submission_type` | varchar | The types of submission ex: ('online_text_entry'\|'online_url'\|'online_upload'\|'media_recording') |
| `body` | text | The content of the submission, if it was submitted directly in a text field. (possibly truncated) |
| `url` | varchar | The URL of the submission (for 'online_url' submissions) |
| `attempt` | integer | This is the submission attempt number. |
| `group_id` | integer | The submissions’s group ID if the assignment is a group assignment. |


#### `syllabus_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `course_id` | bigint | The Canvas id of the updated course. |
| `syllabus_body` | text | The new syllabus content (possibly truncated). |
| `old_syllabus_body` | text | The old syllabus content (possibly truncated). |


#### `user_account_association_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint |  The Canvas id of the user for this association. |
| `account_id` | bigint | The Canvas id of the account for this association. |
| `account_uuid` | varchar | The unique id of the account for this association. |
| `created_at` | datetime | The time at which this association was created. |
| `updated_at` | datetime | The time at which this association was last modified. |
| `is_admin` | boolean | The roles the user has in the account. |


#### `user_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint | The Canvas id of user. |
| `uuid` | varchar | Unique user id. |
| `name` | varchar | Name of user. |
| `short_name` | varchar | Short name of user. |
| `workflow_state` | varchar | State of the user. |
| `created_at` | datetime | The time at which this user was created. |
| `updated_at` | datetime | The time at which this user was last modified in any way. |


#### `user_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id` | bigint | The Canvas id of user. |
| `uuid` | varchar | Unique user id. |
| `name` | varchar | Name of user. |
| `short_name` | varchar | Short name of user. |
| `workflow_state` | varchar | State of the user. |
| `created_at` | datetime | The time at which this user was created. |
| `updated_at` | datetime | The time at which this user was last modified in any way. |


#### `wiki_page_created`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `wiki_page_id` | bigint | The Canvas id of the new wiki page. |
| `title` | varchar | The title of the new page (possibly truncated). |
| `body` | text | The body of the new page (possibly truncated). |


#### `wiki_page_deleted`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `wiki_page_id` | bigint | The Canvas id of the delete wiki page. |
| `title` | varchar | The title of the deleted wiki page (possibly truncated). |


#### `wiki_page_updated`

| Name | Type | Description |
| ---- | ---- | ----------- |
| `wiki_page_id` | bigint |  The Canvas id of the changed wiki page. |
| `title` | varchar | The new title (possibly truncated). |
| `old_title` | varchar | The old title (possibly truncated). |
| `body` | text | The new page body (possibly truncated). |
| `old_body` | text | The old page body (possibly truncated). |
