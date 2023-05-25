Navigation Events
==============

<h2 id="asset_accessed">asset_accessed</h2>

**Definition:** `asset_accessed` events are triggered for viewing various objects in Canvas. Viewing a quiz, a wiki page, the list of quizzes, etc, all generate `asset_access` events.

**Trigger:** Triggered when a variety of assets are viewed.


### Event Body Schema

| Field | Description |
|-|-|
| **data[0].object.extensions["com.instructure.canvas"].asset_name** | indicates Canvas object name being accessed in the NavigationEvent. For an example it could be a title of a course, page, module, assignment, LTI, attachment etc |
| **data[0].object.extensions["com.instructure.canvas"].asset_subtype** | indicates Canvas object sub-type being accessed in the NavigationEvent |
| **data[0].object.extensions["com.instructure.canvas"].asset_type** | indicates Canvas object type being accessed in the NavigationEvent |
| **data[0].object.extensions["com.instructure.canvas"].context_account_id** | The account id of the current context. This is the actual account the context is attached to could be account, sub-account, course |
| **data[0].object.extensions["com.instructure.canvas"].entity_id** | Canvas global ID of the object affected by the event |
| **data[0].object.extensions["com.instructure.canvas"].http_method** | HTTP method/verb (GET, PUT, POST etc.) that the request was sent with. Only present in user-generated events |
| **data[0].object.type** | Entity |




