LTI Variable Substitutions
==========================

Variable substitution (aka variable expansion) is where custom variables really start to
shine.  They provide a mechanism for tool providers to request that specific, contextual
information be sent across in the launch.  When the tool consumer processes the launch request,
it detects requested variable substitutions and sends the appropriate data where possible.
Adding variable substitutions is exactly the same as adding custom variables, except the values
are variables instead of constants.  This is denoted by prefixing the value with a $.  If the
tool consumer doesn't recognize, or can't substitute, the value it will just send the variable
as if it were are regular custom variable (i.e. the name of the substitution variable will be
sent rather than the value).

This allows Canvas to expose data as LTI launch parameters during the LTI launch rather than
requiring access to the Canvas API, which can be expensive for Canvas and the tool.  It allows
tool providers to be much more surgical when requesting user data, and it paves the way for us
to be more transparent to tool installers, by showing them exactly what data the LTI tool will
be given access to. Additionally, variable substitutions are generally simple to add to Canvas
relative to gaining API access.

There are currently over 80 substitutions available.  Many of the substitutions simply
give access to additional user and context information.  An LTI tool can request things
like SIS ids, names, an avatar image, and an email address.  Other variable substitutions
assist tools with accessibility (prefersHighContrast), course copy (previousCourseIds), and
masquerading users.  Additionally, when we don't provide enough information or customization
directly through LTI, tools can request everything they need to use the Canvas API for an even
richer experience.

Some substitutions may be used as 'enabled_capabilities' for LTI2 tools. These substitutions have a
'Launch Parameter' label indicating the parameter name that will be sent in the tool launch if enabled.

For more information on variable substitution, see the <a href="https://www.imsglobal.org/specs/ltiv1p1p1/implementation-guide#toc-9" target="_blank">IMS LTI specification.</a>

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
## Context.id
an opaque identifier that uniquely identifies the context of the tool launch

Launch Parameter: *context_id*

```
cdca1fe2c392a208bd8a657f8865ddb9ca359534
```

## ToolConsumerInstance.guid
returns a unique identifier for the Tool Consumer (Canvas)

Launch Parameter: *tool_consumer_instance_guid*

```
0dWtgJjjFWRNT41WdQMvrleejGgv7AynCVm3lmZ2:canvas-lms
```

## Message.locale
returns the current locale

Launch Parameter: *launch_presentation_locale*

```
de
```

## Message.documentTarget
communicates the kind of browser window/frame where the Canvas has launched a tool

Launch Parameter: *launch_presentation_document_target*

```
iframe
```

## Canvas.api.domain
returns the canvas domain for the current context. Should always be available.

```
canvas.instructure.com
```

## Canvas.api.collaborationMembers.url
returns the api url for the members of the collaboration.

```
https://canvas.instructure.com/api/v1/collaborations/1/members
```

## Canvas.api.baseUrl
returns the base URL for the current context. Should always be available.

```
https://canvas.instructure.com
```

## ToolProxyBinding.memberships.url
returns the URL for the membership service associated with the current context.

```
https://canvas.instructure.com/api/lti/courses/1/membership_service
```

## Canvas.account.id
returns the account id for the current context. Should always be available.

```
1234
```

## Canvas.account.name
returns the account name for the current context. Should always be available.

```
School Name
```

## Canvas.account.sisSourceId
returns the account's sis source id for the current context. Only available if sis_account_id is specified.
```
sis_account_id_1234
```

## Canvas.rootAccount.id
returns the Root Account ID for the current context. Should always be available.

```
1234
```

## Canvas.rootAccount.sisSourceId
returns the root account's sis source id for the current context. Only available if sis_account_id is specified.
```
sis_account_id_1234
```

## Canvas.externalTool.url
returns the URL for the external tool that was launched. Only available for LTI 1.

```
http://example.url/path
```

## Canvas.css.common
returns the URL for the common CSS file. Should always be available.

```
http://example.url/path.css
```

## Canvas.shard.id
returns the shard id for the current context. Should always be available.

```
1234
```

## Canvas.root_account.global_id
returns the root account's global id for the current context. Should always be available.

```
123400000000123
```

## Canvas.root_account.id *[deprecated]*
returns the root account id for the current context. Should always be available.

```
1234
```

## Canvas.root_account.sisSourceId *[deprecated]*
returns the root account sis source id for the current context. Should always be available.

```
1234
```

## Canvas.course.id
returns the current course id. Only available when launched in a course.

```
1234
```

## Canvas.course.workflowState
returns the current course workflow state. Workflow states of "claimed" or "created" indicate an unpublished course.

```
available
```

## Canvas.course.sisSourceId
returns the current course sis source id. Only available when launched in a course.

