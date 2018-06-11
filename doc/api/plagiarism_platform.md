 Plagiarism Detection Platform
==============
The plagiarism detection platform provides a standard way for LTI2 tool providers (TPs) to seamlessly integrate plagiarism detection tools with Canvas. Part of this platform is the introduction of Originality Reports which can be created, edited, and retrieved by TPs. TPs are also given a means of subscribing to webhooks to notify them of changes to assignments and submissions.

This document provides details to guide TPs toward leveraging the plagiarism detection platform. The document is divided into three sections that cover the plagiarism detection platform:

#### Section 1 - Tool Registration
TPs leveraging the new plagiarism detection platform must go through the standard LTI2 registration flow, with some additional steps along the way.

#### Section 2 - Tool Launch & Webhooks
Once registered, tools will be provided with an LTI tool placement in the Canvas assignment create/edit UI to launch a configuration page. Canvas will automatically create a subscription on behalf of the tool for a submissions webhook, allowing the TP to be notified when a submission has been made.

#### Section 3 - Originality Reports
The webhook sent to the TP contains the data needed for the tool to retrieve the submission from Canvas. The TP can then process the submission, determine its "originality score", and create an Originality Report. This data is then sent back to Canvas and associated with the submission via the Canvas Originality Report API.

#### Section 4 - Other Features
Descriptions of optional features tool providers may use.

