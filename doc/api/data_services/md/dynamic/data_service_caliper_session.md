Session
==============

<h2 id="logged_in">logged_in</h2>

**Definition:** The event is emitted anytime an end user logs into Canvas

**Trigger:** Triggered when a user has logged in.


### Event Body Schema

| Field | Description |
|-|-|
| **data[0].object.extensions["com.instructure.canvas"].redirect_url** | The URL the user was redirected to after logging in. Is set when the user logs in after clicking a deep link into Canvas |
| **data[0].object.type** | SoftwareApplication |





### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:09:11.771Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:2b6d64bf-5b31-4e2f-b389-c6ebcb232407",
      "type": "SessionEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "LoggedIn",
      "object": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication",
        "extensions": {
          "com.instructure.canvas": {
            "redirect_url": "https://oxana.instructure.com/"
          }
        }
      },
      "eventTime": "2019-11-01T19:11:01.335Z",
      "referrer": "https://oxana.instructure.com/idp/profile/SAML2/Redirect/SSO?execution=e1s2",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "session": {
        "id": "urn:instructure:canvas:session:ef686f8ed684abf78cbfa1f6a58112b5",
        "type": "Session"
      },
      "extensions": {
        "com.instructure.canvas": {
          "hostname": "oxana.instructure.com",
          "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
          "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
          "client_ip": "93.184.216.34",
          "request_url": "https://oxana.instructure.com/login/saml",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```




<h2 id="logged_out">logged_out</h2>

**Definition:** The event is emitted anytime an end user logs out of Canvas

**Trigger:** Triggered when a user has logged out.


### Event Body Schema

| Field | Description |
|-|-|
| **data[0].object.type** | SoftwareApplication |





### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:09:12.082Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:63f716c7-b56c-4d52-945a-8d0a1daa33f2",
      "type": "SessionEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "LoggedOut",
      "object": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "eventTime": "2019-11-01T19:11:04.195Z",
      "referrer": "https://oxana.instructure.com/courses/1188569/quizzes/4266352?module_item_id=23650329",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "session": {
        "id": "urn:instructure:canvas:session:ef686f8ed684abf78cbfa1f6a58112b5",
        "type": "Session"
      },
      "extensions": {
        "com.instructure.canvas": {
          "hostname": "oxana.instructure.com",
          "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
          "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
          "client_ip": "93.184.216.34",
          "request_url": "https://oxana.instructure.com/logout",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```




