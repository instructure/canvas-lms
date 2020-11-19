Group
==============

<h2 id="group_category_created">group_category_created</h2>

**Definition:** The event is emitted anytime a new group category is added to a course group by an end user or API request.

**Trigger:** Triggered when a new group category is created.




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
    "event_name": "group_category_created",
    "event_time": "2019-11-01T15:06:48.462Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/assignments/7655/edit",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Monterrey",
    "url": "https://oxana.instructure.com/api/v1/courses/565/group_categories",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "565",
    "context_type": "Course",
    "group_category_id": "21070000000000049",
    "group_category_name": "Live_events_Group1",
    "group_limit": 99
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The Canvas id of the group's context. |
| **context_type** | The type of the group's context. |
| **group_category_id** | The Canvas id of the newly created group category. |
| **group_category_name** | The name of the newly created group category. |
| **group_limit** | The cap of the number of users in each group. |



<h2 id="group_category_updated">group_category_updated</h2>

**Definition:** The event is emitted anytime a group category is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a group category is modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "group_category_updated",
    "event_time": "2019-11-01T13:49:58.816Z",
    "hostname": "oxana.instructure.com",
    "http_method": "DELETE",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/546/groups",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/group_categories/1143?includes[]=unassigned_users_count&includes[]=groups_count",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "context_id": "546",
    "context_type": "Course",
    "group_category_id": "21070000000001143",
    "group_category_name": "Group 1 Updated",
    "group_limit": 99
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **context_id** | The Canvas id of the group's context. |
| **context_type** | The type of the group's context. |
| **group_category_id** | The Canvas id of the newly created group category. |
| **group_category_name** | The name of the newly created group category. |
| **group_limit** | The cap of the number of users in each group. |



<h2 id="group_created">group_created</h2>

**Definition:** The event is emitted anytime a new group is added to a course by an end user or API request.

**Trigger:** Triggered when a new group is created.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "group_created",
    "event_time": "2019-11-01T00:08:52.795Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/groups",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/group_categories/1149/groups",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_type": "Course",
    "group_category_id": "21070000000001149",
    "group_category_name": "Live_events_Group1",
    "group_id": "21070000000000051",
    "group_name": "Group 1",
    "max_membership": 100,
    "uuid": "axUYte7Y2ktt62hYUlU5QcMt3T3VbGzAJLASM6tn",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_id** | The Canvas id of the group's account. |
| **context_id** | The Canvas id of the group's context. |
| **context_type** | The type of the group's context ('Account' or 'Course'). |
| **group_category_id** | The Canvas id of the group category. |
| **group_category_name** | The name of the group category. |
| **group_id** | The Canvas id of the group. |
| **group_name** | The name of the group. |
| **max_membership** | The maximum membership cap for the group. |
| **uuid** | The unique id of the group. |
| **workflow_state** | The state of the group. (available, deleted) |



<h2 id="group_membership_created">group_membership_created</h2>

**Definition:** The event is emitted anytime a new member is added to a course group by an end user or API request.

**Trigger:** Triggered when a new user is added to a group.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "group_membership_created",
    "event_time": "2019-11-01T19:11:21.467Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/135519/groups",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/group_categories/30575/clone_with_name",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "group_category_id": "21070000000049012",
    "group_category_name": "Live_events_Group1",
    "group_id": "21070000000000051",
    "group_membership_id": "21070000000123460",
    "group_name": "Group 1",
    "user_id": "21070000000000047",
    "workflow_state": "accepted"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **group_category_id** | The Canvas id of the group category. |
| **group_category_name** | The name of the group category. |
| **group_id** | The Canvas id of the group the user is assigned to. |
| **group_membership_id** | The Canvas id of the group membership. |
| **group_name** | The name of the group the user is being assigned to. |
| **user_id** | The Canvas id of the user being assigned to a group. |
| **workflow_state** | The state of the group membership. |



<h2 id="group_membership_updated">group_membership_updated</h2>

**Definition:** The event is emitted anytime an existing group membership  is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a existing group membership is modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "group_membership_updated",
    "event_time": "2019-11-01T19:11:07.176Z",
    "hostname": "oxana.instructure.com",
    "http_method": "POST",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/13/groups",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/New_York",
    "url": "https://oxana.instructure.com/api/v1/groups/15/memberships",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "group_category_id": "21070000000000049",
    "group_category_name": "Live_events_Group1",
    "group_id": "21070000000000051",
    "group_membership_id": "21070000000000460",
    "group_name": "Group 1",
    "user_id": "21070000000000047",
    "workflow_state": "deleted"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **group_category_id** | The Canvas id of the group category. |
| **group_category_name** | The name of the group category. |
| **group_id** | The Canvas id of the group the user is assigned to. |
| **group_membership_id** | The Canvas id of the group membership. |
| **group_name** | The name of the group the user is assigned to. |
| **user_id** | The Canvas id of the user assigned to a group. |
| **workflow_state** | The state of the group membership. |



<h2 id="group_updated">group_updated</h2>

**Definition:** The event is emitted anytime an existing group is updated by an end user or API request. Only changes to the fields included in the body of the event payload will emit the `updated` event.

**Trigger:** Triggered when a group is modified.




### Payload Example:

```json
{
  "metadata": {
    "client_ip": "93.184.216.34",
    "event_name": "group_updated",
    "event_time": "2019-11-01T19:11:21.332Z",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "producer": "canvas",
    "referrer": "https://oxana.instructure.com/courses/565/groups",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "time_zone": "America/Bogota",
    "url": "https://oxana.instructure.com/groups/48",
    "user_account_id": "21070000000000001",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "user_id": "21070000000000001",
    "user_login": "oxana@example.com",
    "user_sis_id": "456-T45"
  },
  "body": {
    "account_id": "21070000000000079",
    "context_id": "21070000000000565",
    "context_type": "Course",
    "group_category_id": "21070000000000044",
    "group_category_name": "My Group Category",
    "group_id": "21070000000000048",
    "group_name": "My Group",
    "max_membership": 100,
    "uuid": "7CGV0SxY8DkslTomd4MTqkcbQbcTGuZ6Jg96XnLY",
    "workflow_state": "available"
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **account_id** | The Canvas id of the group's account. |
| **context_id** | The Canvas id of the group's context. |
| **context_type** | The type of the group's context ('Account' or 'Course'). |
| **group_category_id** | The Canvas id of the group category. |
| **group_category_name** | The name of the group category. |
| **group_id** | The Canvas id of the group. |
| **group_name** | The name of the group. |
| **max_membership** | The maximum membership cap for the group. |
| **uuid** | The unique id of the group. |
| **workflow_state** | The state of the group. (available, deleted) |