**Description:** type=account, subtype=outcomes
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:46.287Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:02729bac-c975-4e22-b312-6a7f1d8be173",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:account:21070000000000001",
        "type": "Entity",
        "name": "outcomes",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Canvas County School District",
            "asset_type": "account",
            "asset_subtype": "outcomes",
            "entity_id": "21070000000000001",
            "context_account_id": "210700000000000001",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-04T14:46:31.249Z",
      "referrer": "https://oxana.instructure.com/accounts/1/outcomes",
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
          "request_url": "https://oxana.instructure.com/accounts/1/outcomes",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=assignment
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:46.608Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:d71bd983-d03a-4ef8-8701-71cfa7889eaf",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:assignment:21070000000000144",
        "type": "AssignableDigitalResource",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Week 5 Math Homework",
            "asset_type": "assignment",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.700Z",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000565:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000565",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/565/assignments/31468",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=attachment
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:46.918Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:abd40e68-7792-46c3-b0bf-e4980d9c5236",
      "type": "NavigationEvent",
      "actor": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:attachment:21070000000000144",
        "type": "Entity",
        "name": "attachment",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "My Attachment.html",
            "asset_type": "attachment",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000001963",
            "http_method": "GET",
            "filename": "My+Attachment.html",
            "display_name": "My+Attachment.html"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.655Z",
      "referrer": "https://oxana.instructure.com/courses/1963/files/12345?module_item_id=123&fd_cookie_set=1",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
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
          "request_url": "https://oxana.instructure.com/courses/412~17342/files/474~958001/course%20files/CourseResources/Week1/My%20Attachments.htm?download=1",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=calendar_event
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:47.228Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:2a81b5ce-8cd8-4e2f-96c6-62190fadf31d",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:calendar_event:21070000000000144",
        "type": "Entity",
        "name": "calendar_event",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Class end of year party",
            "asset_type": "calendar_event",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:11.076Z",
      "referrer": "https://oxana.instructure.com/calendar",
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
          "request_url": "https://oxana.instructure.com/groups/4820/calendar_events/144?return_to=https%3A%2F%2Futpl.instructure.com%2Fcalendar%4view_name%3Dmonth%10view_start%3D348-0-10",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=collaboration
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:47.556Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:6713c466-1ce1-4ffd-b37f-4940e9d1cb17",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:collaboration:21070000000000144",
        "type": "Entity",
        "name": "collaboration",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Example Collaboration",
            "asset_type": "collaboration",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:35:15.069Z",
      "referrer": "https://oxana.instructure.com/courses/8346/collaborations",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000008346",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000008346"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000008346:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000008346",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/8346/collaborations/144",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=content_tag
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:47.892Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:42fafa38-6b5a-4187-9f9c-007f5262d290",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:content_tag:21070000000000144",
        "type": "Entity",
        "name": "content_tag",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Article: How to learn a foreign language",
            "asset_type": "content_tag",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.871Z",
      "referrer": "https://oxana.instructure.com/courses/14855/modules/items/143",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000014855",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000014855"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000014855:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000014855",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/14855/modules/items/144",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=context_external_tool (this type is used to identify all LTI versions but LTI 2.0 launches)
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:48.209Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:d745a8a5-dd2b-473e-bb96-8c8f6773289a",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:context_external_tool:21070000000000144",
        "type": "Entity",
        "name": "context_external_tool",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "External tool modules",
            "asset_type": "context_external_tool",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "url": "https://externaltool.example.com/lti/",
            "domain": "externaltool.example.com"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:08.825Z",
      "referrer": "https://oxana.instructure.com/courses/20572",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000020572",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000020572"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000020572:Instructor:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000020572",
          "type": "CourseOffering"
        },
        "roles": [
          "Instructor"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/20572/modules/items/44",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=announcements
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:48.547Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:21937a1f-3d5f-40cb-b9d4-2863df75a4fa",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:2107000000000123",
        "type": "Entity",
        "name": "announcements",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "announcements",
            "entity_id": "2107000000000123",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.956Z",
      "referrer": "https://oxana.instructure.com/",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000123",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000123"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000123:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000123",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/123/announcements",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=assignments
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:48.880Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:55154e3e-fcff-4378-83f9-d1068d792261",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "assignments",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "assignments",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.753Z",
      "referrer": "https://oxana.instructure.com/courses/144/assignments/64541?module_item_id=313255",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/assignments",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=calendar_feed
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:49.188Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:49394652-705e-4b29-8412-f2c430f9b824",
      "type": "NavigationEvent",
      "actor": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "calendar_feed",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "6th Grade History",
            "asset_type": "course",
            "asset_subtype": "calendar_feed",
            "entity_id": "21070000000000144",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.874Z",
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
          "request_url": "https://oxana.instructure.com/feeds/calendars/user_abcdeadsadsX3jd93E2134431dasf3214123rf321231.ics",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=collaborations
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:49.498Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:e26e5294-0d45-43d4-8d04-e746c61cffd7",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000012345",
        "type": "Entity",
        "name": "collaborations",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Perspectives on Linguistic Science",
            "asset_type": "course",
            "asset_subtype": "collaborations",
            "entity_id": "21070000000012345",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:35:04.235Z",
      "referrer": "https://oxana.instructure.com/courses/12345/external_tools/25",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000012345",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000012345"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000012345:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000012345",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/12345/collaborations",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=conferences
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:49.832Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:39b95352-8583-4e4a-a6b5-b6f6bc9b1f50",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "conferences",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Mathematics for Engineers 1",
            "asset_type": "course",
            "asset_subtype": "conferences",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:27.252Z",
      "referrer": "https://oxana.instructure.com/courses/144/grades",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/conferences",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=files
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:50.156Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:7398e642-b578-4377-8af4-ed7c00378557",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "files",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "files",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.907Z",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/144/files?sort=updated_at&order=desc",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=grades
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:50.480Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:b53bf87a-497c-4122-b0e3-c642580a1623",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "grades",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Complex Analysis",
            "asset_type": "course",
            "asset_subtype": "grades",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.918Z",
      "referrer": "https://oxana.instructure.com/courses/144",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/grades",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=home
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:50.820Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:5d11e896-1d50-4a19-ada1-2c52fbbcda4d",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "home",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Complex Analysis",
            "asset_type": "course",
            "asset_subtype": "home",
            "entity_id": "21070000000000144",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.697Z",
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/144",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=modules
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:51.128Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:46a5d8a0-9a09-459c-8ab3-e2c9a86c7ca9",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "modules",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Complex Analysis",
            "asset_type": "course",
            "asset_subtype": "modules",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.796Z",
      "referrer": "https://oxana.instructure.com/courses/144/discussion_topics/89887?module_item_id=219850",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/modules",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=outcomes
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:51.444Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:980f8c56-35bf-4ece-b77b-3222ddff2c3c",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "outcomes",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "outcomes",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-03T19:01:11.198Z",
      "referrer": "https://oxana.instructure.com/courses/144/modules",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Instructor:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Instructor"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/outcomes",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=pages
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:51.787Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:464fd337-2c75-4afd-81fd-c6fee60e6af6",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "pages",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "pages",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:08.823Z",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/144/pages?sort=updated_at&order=desc",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=quizzes
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:52.084Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:c8e7c7a1-2335-4fcc-b8f7-0920752ea239",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "quizzes",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "quizzes",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.636Z",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/144/quizzes?page=1&per_page=100",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=roster
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:52.383Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:d8c06f6e-592a-4a27-99ee-4d0b61cafdd5",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "roster",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "roster",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:08.177Z",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/api/v1/courses/144/users?per_page=100&include[]=email",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=speed_grader
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:52.696Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:f0e75bbd-d4de-4647-bfd8-260f98b11632",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "speed_grader",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "speed_grader",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.276Z",
      "referrer": "https://oxana.instructure.com/",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Instructor:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Instructor"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/gradebook/speed_grader?assignment_id=62969&student_id=1830",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=syllabus
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:52.999Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:f2fa19f4-3240-4549-b067-5063c39d286a",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "syllabus",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "syllabus",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.844Z",
      "referrer": "https://oxana.instructure.com/courses/101/pages/the-bbc-reports-on-shakespeare?module_item_id=457878",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/courses/144/assignments/syllabus",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=course, subtype=topics
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:53.302Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:c1c584f2-7194-4b3b-a8bf-5e1115b475a7",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "Entity",
        "name": "topics",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Introduction to Algebra",
            "asset_type": "course",
            "asset_subtype": "topics",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.373Z",
      "referrer": "https://oxana.instructure.com/courses/144/announcements",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000144",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000144"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000144:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000144",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/144/discussion_topics",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=discussion_topic
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:53.617Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:8467aed3-6bb6-42d4-8392-f354829cb29c",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:discussion:21070000000000144",
        "type": "Thread",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Week 1 Journal",
            "asset_type": "discussion_topic",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.666Z",
      "referrer": "https://oxana.instructure.com/groups/1234/discussion_topics/144?module_item_id=457151",
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
          "request_url": "https://oxana.instructure.com/api/v1/groups/1234/discussion_topics/144/view?include_new_entries=1&include_enrollment_state=1&include_context_card_info=1",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=enrollment
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:53.929Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:2c7cfa5c-7ef3-45a6-a4a5-7969e95afe82",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:enrollment:21070000000000144",
        "type": "Entity",
        "name": "enrollment",
        "extensions": {
          "com.instructure.canvas": {
            "asset_type": "enrollment",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:30.201Z",
      "referrer": "https://oxana.instructure.com/courses/1234/users",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000001234",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000001234"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000001234:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000001234",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/1234/users/14320",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=announcements
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:54.249Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:45280282-9b8d-46d2-8102-7ce985761b95",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000006296",
        "type": "Entity",
        "name": "announcements",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Group 2",
            "asset_type": "group",
            "asset_subtype": "announcements",
            "entity_id": "21070000000006296",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T02:35:16.059Z",
      "referrer": "https://oxana.instructure.com/groups/6296/discussion_topics/724641",
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
          "request_url": "https://oxana.instructure.com/groups/6296/announcements",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=calendar_feed
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:54.569Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:087cd124-4093-4dac-b47b-2a16b6375c04",
      "type": "NavigationEvent",
      "actor": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "calendar_feed",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Session 1 (Apr 1, 2019)",
            "asset_type": "group",
            "asset_subtype": "calendar_feed",
            "entity_id": "21070000000000144",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.987Z",
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
          "request_url": "https://oxana.instructure.com/feeds/calendars/user_AbcDeFGhIJkL123412312312312312.ics",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=collaborations
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:54.875Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:f8908571-6c91-4775-bc9e-00ffc01c974c",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "collaborations",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Example Name",
            "asset_type": "group",
            "asset_subtype": "collaborations",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T03:08:58.218Z",
      "referrer": "https://oxana.instructure.com/groups/1444/users",
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
          "request_url": "https://oxana.instructure.com/groups/144/collaborations",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=conferences
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:55.273Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:8cb24552-4c6a-4c25-91ed-6ccb1cebe65f",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "conferences",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "MATH 101 Group 1",
            "asset_type": "group",
            "asset_subtype": "conferences",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:07.150Z",
      "referrer": "https://oxana.instructure.com/groups/144/conferences",
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
          "request_url": "https://oxana.instructure.com/groups/144/conferences",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=files
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:55.634Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:6fcb10d6-3ee5-44cf-a584-841bfbf28d5a",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "files",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "MATH 101 Group 1",
            "asset_type": "group",
            "asset_subtype": "files",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:58.002Z",
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
          "request_url": "https://oxana.instructure.com/api/v1/groups/144/files?sort=updated_at&order=desc",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=pages
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:55.930Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:98b1fb69-f716-403f-a4e4-94781a707d64",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "pages",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "MATH 101 Group 1",
            "asset_type": "group",
            "asset_subtype": "pages",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:34:51.407Z",
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
          "request_url": "https://oxana.instructure.com/api/v1/groups/144/pages?sort=title",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=roster
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:56.252Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:bd56ebcb-fcba-4d1e-9c68-cbfbaeb8eb2d",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "roster",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "MATH 101 Group 1",
            "asset_type": "group",
            "asset_subtype": "roster",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:10:04.255Z",
      "referrer": "https://oxana.instructure.com/groups/144",
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
          "request_url": "https://oxana.instructure.com/groups/144/users",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=group, subtype=topics
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:56.594Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:5df496f2-ce03-425f-a95f-27498872aafa",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:group:21070000000000144",
        "type": "Entity",
        "name": "topics",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "MATH 101 Group 1",
            "asset_type": "group",
            "asset_subtype": "topics",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:16.679Z",
      "referrer": "https://oxana.instructure.com/groups/144/discussion_topics/1434696?module_item_id=5629142",
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
          "request_url": "https://oxana.instructure.com/groups/144/discussion_topics",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=learning_outcome
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:56.909Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:f2318102-28da-4f03-905c-420b2f57a873",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:learning_outcome:21070000000004764",
        "type": "Entity",
        "name": "learning_outcome",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Outcome Test 1",
            "asset_type": "learning_outcome",
            "entity_id": "21070000000004764",
            "context_account_id": "21070000000000001",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-08T19:53:07.183Z",
      "referrer": "https://oxana.instructure.com/accounts/1/outcomes",
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
          "request_url": "https://oxana.instructure.com/accounts/1/outcomes/4764",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=lti/tool_proxy (this type is used to identify LTI 2.0 launches)
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:57.232Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:c9d89a6e-e7e0-4c30-b2d7-8f78fc61c3f0",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:lti/tool_proxy:21070000000000144",
        "type": "Entity",
        "name": "lti/tool_proxy",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Some LTI Tool",
            "asset_type": "lti/tool_proxy",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000001",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:15.799Z",
      "referrer": "https://oxana.instructure.com/courses/565/grades",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000565:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000565",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/565/assignments/5606488/lti/resource/29600186-1937-4bb2-a68-54fe40eff21?display=borderless",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=quizzes:quiz
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:57.605Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:8bfe9cd1-8960-4fb1-b5df-7274b593f178",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:quizzes:quiz:21070000000000144",
        "type": "Entity",
        "name": "quizzes:quiz",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "A very special quiz",
            "asset_type": "quizzes:quiz",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-08T19:56:55.781Z",
      "referrer": "https://oxana.instructure.com/courses/565/quizzes",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000565:user:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000565",
          "type": "CourseOffering"
        }
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
          "request_url": "https://oxana.instructure.com/courses/565/quizzes/144",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=user, subtype=calendar_feed
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:58.029Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:0c4559c2-2a6d-4553-9b29-989c2420ac86",
      "type": "NavigationEvent",
      "actor": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:user:21070000000000144",
        "type": "Entity",
        "name": "calendar_feed",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Sally Student",
            "asset_type": "user",
            "asset_subtype": "calendar_feed",
            "entity_id": "21070000000000144",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.718Z",
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
          "request_url": "https://oxana.instructure.com/feeds/calendars/user_ABdASKrt432fdKSDALhGDSL83423kFDRK32.ics",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=user, subtype=files
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:58.332Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:a829b641-07a1-4a76-a312-55ad35f28a9f",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:user:21070000000000144",
        "type": "Entity",
        "name": "files",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Sally Student",
            "asset_type": "user",
            "asset_subtype": "files",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET",
            "developer_key_id": "170000000056"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:23.214Z",
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
          "request_url": "https://oxana.instructure.com/api/v1/users/144/files?sort=updated_at&order=desc",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=web_conference
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:58.687Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:6bec0191-8ca5-4110-bf3a-12081068e182",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:web_conference:21070000000000144",
        "type": "Entity",
        "name": "web_conference",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Basic Math Conference",
            "asset_type": "web_conference",
            "entity_id": "21070000000000144",
            "context_account_id": "2107000000000007",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-02T01:27:38.610Z",
      "referrer": "https://oxana.instructure.com/courses/565/conferences",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000565:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000565",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/565/conferences/144/join",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```


**Description:** type=wiki_page
### Payload Example:

```json
{
  "sensor": "http://oxana.instructure.com/",
  "sendTime": "2019-11-16T02:08:59.163Z",
  "dataVersion": "http://purl.imsglobal.org/ctx/caliper/v1p1",
  "data": [
    {
      "@context": "http://purl.imsglobal.org/ctx/caliper/v1p1",
      "id": "urn:uuid:cf6e0f3b-3511-4254-86c5-6936ff33f267",
      "type": "NavigationEvent",
      "actor": {
        "id": "urn:instructure:canvas:user:21070000000000001",
        "type": "Person",
        "extensions": {
          "com.instructure.canvas": {
            "user_login": "oxana@example.com",
            "user_sis_id": "456-T45",
            "root_account_id": "21070000000000001",
            "root_account_lti_guid": "7db438071375c02373713c12c73869ff2f470b68.oxana.instructure.com",
            "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs",
            "entity_id": "21070000000000001"
          }
        }
      },
      "action": "NavigatedTo",
      "object": {
        "id": "urn:instructure:canvas:wikiPage:21070000000000144",
        "type": "Page",
        "extensions": {
          "com.instructure.canvas": {
            "asset_name": "Week 1: Intro",
            "asset_type": "wiki_page",
            "entity_id": "21070000000000144",
            "context_account_id": "21070000000000079",
            "http_method": "GET"
          }
        }
      },
      "eventTime": "2019-11-01T00:09:06.878Z",
      "referrer": "https://oxana.instructure.com/courses/565/discussion_topics/1072925?module_item_id=4635201",
      "edApp": {
        "id": "http://oxana.instructure.com/",
        "type": "SoftwareApplication"
      },
      "group": {
        "id": "urn:instructure:canvas:course:21070000000000565",
        "type": "CourseOffering",
        "extensions": {
          "com.instructure.canvas": {
            "context_type": "Course",
            "entity_id": "21070000000000565"
          }
        }
      },
      "membership": {
        "id": "urn:instructure:canvas:course:21070000000000565:Learner:21070000000000001",
        "type": "Membership",
        "member": {
          "id": "urn:instructure:canvas:user:21070000000000001",
          "type": "Person"
        },
        "organization": {
          "id": "urn:instructure:canvas:course:21070000000000565",
          "type": "CourseOffering"
        },
        "roles": [
          "Learner"
        ]
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
          "request_url": "https://oxana.instructure.com/courses/565/pages/week-2-introduction?module_item_id=4635203",
          "version": "1.0.0"
        }
      }
    }
  ]
}
```




