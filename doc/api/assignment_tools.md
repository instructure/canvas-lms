# Introduction

External tools can be associated with Canvas assignments so that students are
able to experience an integrated offering of the tool. Tools can also leverage
LTI services to return submissions and/or scores back to the Canvas gradebook.

The specifics for how grading is achieved depend on the LTI version being used:

- [LTI Advantage: Assignment and Grading Services](#lti_advantage)
- [LTI 1.1 Grade Passback Tools](#outcomes_service)

Tools become associated with Canvas assignments either through the UI during
<a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-add-an-assignment-using-an-external-app/ta-p/656"
target="_blank">assignment creation</a>, or by the tool using the
<a href="/doc/api/line_items.html" target="_blank">Line Items Service</a> to
create assignments.

If configured in via the Canvas UI, Course Designers (Admins/Instructors) will
see a submission type called "External Tool" during assignment creation where
they can select a tool configuration to use for the assignment. The
<a href="file.assignment_selection_placement.html" target="_blank">
assignment_selection placement</a> is often used in conjunction with the
<a href="file.content_item.html" target="_blank">deep linking specification</a>
to allow an Instructor or Course Designer to launch out to the tool and select a
specific resource to be associated to the assignment. When students view
the assignment, instead of seeing a standard Canvas assignment they'll see
the tool loaded in an iframe on the page.

<a name="lti_advantage"></a>
LTI Advantage: Assignment and Grading Services
====================
LTI 1.3 tools can be configured to have access to the
<a href="https://www.imsglobal.org/spec/lti-ags/v2p0/" target="_blank">
Assignment and Grading Services</a> (AGS). Assignment and Grading Services
are a powerful way for tools to interact with the LMS gradebook to save
time for instructors and students.

Some examples of use cases that are uniquely solvable using AGS that were not
resolvable by the LTI 1.1 Outcomes Service include:

- External tools can return scores for assignments without the need of students
  ever accessing the tool.
- Using the Line Items service tools can create columns to store grades in
  the gradebook without the need for instructors to manually create them using
  <a href="file.assignment_selection_placement.html" target="_blank">deep linking
  and the assignment_selection placement</a>.
- Previously returned scores can be cleared out.

In addition to permitting these use cases, many more use cases are described in
the <a
href="https://www.imsglobal.org/spec/lti/v1p3/impl#lti-advantage-use-cases"
target="_blank">IMS LTI Advantage Implementation Guide</a>.

##Configuring
To configure an LTI 1.3 tool that has access to AGS, an
<a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140"
target="_blank">LTI Developer Key must be created</a> with the desired scopes
enabled. This can either be done via the "Manual" method, or by providing raw
JSON or a secure URL that hosts JSON. A full list and description of available
scopes is described in the <a href="https://www.imsglobal.org/spec/lti-ags/v2p0/" target="_blank">
AGS documentation</a>.

For example, the following JSON would create an LTI 1.3 tool that has access to
read and write scores, check for existing scores, and manage line items (ex.
assignments) that are associated with the tool:

```
{
   "title":"Cool AGS Tool ",
   "scopes":[
      "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
      "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
      "https://purl.imsglobal.org/spec/lti-ags/scope/score"
      ],
   "extensions":[
      {
         "domain":"agsexample.com",
         "tool_id":"ags-tool-123",
         "platform":"canvas.instructure.com",
         "settings":{
            "text":"Cool AGS Text",
            "icon_url":"https://some.icon.url",
            "placements":[
               {
                  "text":"Embed Tool Content as a Canvas Assignment",
                  "enabled":true,
                  "icon_url":"https://some.icon.url",
                  "placement":"assignment_selection",
                  "message_type":"LtiDeepLinkingRequest",
                  "target_link_uri":"https://your.target_link_uri/deeplinkexample"
               }
            ]
         }
      }
   ],
   "public_jwk":{
      "kty":"RSA",
      "alg":"RS256",
      "e":"AQAB",
      "kid":"8f796169-0ac4-48a3-a202-fa4f3d814fcd",
      "n":"nZD7QWmIwj-3N_RZ1qJjX6CdibU87y2l02yMay4KunambalP9g0fU9yZLwLX9WYJINcXZDUf6QeZ-SSbblET-h8Q4OvfSQ7iuu0WqcvBGy8M0qoZ7I-NiChw8dyybMJHgpiP_AyxpCQnp3bQ6829kb3fopbb4cAkOilwVRBYPhRLboXma0cwcllJHPLvMp1oGa7Ad8osmmJhXhM9qdFFASg_OCQdPnYVzp8gOFeOGwlXfSFEgt5vgeU25E-ycUOREcnP7BnMUk7wpwYqlE537LWGOV5z_1Dqcqc9LmN-z4HmNV7b23QZW4_mzKIOY4IqjmnUGgLU9ycFj5YGDCts7Q",
      "use":"sig"
   },
   "description":"1.3 Test Tool",
   "target_link_uri":"https://your.target_link_uri",
   "oidc_initiation_url":"https://your.oidc_initiation_url"
}
```

NOTE: Using AGS does not require configuration of any specific placements, so
the placement(s) here could be any placement(s).

##Available Services
Canvas supports the following AGS services:

- <a href="/doc/api/line_items.html" target="_blank">Line Items</a>
- <a href="/doc/api/score.html" target="_blank">Score</a>
- <a href="/doc/api/result.html" target="_blank">Result</a>

##Accessing AGS
Before a tool can run AGS requests, it must be available in the course that it
wishes to interact with, and also complete the
<a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">
OAuth2 Client Credentials</a> grant to obtain an access token. This covered in
depth in the <a href="https://www.imsglobal.org/spec/security/v1p0/#securing_web_services" target="_blank">
IMS LTI Security Framework, SEC 4</a>.

##Request Throttling
Like all requests made to the Canvas API, AGS requests are throttled (see the
<a href="/doc/api/file.throttling.html" target="_blank">Throttling docs</a> for details)
to ensure that Canvas stays up and running. Unlike normal API requests which are made with
a token specific to a user, AGS tokens are specific to a tool installation for a Course or
an Account, and so there is the possibility of many more requests in a short amount of time.
As long as you as a tool provider keep requests more-or-less sequential, and pay attention
to the request throttling headers as detailed in the above doc, even this elevated level
of requests per token should not be limited.

##Common Error Codes
Below are some common error codes that you might encounter while using the Assignment
and Grade Services API. Each code also comes with some advice for fixing your issue.

| Code | Associated Message | Resolution | Notes |
| ---- | ------------------ | ---------- | ----- |
| 400 | \<parameter\> is missing | Ensure you're passing all required parameters |
| 400 | Provided timestamp of \<timestamp\> not a valid timestamp | Ensure you're passing a correctly formatted, valid timestamp |
| 400 | Provided timestamp of \<timestamp\> before last updated timestamp of \<timestamp\> | Ensure the timestamp you're passing isn't before when the result was last updated |
| 400 | Provided submitted_at timestamp of \<timestamp\> in the future | Ensure the provided timestamp isn't too far in the future |
| 401 | Invalid Developer Key | Ensure your credentials point to the correct developer key and that the key is on |
| 401 | Access Token not linked to a Tool associated with this Context | Ensure that your tool is installed and available in the specified context |
| 404 | The specified resource does not exist. | Verify that the course, resource link, line item, or any other such resource that you're specifying exists |
| 404 | Context not found | Ensure that the context you're specifying actually exists. |
| 412 | Tool does not have permission to view line_item | Ensure the specified line item is associated with your tool |
| 412 | The specified LTI link ID is not associated with the line item | Ensure the resourceLinkId you're passing is associated with this line item |
| 422 | This course has concluded. AGS requests will no longer be accepted for this course. | Reopen the specified course or stop sending requests for this course | Only returned if the ags_improved_course_concluded_response_codes feature flag is enabled |
| 422 | User not found in course or is not a student | Ensure the user you're specifying exists or is a student |
| 422 | ScoreMaximum must be greater than or equal to 0 | Ensure you're passing a valid value for ScoreMaximum |
| 422 | ScoreMaximum not supplied when ScoreGiven present | Ensure you're providing a ScoreMaximum in any request with a ScoreGiven |
| 422 | Content items must be provided with submission type 'online_upload' | Ensure you specify the correct submission type when providing submission files |
| 422 | The maximum number of allowed attempts has been reached for this submission | Add additional attempts or stop sending submission requests for the specified student |

##Extensions
Canvas has extended several AGS endpoints to support deeper grading
integrations. Here, we will focus on these extensions and describe how tools can
be configured to leverage AGS in Canvas.

###Line Item Extension: Creating deep linked assignments
The <a href="/doc/api/line_items.html" target="_blank">Line Item service</a> has been extended
to allow an external tool to not only create gradebook columns (i.e. assignments)
in Canvas, but also connect the column/assignment to a specific LTI resource on
the external tool. This means that when the student accesses the assignment from
Canvas, they are able to see the external tool content directly in the page,
complete their assessment on the tool side, and have grades returned without
the instructor having to manually create assignments in Canvas.

This also allows tools to introduce new workflows, such as allowing instructors
to launch from a Course Navigation Placement, select multiple resources, and
import them into their course.

###Score Extension: Creating submission data
The <a href="/doc/api/score.html" target="_blank">Score service</a> has been extended to allow
an external tool to submission data back to the Canvas Gradebook. This data is
then exposed in the Submission Details and Speedgrader Views so that both
students and teachers can see what was submitted to the external tool without
leaving Canvas. Support for basic urls, text, and LTI links are supported.

<a name="outcomes_service"></a>
LTI 1.1 Grade Passback Tools
====================

Tools can know that they have been launched in a graded context because
additional parameters are sent across when a student accesses the external
tool assignment. Specifically, the `lis_outcome_service_url` and
`lis_result_sourced_id` are sent as specified in the LTI 1.1 specification.
Grades are passed back to Canvas from the tool's servers using the
<a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560472">
outcomes component of LTI 1.1</a>. Notably, one of the major limitations of the
LTI 1.1 Outcomes Service is the inability of tools to return grades _before_ a
student accesses the assignment from Canvas. If this functionality is desirable,
you should upgrade to LTI Advantage's Assignment and Grading Services.

**Note** that in the past Canvas would return a 200 HTTP response code, even if the
XML in the body of the response indicated failure. This behavior has changed,
and now if the `imsx_codeMajor` in the XML response is not `success`, then
Canvas will return a 422 (Unprocessable Entity) HTTP response code.

## Data Return Extension

Canvas sends an extension parameter for assignment launches that allows the tool
provider to pass back values as submission text in canvas.
The key is `ext_outcome_data_values_accepted` and the value is a comma separated list of
types of data accepted. The currently available data types are `url` and `text`.
The added launch parameter will look like this:

`ext_outcome_data_values_accepted=url,text`

### Returning Data Values from Tool Provider

If the external tool wants to supply these values, it can augment the POX sent
with the grading value. <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560473">LTI replaceResult POX</a>

Only one type of resultData should be sent, if multiple types are sent the tool
consumer behavior is undefined and is implementation-specific. Canvas will take
the text value and ignore the url value if both are sent.

####Text

Add a `resultData` node with a `text` node of plain text in the same encoding as
the rest of the document within it like this:

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
          <!-- Added element -->
          <resultData>
            <text>text data for canvas submission</text>
          </resultData>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

####URL

Add a `resultData` node with a `url` node within it like this:

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
          <!-- Added element -->
          <resultData>
            <url>https://www.example.com/cool_lti_link_submission</url>
          </resultData>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

#### LTI Launch URL

Add a `resultData` node with a `ltiLaunchUrl` node like this:

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
          <!-- Added element -->
          <resultData>
            <ltiLaunchUrl>https://some.launch.url/launch?lti_submission_id=42</ltiLaunchUrl>
          </resultData>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

## Total Score Return Extension

Canvas sends an extension parameter for assignment launches that allows the tool
provider to pass back a raw score value instead of a percentage.
The key is `ext_outcome_result_total_score_accepted` and the value is `true`.
The added launch parameter will look like this:

`ext_outcome_result_total_score_accepted=true`

### Returning Total Score from Tool Provider

If the external tool wants to supply this value, it can augment the POX sent
with the grading value. <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560473">LTI replaceResult POX</a>

Simply add a node called `resultTotalScore` instead of `resultScore`. If both are
sent, then `resultScore` will be ignored. The `textString` value should be
an Integer or Float value.

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <!-- Added element -->
          <resultTotalScore>
            <language>en</language>
            <textString>50</textString>
          </resultTotalScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

# Submission Details Return Extension

Canvas sends an extension parameter for assignment launches that allows the tool
provider to pass back submission metadata not directly related to the result.

Details about the submission the external tool wants to supply
should augment the POX sent with the grading value. <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560473">LTI replaceResult POX</a>
Simply add a node called `submissionDetails` to the `replaceResultRequest` node. Any data regarding
the submission that is not related directly to the result will be included in this node.

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <!-- Added element -->
      <submissionDetails>
        ...
      </submissionDetails>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

## Submission Submitted At Timestamp Extension

Canvas sends an extension parameter for assignment launches that allows the tool
provider to pass back the submission submitted at timestamp.
The key is `ext_outcome_submission_submitted_at_accepted` and the value is `true`.
The added launch parameter will look like this:

`ext_outcome_submission_submitted_at_accepted=true`

### Submission Submitted At Timestamp from Tool Provider

If the external tool wants to supply this value, it can augment the POX sent
with the submission submitted at value. <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560473">LTI replaceResult POX</a>

Simply add a node called `submittedAt` to the `submissionDetails` node. The text
string must be an <a href="https://tools.ietf.org/html/rfc3339">iso8601 formatted timestamp</a>.
If included, then it will override any existing submitted_at value on the submission even when
result score or result total score are not present.

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <submissionDetails>
        <!-- Added element -->
        <submittedAt>
          2017-04-16T18:54:36.736+00:00
        </submittedAt>
      </submissionDetails>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

### Submission Prioritize Non-tool Grade from Tool Provider

If an external tool wants to honor/preserve any grading done in Canvas by a human, it can augment the POX sent with a
prioritize non-tool grade tag.

Simply add a node called `prioritizeNonToolGrade` to the `submissionDetails` node. The tag expects no data, just its
presence is all that is required for Canvas. If included, any grading done by something other than an LTI tool will
be preserved.

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <submissionDetails>
        <!-- Added element -->
        <prioritizeNonToolGrade/>
      </submissionDetails>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```

### Submission Needs Additional Review

If an external tool wants to tell canvas that grading isn't final and additional review is needed by the instructor, it
can augment the POX sent with the needs additional review grade tag.

Simply add a node called `needsAdditionalReview` to the `submissionDetails` node. The tag expects no data, just its
presence is all that is required for Canvas. If included, the Canvas gradebook will signal to the teacher additional
grading action is needed.

```xml
<?xml version = "1.0" encoding = "UTF-8"?>
<imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
  <imsx_POXHeader>
    <imsx_POXRequestHeaderInfo>
      <imsx_version>V1.0</imsx_version>
      <imsx_messageIdentifier>999999123</imsx_messageIdentifier>
    </imsx_POXRequestHeaderInfo>
  </imsx_POXHeader>
  <imsx_POXBody>
    <replaceResultRequest>
      <submissionDetails>
        <!-- Added element -->
        <needsAdditionalReview/>
      </submissionDetails>
      <resultRecord>
        <sourcedGUID>
          <sourcedId>3124567</sourcedId>
        </sourcedGUID>
        <result>
          <resultScore>
            <language>en</language>
            <textString>0.92</textString>
          </resultScore>
        </result>
      </resultRecord>
    </replaceResultRequest>
  </imsx_POXBody>
</imsx_POXEnvelopeRequest>
```
