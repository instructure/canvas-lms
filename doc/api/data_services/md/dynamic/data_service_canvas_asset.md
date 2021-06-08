Asset
==============

<h2 id="asset_accessed">asset_accessed</h2>

**Definition:** `asset_accessed` events are triggered for viewing various objects in Canvas. Viewing a quiz, a wiki page, the list of quizzes, etc, all generate `asset_access` events. The item being accessed is identified by `asset_type`, `asset_id`, and `asset_subtype`. If `asset_subtype` is set, then it refers to a list of items in the asset. For example, if `asset_type` is `course`, and `asset_subtype` is `quizzes`, then this is referring to viewing the list of quizzes in the course.

If `asset_subtype` is not set, then the access is on the asset described by `asset_type` and `asset_id`.

**Trigger:** Triggered when a variety of assets are viewed.


**Description:** type=group, subtype=conferences

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
    "time_zone": "America/New_York",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/144/conferences",
    "referrer": "https://oxana.instructure.com/groups/144/conferences",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.150Z"
  },
  "body": {
    "asset_name": "MATH 101 Group 1",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "conferences",
    "category": "conferences",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=course, subtype=assignments

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
    "time_zone": "America/Los_Angeles",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/assignments",
    "referrer": "https://oxana.instructure.com/courses/144/assignments/64541?module_item_id=313255",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.753Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "assignments",
    "category": "assignments",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=enrollment

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
    "time_zone": "America/Los_Angeles",
    "context_type": "Course",
    "context_id": "21070000000001234",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/1234/users/14320",
    "referrer": "https://oxana.instructure.com/courses/1234/users",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:30.201Z"
  },
  "body": {
    "asset_name": null,
    "asset_type": "enrollment",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "roster",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=files

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
    "time_zone": "America/New_York",
    "developer_key_id": "170000000056",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/144/files?sort=updated_at&order=desc",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.907Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "files",
    "category": "files",
    "role": null,
    "level": null
  }
}
```


**Description:** type=user, subtype=calendar_feed

### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/feeds/calendars/user_ABdASKrt432fdKSDALhGDSL83423kFDRK32.ics",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.718Z"
  },
  "body": {
    "asset_name": "Sally Student",
    "asset_type": "user",
    "asset_id": "21070000000000144",
    "asset_subtype": "calendar_feed",
    "category": "calendar",
    "role": null,
    "level": null
  }
}
```


**Description:** type=collaboration

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
    "context_type": "Course",
    "context_id": "21070000000008346",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/8346/collaborations/144",
    "referrer": "https://oxana.instructure.com/courses/8346/collaborations",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:35:15.069Z"
  },
  "body": {
    "asset_name": "Example Collaboration",
    "asset_type": "collaboration",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "collaborations",
    "role": "StudentEnrollment",
    "level": "participate"
  }
}
```


**Description:** type=user, subtype=files

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
    "developer_key_id": "170000000056",
    "context_type": "User",
    "context_id": "21070000000000144",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/users/144/files?sort=updated_at&order=desc",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:23.214Z"
  },
  "body": {
    "asset_name": "Sally Student",
    "asset_type": "user",
    "asset_id": "21070000000000144",
    "asset_subtype": "files",
    "category": "files",
    "role": null,
    "level": null
  }
}
```


**Description:** type=account, subtype=outcomes

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
    "context_id": "21070000000000001",
    "context_sis_source_id": null,
    "context_account_id": "210700000000000001",
    "context_role": "AccountAdmin",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/accounts/1/outcomes",
    "referrer": "https://oxana.instructure.com/accounts/1/outcomes",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-04T14:46:31.249Z"
  },
  "body": {
    "asset_name": "Canvas County School District",
    "asset_type": "account",
    "asset_id": "21070000000000001",
    "asset_subtype": "outcomes",
    "category": "outcomes",
    "role": "AccountUser",
    "level": null
  }
}
```


**Description:** type=course, subtype=grades

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
    "time_zone": "America/Denver",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/grades",
    "referrer": "https://oxana.instructure.com/courses/144",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.918Z"
  },
  "body": {
    "asset_name": "Complex Analysis",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "grades",
    "category": "grades",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=conferences

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
    "time_zone": "America/Denver",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/conferences",
    "referrer": "https://oxana.instructure.com/courses/144/grades",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:27.252Z"
  },
  "body": {
    "asset_name": "Mathematics for Engineers 1",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "conferences",
    "category": "conferences",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=syllabus

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
    "time_zone": "America/Los_Angeles",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/assignments/syllabus",
    "referrer": "https://oxana.instructure.com/courses/101/pages/the-bbc-reports-on-shakespeare?module_item_id=457878",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.844Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "syllabus",
    "category": "syllabus",
    "role": null,
    "level": null
  }
}
```


