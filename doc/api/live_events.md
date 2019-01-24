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
| `root_account_uuid` | String | The Canvas uuid of the root account associated with the current user. |
| `root_account_id` | String | The Canvas id of the root account associated with the current user. |
| `root_account_lti_guid` | String | The Canvas lti_guid of the root account associated with the current user. |
| `context_type` | String | The type of context where the event happened. |
| `context_id` | String | The Canvas id of the current context. Always use the `context_type` when using this id to lookup the object. |
| `role` | String | The role of the current user in the current context.  |
| `hostname` | String | The hostname of the current request |
| `producer` | String | The name of the producer of an event. Will always be 'canvas' when an event is originating in canvas. |
| `request_id` | String | The identifier for this request. |
| `session_id` | String | The session identifier for this request. Can be used to correlate events in the same session for a user. |
| `user_account_id` | String | The Canvas id of the account that the current user belongs to. |
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

#### Body (data)

The `body` object will have key/value pairs with information specific to
each event, as described below.

Note: All Canvas ids are "global" identifiers, returned as strings.


### Supported Events

Note that the actual bodies of events may include more fields than
what's described in this document. Those fields are subject to change.


#### `course_created`

| Field | Description |
| ----- | ----------- |
| `course_id` | The Canvas id of the created course. |
| `uuid` | The unique id of the course. |
| `account_id` | The Account id of the created course. |
| `name` | The name the created course. |
| `created_at` | The time at which this course was created. |
| `updated_at` | The time at which this course was last modified in any way. |
| `workflow_state` | The state of the course. |

#### `course_updated`

| Field | Description |
| ----- | ----------- |
| `course_id` | The Canvas id of the updated course. |
| `account_id` | The Account id of the updated course. |
| `name` | The name the updated course. |
| `created_at` | The time at which this course was created. |
| `updated_at` | The time at which this course was last modified in any way. |
| `workflow_state` | The state of the course. |


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
| `assignment_id` | The Canvas id of the topic's associated assignment |
| `context_id` | The Canvas id of the topic's context |
| `context_type` | The type of the topic's context (usually 'Assignment') |
| `workflow_state` | The state of the topic |
| `lock_at` | The lock date (discussion is locked after this date) |
| `updated_at` | The time at which this topic was last modified in any way |

#### `discussion_topic_updated`

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
| `group_category_name` | The name of the newly created group category. |


#### `group_created`

| Field | Description |
| ----- | ----------- |
| `group_id` | The Canvas id of the group. |
| `uuid` | The unique id of the group. |
| `group_name` | The name of the group. |
| `group_category_id` | The Canvas id of the group category. |
| `group_category_name` | The name of the group category. |
| `context_type` | The type of the group's context ('Account' or 'Course'). |
| `context_id` | The Canvas id of the group's context. |
| `account_id` | The Canvas id of the group's account. |
| `workflow_state` | The state of the group. |


#### `group_updated`

| Field | Description |
| ----- | ----------- |
| `group_id` | The Canvas id of the group. |
| `group_name` | The name of the group. |
| `group_category_id` | The Canvas id of the group category. |
| `group_category_name` | The name of the group category. |
| `context_type` | The type of the group's context ('Account' or 'Course'). |
| `context_id` | The Canvas id of the group's context. |
| `account_id` | The Canvas id of the group's account. |
| `workflow_state` | The state of the group. |


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
| `workflow_state` | The state of the group membership. |


#### `group_membership_updated`

| Field | Description |
| ----- | ----------- |
| `group_membership_id` | The Canvas id of the group membership. |
| `user_id` | The Canvas id of the user assigned to a group. |
| `group_id` | The Canvas id of the group the user is assigned to. |
| `group_name` | The name of the group the user is assigned to. |
| `group_category_id` | The Canvas id of the group category. |
| `group_category_name` | The name of the group category. |
| `workflow_state` | The state of the group membership. |


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


