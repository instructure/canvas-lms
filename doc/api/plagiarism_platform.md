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
* `vnd.Canvas.submission.history` service
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
      "Service": "http://canvas.docker/api/lti/courses/3/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.submission",
      "action": ['GET']
    },
    {
      "Service": "http://canvas.docker/api/lti/courses/3/tool_consumer_profile/339b6700-e4cb-47c5-a54f-3ee0064921a9#vnd.Canvas.submission.history",
      "action": ['GET']
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
    "id": "ce95af25-a1c9-456a-a4b4-bae1233be2d8"
  }
}
```
### 3. Originality Reports
Once the TP has been notified of a new submission (see section 2.2), it may access the submission through the Canvas LTI Submissions API for processing (this service is defined in the tool consumer profile). The payload from this request will contain URLs for retrieving the submission’s attachment.

After processing the submission, an Originality Report may be created for the submission.

Using the Originality Report and Submissions APIs requires a JWT access token be sent in the authorization header. For more information on using JWT tokens in Canvas see <a href="jwt_access_tokens.html">JWT access tokens</a>.