**Description:** type=course, subtype=pages

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
    "time_zone": "America/Denver",
    "developer_key_id": "170000000056",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/144/pages?sort=updated_at&order=desc",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:08.823Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "pages",
    "category": "pages",
    "role": null,
    "level": null
  }
}
```


**Description:** type=quizzes:quiz

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
    "time_zone": "America/Denver",
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/565/quizzes/144",
    "referrer": "https://oxana.instructure.com/courses/565/quizzes",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-08T19:56:55.781Z"
  },
  "body": {
    "asset_name": "A very special quiz",
    "asset_type": "quizzes:quiz",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "quizzes",
    "role": null,
    "level": null
  }
}
```


**Description:** type=context_external_tool (this type is used to identify all LTI versions except LTI 2.0 launches)

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
    "context_type": "Course",
    "context_id": "21070000000020572",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "TeacherEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/20572/modules/items/44",
    "referrer": "https://oxana.instructure.com/courses/20572",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:08.825Z"
  },
  "body": {
    "asset_name": "External tool modules",
    "asset_type": "context_external_tool",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "external_tools",
    "role": "TeacherEnrollment",
    "level": null,
    "url": "https://externaltool.example.com/lti/",
    "domain": "externaltool.example.com"
  }
}
```


**Description:** type=course, subtype=modules

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
    "time_zone": null,
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/modules",
    "referrer": "https://oxana.instructure.com/courses/144/discussion_topics/89887?module_item_id=219850",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.796Z"
  },
  "body": {
    "asset_name": "Complex Analysis",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "modules",
    "category": "modules",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=lti/tool_proxy (this type is used to identify LTI 2.0 launches)

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
    "time_zone": "America/New_York",
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000001",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/565/assignments/5606488/lti/resource/29600186-1937-4bb2-a68-54fe40eff21?display=borderless",
    "referrer": "https://oxana.instructure.com/courses/565/grades",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:15.799Z"
  },
  "body": {
    "asset_name": "Some LTI Tool",
    "asset_type": "lti/tool_proxy",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "external_tools",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=roster

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
    "developer_key_id": "170000000056",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/144/users?per_page=100&include[]=email",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:08.177Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "roster",
    "category": "roster",
    "role": null,
    "level": null
  }
}
```


**Description:** type=course, subtype=calendar_feed

### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/feeds/calendars/user_abcdeadsadsX3jd93E2134431dasf3214123rf321231.ics",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.874Z"
  },
  "body": {
    "asset_name": "6th Grade History",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "calendar_feed",
    "category": "calendar",
    "role": null,
    "level": null
  }
}
```


**Description:** type=assignment

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
    "time_zone": "America/Denver",
    "developer_key_id": "170000000056",
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/565/assignments/31468",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.700Z"
  },
  "body": {
    "asset_name": "Week 5 Math Homework",
    "asset_type": "assignment",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "assignments",
    "role": null,
    "level": null
  }
}
```


**Description:** type=course, subtype=home

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
    "time_zone": "America/New_York",
    "developer_key_id": "170000000056",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/144",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.697Z"
  },
  "body": {
    "asset_name": "Complex Analysis",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "home",
    "category": "home",
    "role": null,
    "level": null
  }
}
```


**Description:** type=group, subtype=calendar_feed

### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/feeds/calendars/user_AbcDeFGhIJkL123412312312312312.ics",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.987Z"
  },
  "body": {
    "asset_name": "Session 1 (Apr 1, 2019)",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "calendar_feed",
    "category": "calendar",
    "role": null,
    "level": null
  }
}
```


**Description:** type=group, subtype=files

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
    "time_zone": "America/Denver",
    "developer_key_id": "170000000056",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/groups/144/files?sort=updated_at&order=desc",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:58.002Z"
  },
  "body": {
    "asset_name": "MATH 101 Group 1",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "files",
    "category": "files",
    "role": null,
    "level": null
  }
}
```


**Description:** type=group, subtype=pages

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
    "time_zone": "America/Los_Angeles",
    "developer_key_id": "170000000056",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/groups/144/pages?sort=title",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:34:51.407Z"
  },
  "body": {
    "asset_name": "MATH 101 Group 1",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "pages",
    "category": "pages",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=calendar_event

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
    "context_type": "Group",
    "context_id": "21070000000004820",
    "context_sis_source_id": null,
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/4820/calendar_events/144?return_to=https%3A%2F%2Futpl.instructure.com%2Fcalendar%4view_name%3Dmonth%10view_start%3D348-0-10",
    "referrer": "https://oxana.instructure.com/calendar",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:11.076Z"
  },
  "body": {
    "asset_name": "Class end of year party",
    "asset_type": "calendar_event",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "calendar",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=course, subtype=outcomes

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
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "TeacherEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/outcomes",
    "referrer": "https://oxana.instructure.com/courses/144/modules",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-03T19:01:11.198Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "outcomes",
    "category": "outcomes",
    "role": "TeacherEnrollment",
    "level": null
  }
}
```


