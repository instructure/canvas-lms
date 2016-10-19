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


### Event Format

#### Event Attributes

Events are delivered with attributes and a body. The attributes are:

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `event_name` | String | The name of the event. | `create_discussion_topic` |
| `event_time` | String.timestamp | The time, in ISO 8601 format. | `2015-03-18T15:15:54Z` |

#### Body (metadata)

The body is a JSON-formatted string with two keys: `metadata` and `data`.
`metadata` will be any or all of the following keys and values, if the
event originated as part of a web request:

| Name | Type | Description |
| ---- | ---- | ----------- |
| `user_id`    | String | The Canvas id of the currently logged in user. |
| `real_user_id` | String | If the current user is being masqueraded, this is the Canvas id of the masquerading user. |
| `user_login` | String | The login of the current user. |
| `user_agent` | String | The User-Agent sent by the browser making the request. |
| `root_account_id` | String | The Canvas id of the root account associated with the current user. |
| `root_account_lti_guid` | String | The Canvas lti_guid of the root account associated with the current user. |
| `context_type` | String | The type of context where the event happened. |
| `context_id` | String | The Canvas id of the current context. Always use the `context_type` when using this id to lookup the object. |
| `role` | String | The role of the current user in the current context.  |
| `hostname` | String | The hostname of the current request |
| `request_id` | String | The identifier for this request. |
| `session_id` | String | The session identifier for this request. Can be used to correlate events in the same session for a user. |

For events originating as part of an asynchronous job, the following
fields may be set:

| Name | Type | Description |
| ---- | ---- | ----------- |
| `job_id` | String | The identifier for the asynchronous job. |
| `job_tag` | String | A string identifying the type of job being performed. |


#### Body (data)

The `body` object will have key/value pairs with information specific to
each event, as described below.

Note: All Canvas ids are "global" identifiers, returned as strings.


### Supported Events

Note that the actual bodies of events may include more fields than
what's described in this document. Those fields are subject to change.


#### `syllabus_updated`

| Field | Description |
| ----- | ----------- |
| `course_id` | The Canvas id of the updated course. |
| `syllabus_body` | The new syllabus content (possibly truncated). |
| `old_syllabus_body` | The old syllabus content (possibly truncated). |


#### `discussion_entry_created`

| Field | Description |
| ----- | ----------- |
| `discussion_entry_id` | The Canvas id of the newly added entry. |
| `parent_discussion_entry_id` | If this was a reply, the Canvas id of the parent entry. |
| `parent_discussion_entry_author_id` | If this was a reply, the Canvas id of the parent entry author. |
| `discussion_topic_id` | The Canvas id of the topic the entry was added to. |
| `text` | The (possibly truncated) text of the post. |


#### `discussion_topic_created`

| Field | Description |
| ----- | ----------- |
| `discussion_topic_id` | The Canvas id of the new discussion topic. |
| `is_announcement` | `true` if this topic was posted as an announcement, `false` otherwise. |
| `title` | Title of the topic (possibly truncated). |
| `body` | Body of the topic (possibly truncated). |


#### `group_category_created`

| Field | Description |
| ----- | ----------- |
| `group_category_id` | The Canvas id of the newly created group category. |
| `group_category_name` | The name of the newly created group. |


#### `group_created`

| Field | Description |
| ----- | ----------- |
| `group_id` | The Canvas id of the group the user is assigned to. |
| `group_name` | The name of the group the user is being assigned to. |
| `group_category_id` | The Canvas id of the group category. |
| `group_category_name` | The name of the group category. |


#### `group_membership_created`

Note: Only manual group assignments are currently sent. Groups where
people are automatically assigned to groups will not send `group_assign`
events.

| Field | Description |
| ----- | ----------- |
| `group_membership_id` | The Canvas id of the group membership. |
| `user_id` | The Canvas id of the user being assigned to a group. |
| `group_id` | The Canvas id of the group the user is assigned to. |
| `group_name` | The name of the group the user is being assigned to. |
| `group_category_id` | The Canvas id of the group category. |
| `group_category_name` | The name of the group category. |


#### `logged_in`

| Field | Description |
| ----- | ----------- |
| `redirect_url` | The URL the user was redirected to after logging in. Is set when the user logs in after clicking a deep link into Canvas. |


#### `logged_out`

No extra data.


#### `quiz_submitted`

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the quiz submission. |
| `quiz_id` | The Canvas id of the quiz. |


#### `grade_changed`

