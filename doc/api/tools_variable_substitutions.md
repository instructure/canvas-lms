<!--
  DONT EDIT THIS FILE DIRECTLY
  Update:
    - doc/api/tools_variable_substitutions.head.md
    - lib/lti/variable_expander.rb

  then run `script/generate_lti_variable_substitution_markdown`
-->

# LTI Variable Substitutions

Variable substitution (aka variable expansion) is where custom variables really start to
shine. They provide a mechanism for tool providers to request that specific, contextual
information be sent across in the launch. When the tool consumer processes the launch request,
it detects requested variable substitutions and sends the appropriate data where possible.
Adding variable substitutions is exactly the same as adding custom variables, except the values
are variables instead of constants. This is denoted by prefixing the value with a $. If the
tool consumer doesn't recognize, or can't substitute, the value it will just send the variable
as if it were are regular custom variable (i.e. the name of the substitution variable will be
sent rather than the value).

This allows Canvas to expose data as LTI launch parameters during the LTI launch rather than
requiring access to the Canvas API, which can be expensive for Canvas and the tool. It allows
tool providers to be much more surgical when requesting user data, and it paves the way for us
to be more transparent to tool installers, by showing them exactly what data the LTI tool will
be given access to. Additionally, variable substitutions are generally simple to add to Canvas
relative to gaining API access.

There are currently over 80 substitutions available. Many of the substitutions simply
give access to additional user and context information. An LTI tool can request things
like SIS ids, names, an avatar image, and an email address. Other variable substitutions
assist tools with accessibility (prefersHighContrast), course copy (previousCourseIds), and
masquerading users. Additionally, when we don't provide enough information or customization
directly through LTI, tools can request everything they need to use the Canvas API for an even
richer experience.

Some substitutions may be used as 'enabled_capabilities' for LTI2 tools. These substitutions have a
'Launch Parameter' label indicating the parameter name that will be sent in the tool launch if enabled.

For more information on variable substitution, see the <a href="https://www.imsglobal.org/specs/ltiv1p1p1/implementation-guide#toc-9">IMS LTI specification</a>.

# Usage/Configuration

Variable substitutions can be configured for a tool in 3 ways:

## Via UI

Custom fields can be <a href="https://community.canvaslms.com/docs/DOC-3033">configured via UI</a> by editing the tool configuration and adding the
desired variable to the Custom Fields text box.

The following would add the domain as a launch parameter called custom_arbitrary_name:

```
arbitrary_name=$Canvas.api.domain
```

## Via API

Custom fields can also be <a href="/doc/api/external_tools.html#method.external_tools.create">configured via API</a>.

This would install a course-level tool with domain as a custom field:

```
curl 'https://<domain>.instructure.com/api/v1/courses/<course_id>/external_tools' \
  -X POST \
  -H "Authorization: Bearer <token>;" \
  -F 'name=LTI Example' \
  -F 'consumer_key=some_key' \
  -F 'shared_secret=some_secret' \
  -F 'url=https://example.com/ims/lti' \
  -F 'privacy_level=name_only' \
  -F 'custom_fields[domain]=$Canvas.api.domain'
```

## Via XML Configuration

Custom fields can also be <a href="http://canvas.docker/doc/api/file.tools_xml.html">configured via XML</a>.

This would create a tool in a course with custom fields, some of which are specific for a
particular placement:

```
<?xml version="1.0" encoding="UTF-8"?>
   <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
       xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
       xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
       xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
       xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
       http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
       http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
       http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
     <blti:title>Wikipedia</blti:title>
     <blti:launch_url>https://www.wikipedia.org/</blti:launch_url>
     <blti:custom>
       <lticm:property name="user_sis_id">$Person.sourcedId</lticm:property>
     </blti:custom>
     <blti:extensions platform="canvas.instructure.com">
       <lticm:property name="domain">wikipedia.org</lticm:property>
       <lticm:options name="custom_fields">
           <lticm:property name="canvas_api_domain">$Canvas.api.domain</lticm:property>
           <lticm:property name="canvas_user_id">$Canvas.user.id</lticm:property>
       </lticm:options>
       <lticm:options name="course_navigation">
         <lticm:property name="url">https://en.wikipedia.org/wiki/Wikipedia:Unusual_articles#mediaviewer/File:Cow-on_pole,_with_antlers.jpeg</lticm:property>
         <lticm:property name="text">Cow With Antlers</lticm:property>
         <lticm:options name="custom_fields">
           <lticm:property name="concluded_roles">$Canvas.membership.concludedRoles</lticm:property>
         </lticm:options>
       </lticm:options>
     </blti:extensions>
   </cartridge_basiclti_link>
```