#### `grade_change`

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
| `muted` | The boolean muted state of the submissions's assignment.  Muted grade changes
should not be published to students. |
| `grading_complete` | The boolean state that the submission is completely graded.  False
if the assignment is only partially graded, for example a quiz with automatically and manually
graded sections. Incomplete grade changes should not be published to students. |

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
| `lti_assignment_id` | The LTI assignment guid for the assignment |


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
| `lti_assignment_id` | The LTI assignment guid for the assignment |

#### `assignment_group_created`

| Field | Description |
| ----- | ----------- |
| `assignment_group_id` | The Canvas id of the new assignment group. |
| `context_id` | The Canvas context id of the new assignment group. |
| `context_type` | The context type of the new assignment group. |
| `name` | The name of the new assignment group. |
| `position` | The position of the new assignment group. |
| `group_weight` | The group weight of the new assignment grou. |
| `sis_source_id` | The SIS source id of the new assignment group. |
| `integration_data` | Integration data for the new assignment group. |
| `rules` | Rules for the new assignment group. |

#### `assignment_group_updated`

| Field | Description |
| ----- | ----------- |
| `assignment_group_id` | The Canvas id of the updated assignment group. |
| `context_id` | The Canvas context id of the updated assignment group. |
| `context_type` | The context type of the updated assignment group. |
| `name` | The name of the updated assignment group. |
| `position` | The position of the updated assignment group. |
| `group_weight` | The group weight of the updated assignment group. |
| `sis_source_id` | The SIS source id of the updated assignment group. |
| `integration_data` | Integration data for the updated assignment group. |
| `rules` | Rules for the updated assignment group. |

#### `submission_created`

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


#### `submission_updated`

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

#### `user_created`

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of user. |
| `uuid` | Unique user id. |
| `name` | Name of user. |
| `short_name` | Short name of user. |
| `workflow_state` | State of the user. |
| `created_at` | The time at which this user was created. |
| `updated_at` | The time at which this user was last modified in any way. |


#### `user_updated`

| Field | Description |
| ----- | ----------- |
| `user_id` | The Canvas id of user. |
| `name` | Name of user. |
| `short_name` | Short name of user. |
| `workflow_state` | State of the user. |
| `created_at` | The time at which this user was created. |
| `updated_at` | The time at which this user was last modified in any way. |


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
| `limit_privileges_to_course_section` | Whether students can only talk to students within their course section. |
| `course_section_id` | The id of the section of the course for the new enrollment. |
| `associated_user_id` | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
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
| `limit_privileges_to_course_section` | Whether students can only talk to students within their course section. |
| `course_section_id` | The id of the section of the course for the new enrollment. |
| `associated_user_id` | The id of the user observed by an observer's enrollment. Omitted from non-observer enrollments. |
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
| `account_uuid` | The unique id of the account for this association.|
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

#### `module_created`

| Field | Description |
| ----- | ----------- |
| `module_id` | The Canvas id of the module. |
| `name` | The name of the module. |
| `position` | The position of the module in the course. |
| `workflow_state` | The workflow state of the module. |

#### `module_updated`

| Field | Description |
| ----- | ----------- |
| `module_id` | The Canvas id of the module. |
| `name` | The name of the module. |
| `position` | The position of the module in the course. |
| `workflow_state` | The workflow state of the module. |

#### `module_item_created`

| Field | Description |
| ----- | ----------- |
| `module_item_id` | The Canvas id of the module item. |
| `position` | The position of the module item in the module. |
| `workflow_state` | The workflow state of the module item. |

#### `module_item_updated`

| Field | Description |
| ----- | ----------- |
| `module_item_id` | The Canvas id of the module item. |
| `position` | The position of the module item in the module. |
| `workflow_state` | The workflow state of the module item. |

#### `content_migration_completed`

| Field | Description |
| ----- | ----------- |
| `content_migration_id` | The Canvas id of the content migration. |
| `context_id` | The Canvas id of the context associated with the content migration. |
| `context_type` | The type of context associated with the content migration. |
| `lti_context_id` | The lti context id of the context associated with the content migration. |
| `context_uuid` | The uuid of the context associated with the content migration. |
| `import_quizzes_next` | Indicates whether the user requested that the quizzes in the content migration be created in Quizzes.Next (true) or in native Canvas (false). |
