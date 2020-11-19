User
==============

<h2 id="user_account_association_created">user_account_association_created</h2>

**Definition:** The event is emitted anytime a user is created in an account.

**Trigger:** Triggered when a user is added to an account.




### Payload Example:

```json
{
  "metadata": {
    "event_name": "user_account_association_created",
    "event_time": "2019-11-01T19:11:11.717Z",
    "job_id": "1020020528469291",
    "job_tag": "SIS::CSV::ImportRefactored#run_parallel_importer",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "account_id": "21070000000000079",
    "account_uuid": "5CaqE03jAic6wjkvgbjaerkucZtFyIvYnsW1t62H",
    "created_at": "2019-11-01T19:11:11.717Z",
    "is_admin": false,
    "updated_at": "2019-11-01T19:11:11.717Z",
    "user_id": "21070000000000712"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_id** | The Canvas id of the account for this association. |
| **account_uuid** | The unique id of the account for this association. |
| **created_at** | The time at which this association was created. |
| **is_admin** | Is user an administrator? |
| **updated_at** | The time at which this association was last modified. |
| **user_id** | The Canvas id of the user for this association. |



<h2 id="user_created">user_created</h2>

**Definition:** The event is emitted anytime a user is added to an account.

**Trigger:** Triggered when a new user is created.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "context_account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_type": "Account",
    "developer_key_id": "170000000056",
    "event_name": "user_created",
    "event_time": "2019-11-01T19:11:11.964Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": null,
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Denver",
    "url": "https://oxana.instructure.com/api/v1/accounts/1625/users",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "created_at": "2019-05-09T19:32:25Z",
    "name": "test user",
    "short_name": "test user",
    "updated_at": "2019-05-09T19:32:25Z",
    "user_id": "21070000000025999",
    "user_login": "test",
    "user_sis_id": "456-T45",
    "uuid": "kDfqdZrVWAxrI6RmFBNqipEGKozQR0sYolwPfsvM",
    "workflow_state": "pre_registered"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **created_at** | The time at which this user was created. |
| **name** | Name of user. |
| **short_name** | Short name of user. |
| **updated_at** | The time at which this user was last modified in any way. |
| **user_id** | The Canvas id of user. |
| **user_login** | The login of the current user. |
| **user_sis_id** | The SIS id of the user. |
| **uuid** | Unique user id. |
| **workflow_state** | State of the user. |



<h2 id="user_updated">user_updated</h2>

**Definition:** The event is emitted anytime a user details are updated. Only changes to the fields included in the body of the event payload will emit the `updated` event. The metadata of the event payload will list a user or process that updated the user profile details and the body of the event will list a user details that were updated.

**Trigger:** Triggered when a user record is updated.




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
    "event_name": "user_updated",
    "event_time": "2019-11-01T19:11:01.163Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/2635/gradebook",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": null,
    "url": "https://oxana.instructure.com/api/v1/courses/16175/gradebook_settings",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000025999",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "created_at": "2019-05-01T19:32:25Z",
    "name": "test user 1",
    "short_name": "test user 1",
    "updated_at": "019-11-01T19:11:01.163Z",
    "user_id": "21070000000025999",
    "user_login": "test",
    "user_sis_id": "456-T45",
    "uuid": "kDfqdZrVWAxrI6RmFBNqipEGKozQR0sYolwPfsvM",
    "workflow_state": "registered"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **created_at** | The time at which this user was created. |
| **name** | Name of user. |
| **short_name** | Short name of user. |
| **updated_at** | The time at which this user was last modified in any way. |
| **user_id** | The Canvas id of user. |
| **user_login** | The login of the current user. |
| **user_sis_id** | The SIS id of the user. |
| **uuid** | Unique user id. |
| **workflow_state** | State of the user. (deleted, pre_registered, registered) |