`grade_change` events are posted every time a grade changes. These can
happen as the result of a teacher changing a grade in the gradebook or
speedgrader, a quiz being automatically scored, or changing an assignment's
points possible or grade type. In the case of a quiz being scored, the
`grade_change` event will be fired as the result of a student turning in a
quiz, and the `user_id` in the message attributes will be of the student. In
these cases, `grader_id` should be null in the body.

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the submission that the grade is changing on. |
| `assignment_id` | The Canvas id of the assignment associated with the submission. |
| `grade` | The new grade. |
| `old_grade` | The previous grade, if there was one. |
| `score` | The new score. |
| `old_score` | The previous score. |
| `points_possible` | The maximum points possible for the submission's assignment. |
| `old_points_possible` | The maximum points possible for the previous grade. |
| `grader_id` | The Canvas id of the user making the grade change. Null if this was the result of automatic grading. |
| `user_id` | The Canvas id of the user associated with the submission with the change. |


#### `wiki_page_created`

| Field | Description |
| ----- | ----------- |
| `wiki_page_id` | The Canvas id of the new wiki page. |
| `title` | The title of the new page (possibly truncated). |
| `body` | The body of the new page (possibly truncated). |


#### `wiki_page_updated`

| Field | Description |
| ----- | ----------- |
| `wiki_page_id` | The Canvas id of the changed wiki page. |
| `title` | The new title (possibly truncated). |
| `old_title` | The old title (possibly truncated). |
| `body` | The new page body (possibly truncated). |
| `old_body` | The old page body (possibly truncated). |


#### `wiki_page_deleted`

| Field | Description |
| ----- | ----------- |
| `wiki_page_id` | The Canvas id of the delete wiki page. |
| `title` | The title of the deleted wiki page (possibly truncated). |


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


| Field | Description |
| ----- | ----------- |
| `asset_type` | The type of asset being accessed. |
| `asset_id` | The Canvas id of the asset. |
| `asset_subtype` | See above. |


#### `assignment_created`

| Field | Description |
| ----- | ----------- |
| `assignment_id` | The Canvas id of the new assignment. |
| `title` | The title of the assignment (possibly truncated). |
| `description` | The description of the assignment (possibly truncated). |
| `due_at` | The due date for the assignment. |
| `unlock_at` | The unlock date (assignment is unlocked after this date) |
| `lock_at` | The lock date (assignment is locked after this date) |
| `updated_at` | The time at which this assignment was last modified in any way |
| `points_possible` | The maximum points possible for the assignment |


#### `assignment_updated`

| Field | Description |
| ----- | ----------- |
| `assignment_id` | The Canvas id of the new assignment. |
| `title` | The title of the assignment (possibly truncated). |
| `description` | The description of the assignment (possibly truncated). |
| `due_at` | The due date for the assignment. |
| `unlock_at` | The unlock date (assignment is unlocked after this date) |
| `lock_at` | The lock date (assignment is locked after this date) |
| `updated_at` | The time at which this assignment was last modified in any way |
| `points_possible` | The maximum points possible for the assignment |


#### `submission_created`

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the new submission. |
| `assignment_id` | The Canvas id of the assignment being submitted. |
| `user_id` | The Canvas id of the user associated with the submission. |
| `submitted_at` | The timestamp when the assignment was submitted. |
| `updated_at` | The time at which this assignment was last modified in any way |
| `score` | The raw score |
| `grade` | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example)|
| `submission_type` | The types of submission ex: ('online_text_entry'\|'online_url'\|'online_upload'\|'media_recording') |
| `body` | The content of the submission, if it was submitted directly in a text field. (possibly truncated) |
| `url` | The URL of the submission (for 'online_url' submissions) |
| `attempt` | This is the submission attempt number. |


#### `submission_updated`

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the new submission. |
| `assignment_id` | The Canvas id of the assignment being submitted. |
| `user_id` | The Canvas id of the user associated with the submission. |
| `submitted_at` | The timestamp when the assignment was submitted. |
| `updated_at` | The time at which this assignment was last modified in any way |
| `score` | The raw score |
| `grade` | The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example)|
| `submission_type` | The types of submission ex: ('online_text_entry'\|'online_url'\|'online_upload'\|'media_recording') |
| `body` | The content of the submission, if it was submitted directly in a text field. (possibly truncated) |
| `url` | The URL of the submission (for 'online_url' submissions) |
| `attempt` | This is the submission attempt number. |


#### `enrollment_created`

| Field | Description |
| ----- | ----------- |
| `enrollment_id` | The Canvas id of the new enrollment. |
| `course_id` | The Canvas id of the course for this enrollment. |
| `user_id` | The Canvas id of the user for this enrollment. |
| `user_name` | The user's name. |
| `type` | The type of enrollment; e.g. 'StudentEnrollment', 'TeacherEnrollment', etc. |
| `created_at` | The time at which this enrollment was created. |
| `updated_at` | The time at which this enrollment was last modified in any way. |
| `limit_privileges_to_course_section ` | Whether students can only talk to students withing their course section. |
| `course_section_id ` | The id of the section of the course for the new enrollment. |
| `workflow_state` | The state of the enrollment. |

