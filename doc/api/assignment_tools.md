Grade Passback Tools
====================

Graded external tools are configured just like regular external tools. The
difference is that rather than adding the tool to a course as a link in a
module, a navigation item, etc. the tool gets added as an assignment.
Instructors will see a new assignment type called "External Tool" where
they can select a tool configuration to use for the assignment. When students
go to view the assignment instead of seeing a standard Canvas description
they'll see the tool loaded in an iframe on the page. The tool can then
send grading information back to Canvas.

Tools can know that they have been launched in a graded context because
an additional parameter is sent across, `lis_outcome_service_url`,
as specified in the LTI 1.1 specification. Grades are passed back to Canvas
from the tool's servers using the
<a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560472">outcomes component of LTI 1.1</a>.

## Data Return Extension

Canvas sends an extension parameter for assignment launches that allows the tool
provider to pass back values as submission text in canvas.
The key is `ext_outcome_data_values_accepted` and the value is a comma separated list of
types of data accepted. The currently available data types are `url` and `text`.
So the added launch parameter will look like this:

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
So the added launch parameter will look like this:

`ext_outcome_result_total_score_accepted=true`

### Returning Total Score from Tool Provider

If the external tool wants to supply this value, it can augment the POX sent
with the grading value. <a href="http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html#_Toc319560473">LTI replaceResult POX</a>

Simply add a node called `resultTotalScore` instead of `resultScore`. If both are
sent, then `resultScore` will be ignored. The `textString` value  should be
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
So the added launch parameter will look like this:

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
