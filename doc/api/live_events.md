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

#### Attributes

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
| `user_id`    | Number | The Canvas id of the currently logged in user. |
| `real_user_id` | Number | If the current user is being masqueraded, this is the Canvas id of the masquerading user. |
| `user_login` | String | The login of the current user. |
| `user_agent` | String | The User-Agent sent by the browser making the request. |
| `context_type` | String | The type of context where the event happened. |
| `context_id` | Number | The Canvas id of the current context. Always use the `context_type` when using this id to lookup the object. |
| `role` | String | The role of the current user in the current context.  |
| `hostname` | String | The hostname of the current request |
| `request_id` | String | The identifier for this request. |
| `session_id` | String | The session identifier for this request. Can be used to correlate events in the same session for a user. |

For events originating as part of an asynchronous job, the following
fields may be set:

| Name | Type | Description |
| ---- | ---- | ----------- |
| `job_id` | Number | The identifier for the asynchronous job. |
| `job_tag` | String | A string identifying the type of job being performed. |


#### Body (data)

The `body` object will have key/value pairs with information specific to
each event, as described below.

Note: All Canvas ids are "global" identifiers.


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
| `group_category_name` | The name of the newly created group |


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
happen either as the result of a teacher changing a grade in the
gradebook or speedgrader, or with a quiz being automatically scored. In
the case of a quiz being scored, the `grade_change` event will be fired
as the result of a student turning in a quiz, and the `user_id` in the
message attributes will be of the student. In these cases, `grader_id`
should be null in the body.

| Field | Description |
| ----- | ----------- |
| `submission_id` | The Canvas id of the submission that the grade is changing on. |
| `grade` | The new grade. |
| `old_grade` | The previous grade, if there was one. |
| `grader_id` | The Canvas id of the user making the grade change. Null if this was the result of automatic grading. |
| `student_id` | The Canvas id of the student associated with the submission with the change. |


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