#### `enrollment_updated`

| Field | Description |
| ----- | ----------- |
| `enrollment_id` | The Canvas id of the new enrollment. |
| `course_id` | The Canvas id of the course for this enrollment. |
| `user_id` | The Canvas id of the user for this enrollment. |
| `user_name` | The user's name. |
| `type` | The type of enrollment; e.g. 'StudentEnrollment', 'TeacherEnrollment', etc. |
| `created_at` | The time at which this enrollment was created. |
| `updated_at` | The time at which this enrollment was last modified in any way. |
| `limit_privileges_to_course_section ` | Whether students can only talk to students withing their course section. |
| `course_section_id ` | The id of the section of the course for the new enrollment. |
| `workflow_state` | The state of the enrollment. |

#### `enrollment_state_created`

| Field | Description |
| ----- | ----------- |
| `enrollment_id` | The Canvas id of the new enrollment. |
| `state` | The state of the enrollment. |
| `state_started_at` | The time when this enrollment state starts. |
| `state_is_current` | If this enrollment_state is uptodate |
| `state_valid_until` | The time at which this enrollment is no longer valid. |
| `restricted_access` | True if this enrollment_state is restricted. |
| `access_is_current ` | If this enrollment_state access is upto date. |
| `state_invalidated_at ` | Time enrollment_state was invalidated. |
| `state_recalculated_at` | Time enrollment_state was created. |
| `access_invalidated_at` | Time enrollment_state access was invalidated. |
| `access_recalculated_at` | Time enrollment_state access was created. |

#### `enrollment_state_updated`

| Field | Description |
| ----- | ----------- |
| `enrollment_id` | The Canvas id of the new enrollment. |
| `state` | The state of the enrollment. |
| `state_started_at` | The time when this enrollment state starts. |
| `state_is_current` | If this enrollment_state is uptodate |
| `state_valid_until` | The time at which this enrollment is no longer valid. |
| `restricted_access` | True if this enrollment_state is restricted. |
| `access_is_current ` | If this enrollment_state access is upto date. |
| `state_invalidated_at ` | Time enrollment_state was invalidated. |
| `state_recalculated_at` | Time enrollment_state was created. |
| `access_invalidated_at` | Time enrollment_state access was invalidated. |
| `access_recalculated_at` | Time enrollment_state access was created. |


#### `user_account_association_created`

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of the user for this association. |
| `account_id` | The Canvas id of the account for this association. |
| `created_at` | The time at which this association was created. |
| `updated_at` | The time at which this association was last modified. |
| `roles` | The roles the user has in the account. |

#### `attachment_created`

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of the user associated with the attachment. |
| `attachment_id` | The Canvas id of the attachment. |
| `display_name` | The display name of the attachment (possibly truncated). |
| `filename` | The file name of the attachment (possibly truncated). |
| `unlock_at` | The unlock date (attachment is unlocked after this date) |
| `lock_at` | The lock date (attachment is locked after this date) |
| `updated_at` | The time at which this attachment was last modified in any way |
| `context_type` | The type of context the attachment is used in. |
| `context_id` | The id of the context the attachment is used in. |
| `content_type` | The content type of the attachment. |

#### `attachment_updated`

`attachment_updated` events are triggered when an attachment's `display_name` is updated.

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of the user associated with the attachment. |
| `attachment_id` | The Canvas id of the attachment. |
| `display_name` | The display name of the attachment (possibly truncated). |
| `old_display_name` | The old display name of the attachment (possibly truncated). |
| `filename` | The file name of the attachment (possibly truncated). |
| `unlock_at` | The unlock date (attachment is unlocked after this date) |
| `lock_at` | The lock date (attachment is locked after this date) |
| `updated_at` | The time at which this attachment was last modified in any way |
| `context_type` | The type of context the attachment is used in. |
| `context_id` | The id of the context the attachment is used in. |
| `content_type` | The content type of the attachment. |

#### `attachment_deleted`

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of the user associated with the attachment. |
| `attachment_id` | The Canvas id of the attachment. |
| `display_name` | The display name of the attachment (possibly truncated). |
| `filename` | The file name of the attachment (possibly truncated). |
| `unlock_at` | The unlock date |
| `lock_at` | The lock date |
| `updated_at` | The time at which this attachment was last modified in any way |
| `context_type` | The type of context the attachment is used in. |
| `context_id` | The id of the context the attachment is used in. |
| `content_type` | The content type of the attachment. |

#### `account_notification_created`

| Field | Description |
| ----- | ----------- |
| `account_notification_id` | The Canvas id of the account notification. |
| `subject` | The subject of the notification. |
| `message` | The message to be sent in the notification. |
| `icon` | The icon to display with the message.  Defaults to warning. |
| `start_at` | When to send out the notification. |
| `end_at` | When to expire the notification. |