```
1234
```

## Canvas.course.startAt
returns the current course start date. Only available when launched in a course.

```
YYY-MM-DD HH:MM:SS -0700
```

## Canvas.term.startAt
returns the current course's term start date. Only available when launched in a course that has a term with a start date.

```
YYY-MM-DD HH:MM:SS -0700
```

## CourseSection.sourcedId
returns the current course sis source id. Only available when launched in a course.
to return the section source id use Canvas.course.sectionIds

Launch Parameter: *lis_course_section_sourcedid*

```
1234
```

## Canvas.enrollment.enrollmentState
returns the current course enrollment state. Only available when launched in a course.

```
active
```

## Canvas.membership.roles
returns the current course membership roles. Only available when launched from a course or an account.

```
StudentEnrollment
```

## Canvas.membership.concludedRoles
This is a list of IMS LIS roles should have a different key. Only available when launched in a course.
```
urn:lti:sysrole:ims/lis/None
```

## Canvas.course.previousContextIds
Returns the context ids from the course that the current course was copied from.
Only available when launched in a course that was copied (excludes cartridge imports).

```
1234
```

## Canvas.course.previousCourseIds
Returns the course ids of the course that the current course was copied from.
Only available when launched in a course that was copied (excludes cartridge imports).

```
1234
```

## Person.name.full
Returns the full name of the launching user. Only available when launched by a logged in user.

Launch Parameter: *lis_person_name_full*

```
John Doe
```
## Person.name.family
Returns the last name of the launching user. Only available when launched by a logged in user.

Launch Parameter: *lis_person_name_family*

```
Doe
```

## Person.name.given
Returns the last name of the launching user. Only available when launched by a logged in user.

Launch Parameter: *lis_person_name_given*

```
John
```

## Person.email.primary
Returns the primary email of the launching user. Only available when launched by a logged in user.

Launch Parameter: *lis_person_contact_email_primary*

```
john.doe@example.com
```

## vnd.Canvas.Person.email.sis
Returns the institution assigned email of the launching user. Only available when launched by a logged in user that was added via SIS.

```
john.doe@example.com
```

## Person.address.timezone
Returns the name of the timezone of the launching user. Only available when launched by a logged in user.
```
America/Denver
```

## User.image
Returns the profile picture URL of the launching user. Only available when launched by a logged in user.

Launch Parameter: *user_image*

```
https://example.com/picture.jpg
```

## User.id [duplicates Canvas.user.id and Canvas.user.loginId]
Returns the Canvas user_id of the launching user. Only available when launched by a logged in user.

Launch Parameter: *user_id*

```
420000000000042
```

## Canvas.user.id [duplicates User.id and Canvas.user.loginId]
Returns the Canvas user_id of the launching user. Only available when launched by a logged in user.
```
420000000000042
```

## Canvas.user.prefersHighContrast
Returns the users preference for high contrast colors (an accessibility feature). Only available when launched by a logged in user.
```
false
```

## Canvas.group.contextIds
returns the context ids for the groups the user belongs to in the course.

```
1c16f0de65a080803785ecb3097da99872616f0d,d4d8d6ae1611e2c7581ce1b2f5c58019d928b79d,...
```

## Membership.role
Returns the <a href="https://www.imsglobal.org/specs/ltimemv1p0/specification-3">IMS LTI membership service</a> roles for filtering via query parameters. Only available when launched by a logged in user.

Launch Parameter: *roles*

```
http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator
```

## Canvas.xuser.allRoles [duplicates ext_roles which is sent by default]
Returns list of <a href="https://www.imsglobal.org/specs/ltiv1p0/implementation-guide#toc-16" target ="_blank">LIS role full URNs</a>.
Should always be available.
```
urn:lti:instrole:ims/lis/Administrator,urn:lti:instrole:ims/lis/Instructor,urn:lti:sysrole:ims/lis/SysAdmin,urn:lti:sysrole:ims/lis/User
```

## Canvas.user.globalId [duplicates Canvas.user.id and User.id]
Returns the canvas user_id of the launching user. Only available when launched by a logged in user.
```
420000000000042
```

## Canvas.user.isRootAccountAdmin
Returns true for root account admins and false for all other roles. Only available when launched by a logged in user.
```
true
```

## User.username [duplicates Canvas.user.loginId]
Username/Login ID for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
```
jdoe
```

## Canvas.user.loginId [duplicates User.username]
Returns the username/Login ID for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
```
jdoe
```

## Canvas.user.sisSourceId [duplicates Person.sourceId]
Returns the sis source id for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
```
sis_user_42
```

## Canvas.user.sisIntegrationId
Returns the integration id for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
```
integration_user_42
```