# Supported Substitutions

## Context.title

The title of the context.

**Availability**: _always_  
**Launch Parameter**: _context_title_

```
Example Course
```

## com.instructure.Editor.contents

The contents of the text editor associated with the content item launch.

**Availability**: _always_  
**Launch Parameter**: _com_instructure_editor_contents_

```
"This text was in the editor"
```

## com.instructure.Editor.selection

The contents the user has selected in the text editor associated
with the content item launch.

**Availability**: _always_  
**Launch Parameter**: _com_instructure_editor_selection_

```
"this text was selected by the user"
```

## com.instructure.PostMessageToken

A token that can be used for frontend communication between an LTI tool
and Canvas via the Window.postMessage API.

**Availability**: \**  
**Launch Parameter**: *com_instructure_post_message_token\*

```
9ae4170c-6b64-444d-9246-0b7dedd5f560
```

## com.instructure.Assignment.lti.id

The LTI assignment id of an assignment. This value corresponds with
the `ext_lti_assignment_id` send in various launches and webhooks.

**Availability**: _always_  
**Launch Parameter**: _com_instructure_assignment_lti_id_

```
9ae4170c-6b64-444d-9246-0b7dedd5f560
```

## com.instructure.OriginalityReport.id

The Canvas id of the Originality Report associated
with the launch.

**Availability**: \**  
**Launch Parameter**: *com_instructure_originality_report_id\*

```
23
```

## com.instructure.Submission.id

The Canvas id of the submission associated with the
launch.

**Availability**: \**  
**Launch Parameter**: *com_instructure_submission_id\*

```
23
```

## com.instructure.File.id

The Canvas id of the file associated with the submission
in the launch.

**Availability**: \**  
**Launch Parameter**: *com_instructure_file_id\*

```
23
```

## CourseOffering.sourcedId

the LIS identifier for the course offering.

**Availability**: _when launched in a course_  
**Launch Parameter**: _lis_course_offering_sourcedid_

```
1234
```

## Context.id

an opaque identifier that uniquely identifies the context of the tool launch.

**Availability**: _always_  
**Launch Parameter**: _context_id_

```
cdca1fe2c392a208bd8a657f8865ddb9ca359534
```

## Context.sourcedId

The sourced Id of the context.

**Availability**: _always_

```
1234
```

## Message.documentTarget

communicates the kind of browser window/frame where the Canvas has launched a tool.

**Availability**: _always_  
**Launch Parameter**: _launch_presentation_document_target_

```
iframe
```

## Message.locale

returns the current locale.

**Availability**: _always_  
**Launch Parameter**: _launch_presentation_locale_

```
de
```

## ToolConsumerInstance.guid

returns a unique identifier for the Tool Consumer (Canvas).

**Availability**: _always_  
**Launch Parameter**: _tool_consumer_instance_guid_

```
0dWtgJjjFWRNT41WdQMvrleejGgv7AynCVm3lmZ2:canvas-lms
```

## Canvas.api.domain

returns the canvas domain for the current context.

**Availability**: _always_

```
canvas.instructure.com
```

## Canvas.api.collaborationMembers.url

returns the api url for the members of the collaboration.

**Availability**: _always_

```
https://canvas.instructure.com/api/v1/collaborations/1/members
```

## Canvas.api.baseUrl

returns the base URL for the current context.

**Availability**: _always_

```
https://canvas.instructure.com
```

## ToolProxyBinding.memberships.url

returns the URL for the membership service associated with the current context.

This variable is for future use only. Complete support for the IMS Membership Service has not been added to Canvas. This will be updated when we fully support and certify the IMS Membership Service.

**Availability**: _always_

```
https://canvas.instructure.com/api/lti/courses/1/membership_service
```

## Canvas.account.id

returns the account id for the current context.

**Availability**: _always_

```
1234
```

## Canvas.account.name

returns the account name for the current context.

**Availability**: _always_

```
School Name
```

## Canvas.account.sisSourceId

returns the account's sis source id for the current context.

**Availability**: _always_

```
sis_account_id_1234
```

## Canvas.rootAccount.id

returns the Root Account ID for the current context.

**Availability**: _always_

```
1234
```

## Canvas.rootAccount.sisSourceId

returns the root account's sis source id for the current context.

**Availability**: _always_

```
sis_account_id_1234
```

## Canvas.externalTool.url

returns the URL for the external tool that was launched. Only available for LTI 1.

**Availability**: _always and when in an LTI 1_

```
http://example.url/path
```

## com.instructure.brandConfigJSON.url