**Description:** type=group, subtype=announcements

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
    "context_type": "Group",
    "context_id": "21070000000006296",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/6296/announcements",
    "referrer": "https://oxana.instructure.com/groups/6296/discussion_topics/724641",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T02:35:16.059Z"
  },
  "body": {
    "asset_name": "Group 2",
    "asset_type": "group",
    "asset_id": "21070000000006296",
    "asset_subtype": "announcements",
    "category": "announcements",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=course, subtype=speed_grader

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
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "TeacherEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/gradebook/speed_grader?assignment_id=62969&student_id=1830",
    "referrer": "https://oxana.instructure.com/",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.276Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "speed_grader",
    "category": "grades",
    "role": "TeacherEnrollment",
    "level": null
  }
}
```


**Description:** type=group, subtype=topics

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
    "time_zone": "America/New_York",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/144/discussion_topics",
    "referrer": "https://oxana.instructure.com/groups/144/discussion_topics/1434696?module_item_id=5629142",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:16.679Z"
  },
  "body": {
    "asset_name": "MATH 101 Group 1",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "topics",
    "category": "topics",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=course, subtype=announcements

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
    "time_zone": "America/Los_Angeles",
    "context_type": "Course",
    "context_id": "21070000000000123",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/123/announcements",
    "referrer": "https://oxana.instructure.com/",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.956Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "2107000000000123",
    "asset_subtype": "announcements",
    "category": "announcements",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=topics

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
    "time_zone": null,
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/144/discussion_topics",
    "referrer": "https://oxana.instructure.com/courses/144/announcements",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.373Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "topics",
    "category": "topics",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=web_conference

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
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "2107000000000007",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/565/conferences/144/join",
    "referrer": "https://oxana.instructure.com/courses/565/conferences",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-02T01:27:38.610Z"
  },
  "body": {
    "asset_name": "Basic Math Conference",
    "asset_type": "web_conference",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "conferences",
    "role": "StudentEnrollment",
    "level": "participate"
  }
}
```


**Description:** type=content_tag

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
    "context_type": "Course",
    "context_id": "21070000000014855",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/14855/modules/items/144",
    "referrer": "https://oxana.instructure.com/courses/14855/modules/items/143",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.871Z"
  },
  "body": {
    "asset_name": "Article: How to learn a foreign language",
    "asset_type": "content_tag",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "external_urls",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=learning_outcome

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
    "time_zone": "America/Denver",
    "context_type": "Account",
    "context_id": "21070000000000001",
    "context_sis_source_id": null,
    "context_account_id": "21070000000000001",
    "context_role": "AccountAdmin",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/accounts/1/outcomes/4764",
    "referrer": "https://oxana.instructure.com/accounts/1/outcomes",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-08T19:53:07.183Z"
  },
  "body": {
    "asset_name": "Outcome Test 1",
    "asset_type": "learning_outcome",
    "asset_id": "21070000000004764",
    "asset_subtype": null,
    "category": "outcomes",
    "role": "AccountUser",
    "level": null
  }
}
```


**Description:** type=wiki_page

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
    "time_zone": "America/Denver",
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/565/pages/week-2-introduction?module_item_id=4635203",
    "referrer": "https://oxana.instructure.com/courses/565/discussion_topics/1072925?module_item_id=4635201",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.878Z"
  },
  "body": {
    "asset_name": "Week 1: Intro",
    "asset_type": "wiki_page",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "wiki",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=discussion_topic

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
    "time_zone": "America/New_York",
    "context_type": "Group",
    "context_id": "21070000000001234",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/groups/1234/discussion_topics/144/view?include_new_entries=1&include_enrollment_state=1&include_context_card_info=1",
    "referrer": "https://oxana.instructure.com/groups/1234/discussion_topics/144?module_item_id=457151",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.666Z"
  },
  "body": {
    "asset_name": "Week 1 Journal",
    "asset_type": "discussion_topic",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "topics",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=attachment

### Payload Example:

```json
{
  "metadata": {
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
    "context_type": "Course",
    "context_id": "21070000000000565",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000001963",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/412~17342/files/474~958001/course%20files/CourseResources/Week1/My%20Attachments.htm?download=1",
    "referrer": "https://oxana.instructure.com/courses/1963/files/12345?module_item_id=123&fd_cookie_set=1",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:06.655Z"
  },
  "body": {
    "asset_name": "My Attachment.html",
    "asset_type": "attachment",
    "asset_id": "21070000000000144",
    "asset_subtype": null,
    "category": "files",
    "role": null,
    "level": null,
    "filename": "My+Attachment.html",
    "display_name": "My+Attachment.html"
  }
}
```


**Description:** type=group, subtype=roster

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
    "time_zone": "America/New_York",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/144/users",
    "referrer": "https://oxana.instructure.com/groups/144",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:10:04.255Z"
  },
  "body": {
    "asset_name": "MATH 101 Group 1",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "roster",
    "category": "roster",
    "role": "GroupMembership",
    "level": null
  }
}
```


