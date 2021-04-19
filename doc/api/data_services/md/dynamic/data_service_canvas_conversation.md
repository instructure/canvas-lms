Conversation
==============

<h2 id="conversation_created">conversation_created</h2>

**Definition:** The event is emitted anytime a new conversation is initiated by the sender.

**Trigger:** Triggered when a new conversation is created.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000123",
    "user_login": "inewton@example.com",
    "user_sis_id": "456-T45",
    "time_zone": "America/Denver",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "client_ip": "93.184.216.34",
    "url": "http://oxana.instructure.com/conversations",
    "referrer": "http://oxana.instructure.com/conversations",
    "producer": "canvas",
    "event_name": "conversation_created",
    "event_time": "2020-03-24T16:55:59.973Z"
  },
  "body": {
    "conversation_id": "123456789",
    "updated_at": "2018-09-24T06:00:00Z"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **conversation_id** | The Canvas id of the conversation. |
| **updated_at** | The time this conversation was updated. |



<h2 id="conversation_forwarded">conversation_forwarded</h2>

**Definition:** The event is emitted when a conversation is updated.

**Trigger:** Triggered when a new user is added to a conversation




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000123",
    "user_login": "inewton@example.com",
    "user_sis_id": "456-T45",
    "time_zone": "America/Denver",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "client_ip": "93.184.216.34",
    "url": "http://oxana.instructure.com/conversations/11/add_message",
    "referrer": "http://oxana.instructure.com/conversations",
    "producer": "canvas",
    "event_name": "conversation_forwarded",
    "event_time": "2020-03-27T17:30:26.715Z"
  },
  "body": {
    "conversation_id": "11",
    "updated_at": "2020-03-30T11:18:51-06:00"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **conversation_id** | The Canvas id of the conversation. |
| **updated_at** | The time this conversation was updated. |



<h2 id="conversation_message_created">conversation_message_created</h2>

**Definition:** The event is emitted anytime a new conversation message is added to a conversation.

**Trigger:** Triggered when a new conversation mesage is created.




### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000123",
    "user_login": "inewton@example.com",
    "user_sis_id": "456-T45",
    "time_zone": "America/Denver",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "client_ip": "93.184.216.34",
    "url": "http://oxana.instructure.com/conversations/53/add_message",
    "referrer": "http://oxana.instructure.com/conversations",
    "producer": "canvas",
    "event_name": "conversation_message_created",
    "event_time": "2020-03-24T21:42:38.385Z"
  },
  "body": {
    "author_id": "2",
    "conversation_id": "53",
    "created_at": "2020-03-24T21:42:37Z",
    "message_id": "45"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **author_id** | The Canvas id of the author. |
| **conversation_id** | The Canvas id of the conversation. |
| **created_at** | The time this conversation message was created. |
| **message_id** | The Canvas id of the conversation message. |



