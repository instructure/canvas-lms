Account
==============

<h2 id="account_notification_created">account_notification_created</h2>

**Definition:** The event is emitted anytime an account level notification is created by and end user or API request.

**Trigger:** Triggered anytime a new account notification is created.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "user_login": "oxana@example.com",
    "user_account_id": "21070000000000001",
    "user_sis_id": "456-T45",
    "user_id": "21070000000000001",
    "time_zone": "America/Chicago",
    "context_type": "Account",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "TaEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/accounts/4/account_notifications",
    "referrer": "https://oxana.instructure.com/accounts/8/settings",
    "producer": "canvas",
    "event_name": "account_notification_created",
    "event_time": "2019-11-01T18:42:07.091Z"
  },
  "body": {
    "account_notification_id": "21070000000000004",
    "end_at": "2018-10-12T06:00:00Z",
    "icon": "information",
    "message": "<p>This is a new Announcement</p>",
    "start_at": "2018-10-12T06:00:00Z",
    "subject": "This is a new Announcement"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_notification_id** | The Canvas id of the account notification. |
| **end_at** | When to expire the notification. |
| **icon** | The icon to display with the message.  Defaults to warning. |
| **message** | The message to be sent in the notification. NOTE: This field will be truncated to only include the first 8192 characters. |
| **start_at** | When to send out the notification. |
| **subject** | The subject of the notification. NOTE: This field will be truncated to only include the first 8192 characters. |



