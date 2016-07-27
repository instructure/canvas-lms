LTI Variable Substitutions
==========================

Variable substitution (aka variable expansion) is where custom variables really start to
shine.  They provide a mechanism for tool providers to request that specific, contextual
information be sent across in the launch.  When the tool consumer processes the launch request,
it detects requested variable substitutions and sends the appropriate data where possible.
Adding variable substitutions is exactly the same as adding custom variables, except the values
are variables instead of constants.  This is denoted by prefixing the value with a $.  If the
tool consumer doesn't recognize, or can't substitute, the value it will just send the variable
as if it were are regular custom variable.

This is a fairly new addition to our LTI feature set, but has allowed us to expose a lot of
data to LTI tools without asking them to go back to the Canvas API, which can be expensive
for us and them.  It allows tool providers to be much more surgical when requesting user
data, and it paves the way for us to be more transparent to tool installers, by showing them
exactly what data the LTI tool will be given access to.  On top of all that, variable
substitutions are generally simple to add to Canvas.

There are currently over 45 substitutions available.  Many of the substitutions simply
give access to additional user and context information.  An LTI tool can request things
like SIS ids, names, an avatar image, and an email address.  Other variable substitutions
assist tools with accessibility (prefersHighContrast), course copy (previousCourseIds), and
masquerading users.  Additionally, when we don't provide enough information or customizability
directly through LTI, tools can request everything they need to use the Canvas API for an even
richer experience.
## Canvas.api.domain
returns the canvas domain for the current context. Should always be available.

```
canvas.instructure.com
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
returns the account's sis source id for the current context. Should always be available.

## Canvas.rootAccount.id
returns the Root Account ID for the current context. Should always be available.

```
1234
```

## Canvas.rootAccount.sisSourceId
returns the root account's sis source id for the current context. Should always be available.

## Canvas.externalTool.url
returns the URL for the external tool that was launched. Only available for LTI 1.

```
http://example.url/path
```

## Canvas.css.common
returns the URL for the external tool that was launched. Should always be available.

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

## Canvas.course.sisSourceId
returns the current course sis source id. Only available when launched in a course.

```
1234
```

## Canvas.course.startAt
returns the current course start date. Only available when launched in a course.

```
1234
```

## Canvas.term.startAt
returns the current course's term start date. Only available when launched in a course that has a term with a start date.

```
1234
```

## CourseSection.sourcedId
returns the current course section sis source id. Only available when launched in a course.

```
1234
```

## Canvas.enrollment.enrollmentState
returns the current course enrollment state. Only available when launched in a course.

```
1234
```

## Canvas.membership.roles
returns the current course membership roles. Only available when launched from a course or an account.

```
1234
```

## Canvas.membership.concludedRoles
This is a list of IMS LIS roles should have a different key. Only available when launched in a course.

## Canvas.course.previousContextIds
returns the current course enrollment state. Only available when launched in a course.

```
1234
```

## Canvas.course.previousCourseIds
returns the current course enrollment state. Only available when launched in a course.

```
1234
```

## Person.name.full
Only available when launched by a logged in user.

## Person.name.family
Only available when launched by a logged in user.

## Person.name.given
Only available when launched by a logged in user.

## Person.email.primary
Only available when launched by a logged in user.

## Person.address.timezone
Only available when launched by a logged in user.

## User.image
Only available when launched by a logged in user.

## User.id
Only available when launched by a logged in user.

## Canvas.user.id
Only available when launched by a logged in user.

## Canvas.user.prefersHighContrast
Only available when launched by a logged in user.

## Canvas.group.contextIds
returns the context ids for the groups the user belongs to in the course.

```
1c16f0de65a080803785ecb3097da99872616f0d,d4d8d6ae1611e2c7581ce1b2f5c58019d928b79d,...
```

## Membership.role
Only available when launched by a logged in user.

## Canvas.xuser.allRoles
Should always be available.

## Canvas.user.globalId
Only available when launched by a logged in user.

## User.username
Substitutions for the primary pseudonym for the user for the account
This should hold all the SIS information for the user
This may not be the pseudonym the user is actually gingged in with. Only available when pseudonym is in use.

## Canvas.user.loginId
Only available when pseudonym is in use.

## Canvas.user.sisSourceId
Only available when pseudonym is in use.

## Canvas.user.sisIntegrationId
Only available when pseudonym is in use.

## Person.sourcedId
Only available when pseudonym is in use.

## Canvas.logoutService.url
This is the pseudonym the user is actually logged in as
it may not hold all the sis info needed in other launch substitutions.

## Canvas.masqueradingUser.id
Only available when the user is being masqueraded.

## Canvas.masqueradingUser.userId
Only available when the user is being masqueraded.

## Canvas.xapi.url


## Caliper.url


## Canvas.course.sectionIds
Only available when launched from a course.

## Canvas.course.sectionSisSourceIds
Only available when launched from a course.

## Canvas.module.id
Only available when content tag is present.

## Canvas.moduleItem.id
Only available when content tag is present.

## Canvas.assignment.id
Only available when launched as an assignment.

## Canvas.assignment.title
Only available when launched as an assignment.

## Canvas.assignment.pointsPossible
Only available when launched as an assignment.

## Canvas.assignment.unlockAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.lockAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.dueAt *[deprecated]*
deprecated in favor of ISO8601. Only available when launched as an assignment.

## Canvas.assignment.unlockAt.iso8601


## Canvas.assignment.lockAt.iso8601


## Canvas.assignment.dueAt.iso8601

## Canvas.assignment.published
Returns if the assignment is currently published as a boolean string value 'true', 'false'. Only available when launched as an assignment.

## LtiLink.custom.url


## ToolProxyBinding.custom.url


## ToolProxy.custom.url


## ToolConsumerProfile.url


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