## Person.sourcedId [duplicates Canvas.user.sisSourceId]
Returns the sis source id for the primary pseudonym for the user for the account.
This may not be the pseudonym the user is actually logged in with. Only available when pseudonym is in use.
```
sis_user_42
```

## Canvas.logoutService.url
Returns the logout service url for the user.
This is the pseudonym the user is actually logged in as.
it may not hold all the sis info needed in other launch substitutions.
```
https://<domain>.instructure.com/api/lti/v1/logout_service/<external_tool_id>-<user_id>-<current_unix_timestamp>-<opaque_string>
```

## Canvas.masqueradingUser.id
Returns the Canvas user_id for the masquerading user.
Only available when the user is being masqueraded.
```
420000000000042
```


## Canvas.masqueradingUser.userId
Returns the 40 character opaque user_id for masquerading user.
Only available when the user is being masqueraded.
```
da12345678cb37ba1e522fc7c5ef086b7704eff9
```

## Canvas.xapi.url
Returns the xapi url for the user.
```
https://<domain>.instructure.com/api/lti/v1/xapi/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
```

## Caliper.url
Returns the caliper url for the user.
```
https://<domain>.instructure.com/api/lti/v1/caliper/<external_tool_id>-<user_id>-<course_id>-<current_unix_timestamp>-<opaque_id>
```

## Canvas.course.sectionIds
Returns a comma separated list of section_id's that the user is enrolled in.
Only available when launched from a course as an enrolled user.
```
42, 43
```

## Canvas.course.sectionSisSourceIds
Returns a comma separated list of section sis_id's that the user is enrolled in.
Only available when launched from a course as an enrolled user.
```
section_sis_id_1, section_sis_id_2
```

## Canvas.module.id
Returns the module_id that the module item was launched from.
Only available when content tag is present.
```
1234
```

## Canvas.moduleItem.id
Returns the module_item_id of the module item that was launched.
Only available when content tag is present.
```
1234
```

## Canvas.assignment.id
Returns the assignment_id of the assignment that was launched.
Only available when launched as an assignment.
```
1234
```

## Canvas.assignment.title
Returns the title of the assignment that was launched.
Only available when launched as an assignment.
```
Deep thought experiment
```

## Canvas.assignment.pointsPossible
Returns the points possible of the assignment that was launched.
Only available when launched as an assignment.
```
100
```

## Canvas.assignment.unlockAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.lockAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.dueAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.unlockAt.iso8601
Returns the unlock_at date of the assignment that was launched.
Only available when launched as an assignment.
```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.lockAt.iso8601
Returns the lock_at date of the assignment that was launched.
Only available when launched as an assignment.
```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.dueAt.iso8601
Returns the due_at date of the assignment that was launched.
Only available when launched as an assignment.
```
YYYY-MM-DDT07:00:00Z
```

## Canvas.assignment.published
Returns true if the assignment that was launched is published.
Only available when launched as an assignment.
```
true
```

## LtiLink.custom.url
Returns the endpoint url for accessing link-level tool settings
Only available for LTI 2.0
```
https://<domain>.instructure.com/api/lti/tool_settings/<link_id>
```

## ToolProxyBinding.custom.url
Returns the endpoint url for accessing context-level tool settings
Only available for LTI 2.0
```
https://<domain>.instructure.com/api/lti/tool_settings/<binding_id>
```

## ToolProxy.custom.url
Returns the endpoint url for accessing system-wide tool settings
Only available for LTI 2.0
```
https://<domain>.instructure.com/api/lti/tool_settings/<proxy_id>
```

## ToolConsumerProfile.url
Returns the <a href="https://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-46" target="_blank">Tool Consumer Profile</a> url for the tool.
Only available for LTI 2.0
```
https://<domain>.instructure.com/api/lti/courses/<course_id>/tool_consumer_profile/<opaque_id>
https://<domain>.instructure.com/api/lti/accounts/<account_id>/tool_consumer_profile/<opaque_id>
```


## Canvas.file.media.id
Only available when an attachment is present and it has either a media object or media entry id defined.

## Canvas.file.media.type
Only available when an attachment is present and has a media object defined.

## Canvas.file.media.duration
Only available when an attachment is present and has a media object defined.

## Canvas.file.media.size
Only available when an attachment is present and has a media object defined.

## Canvas.file.media.title
Only available when an attachment is present and has a media object defined.

## Canvas.file.usageRights.name
Only available when an attachment is present and has usage rights defined.

## Canvas.file.usageRights.url
Only available when an attachment is present and has usage rights defined.

## Canvas.file.usageRights.copyrightText
Only available when an attachment is present and has usage rights defined.