returns the URL to retrieve the brand config JSON for the launching context.

**Availability**: _always_

```
http://example.url/path.json
```

## com.instructure.brandConfigJSON

returns the brand config JSON itself for the launching context.

**Availability**: _always_

```
{"ic-brand-primary-darkened-5":"#0087D7"}
```

## com.instructure.brandConfigJS.url

returns the URL to retrieve the brand config javascript for the launching context.
This URL should be used as the src attribute for a script tag on the external tool
provider's web page. It is configured to be used with the [instructure-ui node module](https://github.com/instructure/instructure-ui).
More information on on how to use instructure ui react components can be found [here](http://instructure.github.io/instructure-ui/).

**Availability**: _always_

```
http://example.url/path.js
```

## Canvas.css.common

returns the URL for the common css file.

**Availability**: _always_

```
http://example.url/path.css
```

## Canvas.shard.id

returns the shard id for the current context.

**Availability**: _always_

```
1234
```

## Canvas.root_account.global_id [duplicates Canvas.user.globalId]

returns the root account's global id for the current context.

**Availability**: _always_

```
123400000000123
```

## Canvas.root_account.id _[deprecated]_

returns the root account id for the current context.

**Availability**: _always_

```
1234
```

## vnd.Canvas.root_account.uuid

returns the account uuid for the current context.

**Availability**: _always_  
**Launch Parameter**: _vnd_canvas_root_account_uuid_

```
Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo
```

## Canvas.root_account.sisSourceId _[deprecated]_

returns the root account sis source id for the current context.

**Availability**: _always_

```
1234
```

## Canvas.course.id

returns the current course id.

**Availability**: _when launched in a course_

```
1234
```

## vnd.instructure.Course.uuid

returns the current course uuid.

**Availability**: _when launched in a course_

```
S3vhRY2pBzG8iPdZ3OBPsPrEnqn5sdRoJOLXGbwc
```

## Canvas.course.name

returns the current course name.

**Availability**: _when launched in a course_

```
Course Name
```

## Canvas.course.sisSourceId

returns the current course sis source id.

**Availability**: _when launched in a course_

```
1234
```

## Canvas.course.startAt

returns the current course start date.

**Availability**: _when launched in a course_

```
YYY-MM-DD HH:MM:SS -0700
```

## Canvas.course.workflowState

returns the current course workflow state. Workflow states of "claimed" or "created"
indicate an unpublished course.

**Availability**: _when launched in a course_

```
active
```

## Canvas.term.startAt

returns the current course's term start date.

**Availability**: _when launched in a course that has a term with a start date_

```
YYY-MM-DD HH:MM:SS -0700
```

## Canvas.term.name

returns the current course's term name.

**Availability**: \**  
**Launch Parameter**: *canvas_term_name\*

```
W1 2017
```

## CourseSection.sourcedId

returns the current course sis source id
to return the section source id use Canvas.course.sectionIds.

**Availability**: _when launched in a course_  
**Launch Parameter**: _lis_course_section_sourcedid_

```
1234
```

## Canvas.enrollment.enrollmentState

returns the current course enrollment state.

**Availability**: _when launched in a course_

```
active
```

## Canvas.membership.roles

returns the current course membership roles.

**Availability**: _when launched from a course or an account_

```
StudentEnrollment
```

## Canvas.membership.concludedRoles

This is a list of IMS LIS roles should have a different key.

**Availability**: _when launched in a course_

```
urn:lti:sysrole:ims/lis/None
```

## Canvas.course.previousContextIds

With respect to the current course, returns the context ids of the courses from which content has been copied (excludes cartridge imports).

**Availability**: _when launched in a course_

```
1234,4567
```

## Canvas.course.previousContextIds.recursive

With respect to the current course, recursively returns the context ids of the courses from which content has been copied (excludes cartridge imports).

**Availability**: _when launched in a course_

```
1234,4567
```

## Canvas.course.previousCourseIds

With respect to the current course, returns the course ids of the courses from which content has been copied (excludes cartridge imports).

**Availability**: _when launched in a course_

```
1234
```

## Person.name.full

Returns the full name of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _lis_person_name_full_

```
John Doe
```

## Person.name.display

Returns the display name of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _person_name_display_

```
John Doe
```

## Person.name.family

Returns the last name of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _lis_person_name_family_

```
Doe
```

## Person.name.given

Returns the first name of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _lis_person_name_given_

```
John
```

## Person.email.primary

Returns the primary email of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _lis_person_contact_email_primary_

```
john.doe@example.com
```

## vnd.Canvas.Person.email.sis

Returns the institution assigned email of the launching user.

**Availability**: _when launched by a logged in user that was added via SIS_

```
john.doe@example.com
```

## Person.address.timezone

Returns the name of the timezone of the launching user.

**Availability**: _when launched by a logged in user_

```
America/Denver
```

## User.image

Returns the profile picture URL of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _user_image_

```
https://example.com/picture.jpg
```

## User.id [duplicates Canvas.user.id]

Returns the Canvas user_id of the launching user.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _user_id_

```
420000000000042
```

## Canvas.user.id [duplicates User.id]

Returns the Canvas user_id of the launching user.

**Availability**: _when launched by a logged in user_

```
420000000000042
```

## vnd.instructure.User.uuid [duplicates User.uuid]

Returns the Canvas user_uuid of the launching user.

**Availability**: _when launched by a logged in user_

```
N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3
```

## Canvas.user.prefersHighContrast

Returns the users preference for high contrast colors (an accessibility feature).

**Availability**: _when launched by a logged in user_

```
false
```

## Canvas.group.contextIds

returns the context ids for the groups the user belongs to in the course.

**Availability**: _always_

```
1c16f0de65a080803785ecb3097da99872616f0d,d4d8d6ae1611e2c7581ce1b2f5c58019d928b79d,...
```

## Membership.role

Returns the [IMS LTI membership service](https://www.imsglobal.org/specs/ltimemv1p0/specification-3) roles for filtering via query parameters.

**Availability**: _when launched by a logged in user_  
**Launch Parameter**: _roles_

```
http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator
```

## Canvas.xuser.allRoles [duplicates ext_roles which is sent by default]

Returns list of [LIS role full URNs](https://www.imsglobal.org/specs/ltiv1p0/implementation-guide#toc-16).

**Availability**: _always_

```
urn:lti:instrole:ims/lis/Administrator,urn:lti:instrole:ims/lis/Instructor,urn:lti:sysrole:ims/lis/SysAdmin,urn:lti:sysrole:ims/lis/User
```

## Canvas.user.globalId [duplicates Canvas.root_account.global_id]

Returns the Canvas global user_id of the launching user.

**Availability**: _when launched by a logged in user_

```
420000000000042
```

## Canvas.user.isRootAccountAdmin

Returns true for root account admins and false for all other roles.

**Availability**: _when launched by a logged in user_

```
true
```

## User.username [duplicates Canvas.user.loginId]

Username/Login ID for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with.

**Availability**: _when pseudonym is in use_

```
jdoe
```

## Canvas.user.loginId [duplicates User.username]

Username/Login ID for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with.

**Availability**: _when pseudonym is in use_

```
jdoe
```

## Canvas.user.sisSourceId [duplicates Person.sourcedId]

Returns the sis source id for the primary pseudonym for the user for the account
This may not be the pseudonym the user is actually logged in with.

**Availability**: _when pseudonym is in use_

```
sis_user_42
```

## Canvas.user.sisIntegrationId

Returns the integration id for the primary pseudonym for the user for the account
This may not be the pseudonym the user is actually logged in with.

**Availability**: _when pseudonym is in use_

```
integration_user_42
```

## Person.sourcedId [duplicates Canvas.user.sisSourceId]

Returns the sis source id for the primary pseudonym for the user for the account
This may not be the pseudonym the user is actually logged in with.

**Availability**: _when pseudonym is in use_  
**Launch Parameter**: _lis_person_sourcedid_

```
sis_user_42
```

## Canvas.logoutService.url

Returns the logout service url for the user.
This is the pseudonym the user is actually logged in as.
It may not hold all the sis info needed in other launch substitutions.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/v1/logout_service/<external_tool_id>-<user_id>-<current_unix_timestamp>-<opaque_string>
```

## Canvas.masqueradingUser.id

Returns the Canvas user_id for the masquerading user.
This is the pseudonym the user is actually logged in as.
It may not hold all the sis info needed in other launch substitutions.

**Availability**: _when the user is being masqueraded_

```
420000000000042
```

## Canvas.masqueradingUser.userId

Returns the 40 character opaque user_id for masquerading user.
This is the pseudonym the user is actually logged in as.
It may not hold all the sis info needed in other launch substitutions.

**Availability**: _when the user is being masqueraded_

```
da12345678cb37ba1e522fc7c5ef086b7704eff9
```

## Canvas.xapi.url

Returns the xapi url for the user.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/v1/xapi/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
```

## Caliper.url

Returns the caliper url for the user.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/v1/caliper/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
```

## Canvas.course.sectionIds

Returns a comma separated list of section_id's that the user is enrolled in.

**Availability**: _when launched from a course_

```
42, 43
```

## Canvas.course.sectionSisSourceIds

Returns a comma separated list of section sis_id's that the user is enrolled in.

**Availability**: _when launched from a course_

```
section_sis_id_1, section_sis_id_2
```

## com.instructure.contextLabel

Returns the course code.

**Availability**: _when launched in a course_  
**Launch Parameter**: _context_label_

```
CS 124
```

## Canvas.module.id

Returns the module_id that the module item was launched from.

**Availability**: _when content tag is present_

```
1234
```

## Canvas.moduleItem.id

Returns the module_item_id of the module item that was launched.

**Availability**: _when content tag is present_

```
1234
```

## Canvas.assignment.id

Returns the assignment_id of the assignment that was launched.

**Availability**: _when launched as an assignment_

```
1234
```

## Canvas.assignment.title

Returns the title of the assignment that was launched.

**Availability**: _when launched as an assignment_

```
Deep thought experiment
```

## Canvas.assignment.pointsPossible

Returns the points possible of the assignment that was launched.

**Availability**: _when launched as an assignment_

```
100
```

## Canvas.assignment.unlockAt _[deprecated]_

deprecated in favor of ISO8601.

**Availability**: _when launched as an assignment_

## Canvas.assignment.lockAt _[deprecated]_

deprecated in favor of ISO8601.

**Availability**: _when launched as an assignment_

## Canvas.assignment.dueAt _[deprecated]_

deprecated in favor of ISO8601.

**Availability**: _when launched as an assignment_

## Canvas.assignment.unlockAt.iso8601

Returns the `unlock_at` date of the assignment that was launched.
Only available when launched as an assignment with an `unlock_at` set.

**Availability**: _always_

```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.lockAt.iso8601

Returns the `lock_at` date of the assignment that was launched.
Only available when launched as an assignment with a `lock_at` set.

**Availability**: _always_

```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.dueAt.iso8601

Returns the `due_at` date of the assignment that was launched.
Only available when launched as an assignment with a `due_at` set.

**Availability**: _always_

```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.published

Returns true if the assignment that was launched is published.
Only available when launched as an assignment.

**Availability**: _when launched as an assignment_

```
true
```

## LtiLink.custom.url

Returns the endpoint url for accessing link-level tool settings
Only available for LTI 2.0.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/tool_settings/<link_id>
```

## ToolProxyBinding.custom.url

Returns the endpoint url for accessing context-level tool settings
Only available for LTI 2.0.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/tool_settings/<binding_id>
```

## ToolProxy.custom.url

Returns the endpoint url for accessing system-wide tool settings
Only available for LTI 2.0.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/tool_settings/<proxy_id>
```

## ToolConsumerProfile.url

Returns the [Tool Consumer Profile](https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-46) url for the tool.
Only available for LTI 2.0.

**Availability**: _always_

```
https://<domain>.instructure.com/api/lti/courses/<course_id>/tool_consumer_profile/<opaque_id>
https://<domain>.instructure.com/api/lti/accounts/<account_id>/tool_consumer_profile/<opaque_id>
```

## vnd.Canvas.OriginalityReport.url

The originality report LTI2 service endpoint.

**Availability**: _always_  
**Launch Parameter**: _vnd_canvas_originality_report_url_

```
api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report
```

## vnd.Canvas.submission.url

The submission LTI2 service endpoint.

**Availability**: _always_  
**Launch Parameter**: _vnd_canvas_submission_url_

```
api/lti/assignments/{assignment_id}/submissions/{submission_id}
```

## vnd.Canvas.submission.history.url

The submission history LTI2 service endpoint.

**Availability**: _always_  
**Launch Parameter**: _vnd_canvas_submission_history_url_

```
api/lti/assignments/{assignment_id}/submissions/{submission_id}/history
```

## Canvas.file.media.id

**Availability**: _when an attachment is present and it has either a media object or media entry id defined_

## Canvas.file.media.type

**Availability**: _when an attachment is present and has a media object defined_

## Canvas.file.media.duration

**Availability**: _when an attachment is present and has a media object defined_

## Canvas.file.media.size

**Availability**: _when an attachment is present and has a media object defined_

## Canvas.file.media.title

**Availability**: _when an attachment is present and has a media object defined_

## Canvas.file.usageRights.name

**Availability**: _when an attachment is present and has usage rights defined_

## Canvas.file.usageRights.url

**Availability**: _when an attachment is present and has usage rights defined_

## Canvas.file.usageRights.copyrightText

**Availability**: _when an attachment is present and has usage rights defined_