For additional help please see the following reference tools:
* [Plagiarism Detection Reference Tool](https://github.com/instructure/lti_originality_report_example)
* [LTI 2.1 Reference Tool](https://github.com/instructure/lti2_reference_tool_provider)

### 1. Tool Registration
Canvas’ plagiarism platform requires the TP to support LTI2 and obtain a Canvas developer key. During the standard LTI2 registration flow, the TP should take the following steps:
1. Include a JWT access token in the Authorization header of the request to get the Tool Consumer Profile (see section 1.1).
2. Add the `Canvas.placements.similarityDetection` capability to the Tool Profile’s Resource Handler enabled capabilities (See section 1.2).
3. Add the `vnd.Canvas.OriginalityReport` service to the Tool Proxy’s Security Contract (see section 1.3).
4. Add the `Security.splitSecret` capability to the Tool Proxy’s enabled capabilities (see section 1.4).
5. Include a JWT access token in the Authorization header of the Tool Proxy create POST request (see section 1.5).

#### 1.1 Include JWT Access Token in Tool Consumer Profile Request
Requesting a TCP is the second step of registering an LTI2 Tool (See [LTI2 implementation guide](https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-100))

Canvas will include a restricted set of services/capabilities in the TCP if the request to retrieve the TCP contains a JWT access token in the Authorization header.

Canvas requires that the TP use the following restricted capabilities/services:
* `vnd.Canvas.OriginalityReport` service
* `vnd.Canvas.submission` service
* `Canvas.placements.similarityDetection` capability

To retrieve a TCP with these restricted services/capabilities first retrieve a JWT access token as described in <a href="jwt_access_tokens.html">JWT access tokens</a> section 1.0. These tokens are associated with a single developer key which, in turn, are associated with a single custom TCP. Include this token in the authorization header of the request to retrieve the TCP:

```
Authorization Bearer <JWT access token>
```

#### 1.2 Adding the Similarity Detection Placement
Tool Providers who wish to use the plagiarism detection platform must add the similarity detection placement capability to the Tool Profile’s Resource Handler:
```json
{
…
"resource_handler":[
      {
         …
         "message":[
            {
               "message_type":"basic-lti-launch-request",
               "path":"/messages/assignment-configuration",
               "enabled_capability": ["Canvas.placements.similarityDetection"]
            }
         ]
      }
  ]
…
}
```
This placement is listed in the TCP request as described in section 1.1:
```json
{
…
"capability_offered":[
      "basic-lti-launch-request",
      "User.id",
	…
      "Canvas.placements.similarityDetection"
   ],
…
}
```
Note that the `Canvas.placements.similarityDetection` capability should be enabled in both the resource handler and in the `enabled_capability` array at the root of the tool proxy.

#### 1.3 Adding the Services to the Security Contract
The following example security contract shows the services required to use the plagiarism platform:

```json
{
  …
  "security_contract": {
    …
    "tool_service": [{
      "@type": "RestService",
      "service": "http://canvas.docker/api/lti/courses/3/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.OriginalityReport",
      "action": ["POST", "PUT", "GET"]
    },
    {
      "@type": "RestService",
      "service": "http://canvas.docker/api/lti/courses/3/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.submission",
      "action": ["GET"]
    },
    {
      "service": "http://canvas.docker/api/lti/courses/3/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.submission.history",
      "action": ["GET"]
    }]
  …
}
```
For each tool service object, the `service` field must match the `@id` of the `service` given in the TCP (see section 1.1) and the value of `action` must be a subset of the actions provided in the TCP (see section 1.1).

#### 1.4 Adding the Security.splitSecret Capability
The `Security.splitSecret` capability must be used by the TP when using the similarity detection platform in Canvas. Specify this capability in the Tool Proxy:
```json
{
  …
  "lti_version": "LTI-2p0",
  "tool_profile" : {…}.
  "enabled_capability": ["Canvas.placements.similarityDetection", "Security.splitSecret"]
  …
}
```
The following excerpt regarding the split secret capability is from the LTI 2.1 Implementation Guide (in draft) and may change in the future:
> The shared secret is used to digitally sign launch requests in accordance with the OAuth [sic]. If the Tool Consumer offers a capability of `Security.splitSecret` and this is enabled in the Tool Proxy, then the security contract should include an element named `tp_half_shared_secret` with a value of 128 hexadecimal characters (all in lowercase). This represents the second half of the string to use as the shared secret; the first half will be generated by the Tool Consumer and passed to the Tool Provider in its acceptance response (see section 10.1) as a parameter named `tc_half_shared_secret` (along with the Tool Proxy GUID value); this should also be a 128 string of lowercase hexadecimal characters. Each 128-character hexadecimal string should be generated from 64 bytes of random data. If the split secret capability was not offered or enabled, then the security contract should include the full shared secret in an element named `shared_secret`. The Tool Proxy should never contain both the `tp_half_shared_secret` and `shared_secret` elements; just one or the other.

#### 1.5 The Tool Proxy Create Request
The next-to-last step in the standard LTI2 registration flow is creating a Tool Proxy in the Tool Consumer (see [LTI2 implementation guide](https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-101)).

To register a Tool Proxy that uses restricted capabilities/services (like the originality report service) from a custom TCP the Tool Proxy creation `POST` request should include a JWT access token in the `Authorization` header. For information on retrieving a JWT access token for this purpose see <a href="jwt_access_tokens.html">JWT access tokens</a> section 1.0. This may be the same token used to retrieve the tool consumer profile.

Standard LTI2 registration requires requests to be signed with a temporary `reg_key` and `reg_password` (see [LTI@ implementation guide](https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-60)). When using a JWT access token in the authorization header this is not necessary (see <a href="jwt_access_tokens.html">JWT access tokens</a> section 1.0).

### 2. Tool Launch & Webhooks
Tools configured as described in section 1 of this document will be launchable from the assignment create/edit page in Canvas (see section 2.1). Once an assignment is created and associated with a plagiarism tool Canvas will automatically create a subscription to notify the tool when submissions are created by students(see section 2.2).

#### 2.1 The Similarity Detection Placement
Tools configured as described in section 1 of this document will be made available to assignments using “File Upload” submission types. Other submission types are not supported at this time. Once “File Upload” submission type is selected, a “Plagiarism Review” dropdown box becomes available so that the user can associate the assignment to the plagiarism tool. Note that the plagiarism platform feature flag must be enabled in Canvas.

Selecting a tool in the "Plagiarism Review" selector initiates a standard LTI launch to the launch URL provided in the resource handler during the registration phase (see 1.2). This launch is intended to allow configuration of the plagiarism review tool during the assignment creation process.

~~In addition to standard LTI parameters and variables requested by the TP for this launch, Canvas will send a parameter named `ext_lti_assignment_id`.~~ This behavior will soon be deprecated. Instead please add the `com.instructure.Assignment.lti.id` capability to the same message that uses the `Canvas.placements.similarityDetection` capability. This parameter's value uniquely identifies the assignment and may be used by the TP to show the correct configuration options.

#### 2.2 Webhook Background

Webhooks from canvas are your way to know that a change has taken place (e.g. new or updated submission, change to assignment, etc).

Webhooks are available via HTTPS to an endpoint you own and specify, or via an AWS SQS queue that you provision, own, and specify. We recommend SQS for the most robust integration, but do support HTTPS for lower volume applications.

Webhooks that are sent but receive an unsuccessful response will be retried five times, waiting thirty seconds between attempts.

If you choose to use SQS transport, contact us for simple steps on how to grant Canvas write permissions to your queue or queues.

We do not duplicate or batch messages before transmission. Avoid creating multiple identical subscriptions. Webhooks always identify the ID of the subscription that caused them to be sent, allowing you to identify problematic or high volume subscriptions.

We cannot guarantee the transmission order of webhooks. If order is important to your application, you must check the “event_time” attribute in the “metadata” hash to determine the sequence that events occurred in Canvas.

While we strive to maintain very low latency, this is not guaranteed at all times, and applications should support delays of several minutes.

Additional JSON keys may be added in the future. Consumers should be permissive in what they accept in this regard.

#### 2.3 Subscribing to Webhooks
Once an assignment is created that uses a plagiarism detection tool a webhook subscription is automatically created and configured as specified by the `SubmissionEvent` service in the Tool Profile’s `service_offered` section. Below is an example of how to configure this service in the Tool Profile:
```json
{
  …
  "service_offered": [{
    // Must end in "#vnd.Canvas.SubmissionEvent"
    "@id": "my.tool.com/service#vnd.Canvas.SubmissionEvent",
    "endpoint": "http://my.tool.com/subission_endpoint",// Endpoint Canvas will POST events to
    "@type": "RestService",
    "format": ["application/json"],
    "action": ["POST"]
  }],
  …
}
```
This automatic subscription will cause a webhook to be sent to the endpoint specified by the SubmissionEvent whenever a submission is created or updated or when a user clicks the “resubmit to plagiarism detection service” button in the Canvas UI.

#### 2.4 Webhook payload format
HTTPS Webhooks will be transmitted over HTTPS via a POST request with a content type of application/json to the endpoint you specify in your subscriptions.

SQS Webhooks will contain the same JSON body as the body of the SQS Message.

See assignment_updated, submission_created, and submission_updated at https://canvas.instructure.com/doc/api/file.live_events.html for additional field definitions.

A JSON body example is shown below.

```json
{
  "metadata": {
    "root_account_uuid": "LC6nuzxUST0u7aNHzzzyCjEww5wAtjO5GiSlrHMu",
    "root_account_id": "90000000000000001",
    "root_account_lti_guid": "LC6nuzxUST0u7aNHCm0yCjEww5wAtjO5GiSlrHMu:canvas-lms",
    "user_id": "10000000000000001",
    "real_user_id": "10000000000000001",
    "user_login": "student01@test.com",
    "context_type": "Course",
    "context_id": "10000000000000009",
    "context_role": "StudentEnrollment",
    "request_id": "1602a2f9-4c28-44ec-9cb2-372cbac73224",
    "session_id": "337e3af6f38cd4ff31539d1ae677a288",
    "hostname": "sandbox.beta.instructure.com",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:54.0) Gecko/20100101 Firefox/54.0",
    "producer": "canvas",
    "event_name": "submission_updated",
    "event_time": "2017-05-23T09:58:31Z"
  },
  "body": {
    "submission_id": "93360000000000051",
    "assignment_id": "93360000000000063",
    "user_id": "93360000000000007",
    "submitted_at": "2017-05-23T09:58:31Z",
    "graded_at": null,
    "updated_at": "2017-05-23T09:58:31Z",
    "score": null,
    "grade": null,
    "submission_type": "online_upload",
    "body": null,
    "url": null,
    "attempt": 1,
    "lti_assignment_id": "5afe0638-5467-4a6b-b245-c4b2e646c547"
  },
  "subscription": {
    "id": "ce95af25-a1c9-456a-a4b4-bae1233be2d8",
    "owner_id": "ltiToolProxy:e43eed0a-e7e5-48d6-a578-378c575a3ac3"
  }
}
```
### 3. Originality Reports
Once the TP has been notified of a new submission (see section 2.2), it may access the submission through the <a href="plagiarism_detection_submissions.html">Canvas LTI Submissions API</a> for processing. The payload from this request will contain URLs for retrieving the submission’s attachment.

After processing the submission, an Originality Report may be created for the submission.

For more details on creating originality reports see the <a href="originality_reports.html"> Canvas Originality Report API documentation</a>.

Using the Originality Report and Submissions APIs requires a JWT access token be sent in the authorization header. For more information on using JWT tokens in Canvas see <a href="jwt_access_tokens.html">JWT access tokens</a>.

### 4. Other Features and Considerations
The following are optional features the tool provider may wish to implement.

#### Course Copy
The plagiarism platform automatically handles most of the work required for course copy to work with TPs. When a Course that contains assignments associated with a plagiarism detection TP is copied in Canvas the following occurs:
* The copies of assignments in the new course are automatically associated with the correct tool.
* A webhook subscription is automatically created on behalf of the tool for the newly copied assignments.
* Tool Settings associated with the course are copied to the new course (See _Using the LTI Tool Settings Service_ below).

These two actions will only occur if the same TP has been installed in the context the course is being copied to.

Once the course copy has occurred TPs should be aware that they will begin receiving `submission_created` webhooks for assignments for which they have never had an LTI launch occur. This is because it is unlikely that an instructor will edit each assignment in the new course, which is what would allow the `Canvas.placements.similarityDetection` placement LTI launch to occur. To access information about assignments that a TP has never received an LTI launch for use the <a href="plagiarism_detection_platform_assignments.html">Assignment LTI API</a>.

TPs often have a configuration that is set on a per-assignment basis via their UI by the instructor creating the assignment and stored by the TP. There are two ways of handeling these TP configurations during a course copy: using reasonable defaults or using the LTI Tool Settings Service.

##### Option 1: Using Defaults
When receiving a `submission_created` webhook for an assignment that has never had an associated LTI launch, TP configuration items have not been set by the instructor. In these cases, TPs should use good defaults for any custom configuration they typically offer to instructors when configuring assignments. TPs may even wish to provide a resource handler that uses the `Canvas.placements.accountNavigation` placement in order to provide Canvas administrators the ability to set account-level default configurations.

##### Option 2: Using the LTI Tool Settings Service
The LTI Tool Settings service may be used as a key/value store associated with a particular LTI launch. This means that a TP may store their custom per-assignment configuration in a Tool Setting associated with the Canvas assignment. When a course is copied all Tool Settings will be copied to the new course and be associated with the proper assignments in the new context. The following describes how to create a Tool Setting associated with an assignment and leverage it for course copy:

1. Use `LtiLink.custom.url` variable expansion
2. Store assignment-level custom configuration in Tool Settings
3. When receiving a `submission_created` webhook for an unknown assignment, use the LTI assignment API to fetch assignment data
4. When receiving a `submission_created` webhook for an unknown assignment, use the `lti_assignment_id` and the Tool Setting Service to retrieve TP assignment-level configuration


##### 1. Using `LtiLink.custom.url`
The `LtiLink.custom.url` variable expansion should be used in the same message handler that handles `Canvas.placements.similarityDetection` launches:
```json
...
"message":[
    {
       "message_type":"basic-lti-launch-request",
       "path":"/messages/assignment-configuration",
       "enabled_capability": ["Canvas.placements.similarityDetection"],
       "parameter": [
          {
            "name": "tool_setting_endpoint",
            "variable": "LtiLink.custom.url"
          }
       ]
    }
]
...
```

Canvas will then create a Tool Setting for the TP associated with the assignment when the `Canvas.placements.similarityDetection` launch occurs for the first time. This Tool Setting can be used to store TP specific assignment-level configuration that will be copied to the new context during a course copy.

##### 2. Store assignment-level custom configuration in Tool Settings
```
PUT
/api/lti/tool_proxy/<tool proxy guid>/courses/24/resource_link_id/<lti assignment id>/tool_setting
```

Example Request:
```
curl -X PUT \
  http://canvas.docker/api/lti/tool_proxy/0ce4dbf1-b8c5-407d-85ac-618d7615a5a5/courses/24/resource_link_id/b2d9b916-5128-42ad-ad17-b54091a52be2/tool_setting \
  -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJDYW52YXMiLCJzdWIiOiIwY2U0ZGJmMS1iOGM1LTQwN2QtODVhYy02MThkNzYxNWE1YTUiLCJleHAiOjE1MTI3NTYwOTMsImF1ZCI6WyJjYW52YXMuZG9ja2VyIiwiY2FudmFzLmRvY2tlciJdLCJpYXQiOjE1MTI3NTI0OTMsIm5iZiI6MTUxMjc1MjQ2MywianRpIjoiZTY3MmM5OGItYmM4NS00NjliLWE5YjYtNjEyMDE2MWFhZjk0Iiwic2hhcmRfaWQiOjEsInJlZ19rZXkiOiIwY2U0ZGJmMS1iOGM1LTQwN2QtODVhYy02MThkNzYxNWE1YTUifQ.InMhzWYLhcAWRJHJsy9pRojEcQ5KRUtRGp50mQmFrnA' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
```
When using the update endpoint the request body should contain JSON defining the key/value pairs the TP wishes Canvas to store in the Tool Setting. Canvas will *replace* the contents of the Tool Setting with whatever keys/values are sent in the request:
```json
{"tp_custom_setting": "some value"}
```
This endpoint is defined in the tool consumer profile.

##### 3. use the LTI assignment API to fetch assignment data
When a `submission_created` webhook is received for an assignment the TP has not seen before, it means that the submission is for an assignment that was copied from an assignment the TP _was_ configured on within another course. The TP should still process the submission. To fetch assignment information for a submission that has not been seen before, use the <a href="plagiarism_detection_platform_assignments.html">Canvas LTI Assignments API</a>

##### 4. use the `lti_assignment_id` and the Tool Setting Service to retrieve TP assignment-level configuration
If the TP has been leveraging Tool Settings in Canvas to store TP specific assignment-level configurations, those Tool Settings will be copied to the new assignment as well. To access the Tool Setting note the `lti_assignment_id` in the `submission_created` webhook. The Tool Setting that should be requested will have a `resource_link_id` that matches this value:
```
GET
/api/lti/tool_proxy/<tool proxy guid>/courses/24/resource_link_id/<lti assignment id>/tool_setting

```
Example Request:
```
curl -X GET \
  http://canvas.docker/api/lti/tool_proxy/0ce4dbf1-b8c5-407d-85ac-618d7615a5a5/courses/24/resource_link_id/b2d9b916-5128-42ad-ad17-b54091a52be2/tool_setting \
  -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJDYW52YXMiLCJzdWIiOiIwY2U0ZGJmMS1iOGM1LTQwN2QtODVhYy02MThkNzYxNWE1YTUiLCJleHAiOjE1MTI3NTYwOTMsImF1ZCI6WyJjYW52YXMuZG9ja2VyIiwiY2FudmFzLmRvY2tlciJdLCJpYXQiOjE1MTI3NTI0OTMsIm5iZiI6MTUxMjc1MjQ2MywianRpIjoiZTY3MmM5OGItYmM4NS00NjliLWE5YjYtNjEyMDE2MWFhZjk0Iiwic2hhcmRfaWQiOjEsInJlZ19rZXkiOiIwY2U0ZGJmMS1iOGM1LTQwN2QtODVhYy02MThkNzYxNWE1YTUifQ.InMhzWYLhcAWRJHJsy9pRojEcQ5KRUtRGp50mQmFrnA' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/x-www-form-urlencoded'
```

Response:
```
{"tp_custom_setting": "some value"}
```
#### Group Assignments
When a student submits to a group assignment, Canvas will send a `submission_created` webhook for *each student in that group*. The tool provider need only respond to one of these webhooks per group.

Canvas will copy any originality reports created for a group submission to every other student in the same group. Canvas will also propagate edits to any originality reports for a group submission to every other student in the same group.

The `submission_created` and `subission_updated` webhooks each contain a `group_id` that identifies what group a submission belongs to. Tool providers may use this value to make sure they only create one originality report per group.

#### End-User License Agreement Verification
##### Description
This feature provides a mechanism for a tool provider to specify a link to a EULA or terms of service they wish to show to students submitting homework.

This feature also guarantees that the user has agreed to the EULA/terms of service before they submit homework. The timestamp of when the user agreed is also provided to the tool provider during the normal submission/attachment retrieval flow.

##### Implementation
To implement this feature a tool provider must add the `vnd.Canvas.Eula` service to the `service_offered` array of their tool proxy:
```json
{
  …
  "service_offered": [
    …
    {
      // Must end in "#vnd.Canvas.Eula"
      "@id": "my.tool.com/service#vnd.Canvas.Eula",
      "endpoint": "http://my.tool.com/eula", // URL of EULA for Canvas to link to
      "@type": "RestService",
      "format": ["application/json"],
      "action": ["GET"]
    },
    …
  ],
  …
}
```

As shown in the example above the value of `endpoint` should be a fully qualified URL pointing to the tool provider’s terms of service or EULA. The value of the `@id` must end in `#vnd.Canvas.Eula`. The `action` array must contain `GET`.

Once the tool is registered in Canvas and associated with an assignment, students will be presented with a link to the tool’s EULA that they must agree to before Canvas will allow a homework submission:

<img style="width:35vw;" src="./images/eula.png" alt="Submission details" />

When the tool provider retrieves the assignment details from Canvas the body of the response payload will contain a property named `eula_agreement_timestamp` which contains the timestamp indicating when the user clicked the checkbox:
```json
{
   "id":215,
   "submitted_at":"2017-10-17T14:28:09Z",
   "assignment_id":216,
   "user_id":"86157096483e6b3a50bfedc6bac902c0b20a824f",
   "submission_type":"online_upload",
   "workflow_state":"submitted",
   "attempt":1,
   "eula_agreement_timestamp":"1508250487578",
   "attachments":[
      {
         "id":230,
         "size":14942,
         "filename":"1508250488_822__Test_Student_Submission.doc",
         "display_name":"Test_Student_Submission.doc",
         "created_at":"2017-10-17T14:28:08Z",
         "updated_at":"2017-10-17T14:28:08Z",
         "url":"http://canvas.docker/api/lti/assignments/10000000000216/submissions/10000000000215/attachment/10000000000230"
      }
   ]
}
```