**Description:** type=course, subtype=collaborations

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
    "time_zone": "America/Los_Angeles",
    "context_type": "Course",
    "context_id": "21070000000012345",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "StudentEnrollment",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/courses/12345/collaborations",
    "referrer": "https://oxana.instructure.com/courses/12345/external_tools/25",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:35:04.235Z"
  },
  "body": {
    "asset_name": "Perspectives on Linguistic Science",
    "asset_type": "course",
    "asset_id": "21070000000012345",
    "asset_subtype": "collaborations",
    "category": "collaborations",
    "role": "StudentEnrollment",
    "level": null
  }
}
```


**Description:** type=course, subtype=quizzes

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
    "time_zone": "America/Los_Angeles",
    "developer_key_id": "170000000056",
    "context_type": "Course",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/api/v1/courses/144/quizzes?page=1&per_page=100",
    "referrer": null,
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T00:09:07.636Z"
  },
  "body": {
    "asset_name": "Introduction to Algebra",
    "asset_type": "course",
    "asset_id": "21070000000000144",
    "asset_subtype": "quizzes",
    "category": "quizzes",
    "role": null,
    "level": null
  }
}
```


**Description:** type=group, subtype=collaborations

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
    "time_zone": "America/New_York",
    "context_type": "Group",
    "context_id": "21070000000000144",
    "context_sis_source_id": "2017.100.101.101-1",
    "context_account_id": "21070000000000079",
    "context_role": "GroupMembership",
    "request_id": "1dd9dc6f-2fb0-4c19-a6c5-7ee1bf3ed295",
    "session_id": "ef686f8ed684abf78cbfa1f6a58112b5",
    "hostname": "oxana.instructure.com",
    "http_method": "GET",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36",
    "client_ip": "93.184.216.34",
    "url": "https://oxana.instructure.com/groups/144/collaborations",
    "referrer": "https://oxana.instructure.com/groups/1444/users",
    "producer": "canvas",
    "event_name": "asset_accessed",
    "event_time": "2019-11-01T03:08:58.218Z"
  },
  "body": {
    "asset_name": "Example Name",
    "asset_type": "group",
    "asset_id": "21070000000000144",
    "asset_subtype": "collaborations",
    "category": "collaborations",
    "role": "GroupMembership",
    "level": null
  }
}
```




### Event Body Schema

| Field | Description |
|-|-|
| **asset_id** | The Canvas id of the asset. |
| **asset_name** | The title of a course, page, module, assignment, LTI, attachment etc. |
| **asset_subtype** | The sub type of asset being accessed. |
| **asset_type** | The type of asset being accessed. |
| **category** | A categorized list of values based on the asset or asset subtype accessed. (announcements, assignments, calendar, collaborations, conferences, external_tools, external_urls, files, grades, home, modules, outcomes, pages, quizzes, roster, syllabus, topics, wiki) |
| **display_name** | The display name of the attachment, possibly truncated. |
| **domain** | The domain of the LTI tool, when subtype is context_external_tool. |
| **filename** | The file name of the attachment, possibly truncated. |
| **level** | Usually null, can be used to indicate a deeper level of access. Can be "submit" for assignments. Can be "participate" for collaboration, calendar, discussion_topic (user posts to topic), quizzes:quiz, web_conference, or wiki_page (page created or edited). |
| **role** | The role of the user accessing the asset. (AccountUser, DesignerEnrollment, GroupMembership, ObserverEnrollment, StudentEnrollment, StudentViewEnrollment, TaEnrollment, TeacherEnrollment, User) |
| **url** | The URL of the LTI tool, when subtype is context_external_tool. |



