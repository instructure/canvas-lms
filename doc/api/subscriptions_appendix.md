A tool must have certain capabilities enabled in order to create webhook subscriptions for a given event type in a given context. These capabilities can only be obtained through the use of a custom tool consumer profile.

All available event types are listed bellow along with the capability that will allow creating
subscriptions of the associated type.

### `QUIZ_SUBMITTED` Event Type
* vnd.instructure.webhooks.root_account.quiz_submitted
* vnd.instructure.webhooks.assignment.quiz_submitted

### `GRADE_CHANGE` Event Type
* vnd.instructure.webhooks.root_account.grade_change

### `ATTACHMENT_CREATED` Event Type
* vnd.instructure.webhooks.root_account.attachment_created
* vnd.instructure.webhooks.assignment.attachment_created

### `SUBMISSION_CREATED` Event Type
* vnd.instructure.webhooks.root_account.submission_created
* vnd.instructure.webhooks.assignment.submission_created

### `SUBMISSION_UPDATED` Event Type
* vnd.instructure.webhooks.root_account.submission_updated
* vnd.instructure.webhooks.assignment.submission_updated

### `PLAGIARISM_RESUBMIT` Event Type
* vnd.instructure.webhooks.root_account.plagiarism_resubmit
* vnd.instructure.webhooks.assignment.plagiarism_resubmit

### All Event Types
* vnd.instructure.webhooks.root_account.all
