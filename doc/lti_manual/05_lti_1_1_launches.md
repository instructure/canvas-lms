# LTI 1.1 Launches
See [the LTI launches document](./03_lti_launches.md) document for an overview of all LTI version launches.
## Overview
An LTI 1.1 launch is a single form post from the tool consumer to the tool provider. The tool responds to the form post with HTML. This HTML is the tool's UI and is rendered in a Canvas iframe or a new tab (depending on the context).

## Parameters
Parameters sent in the LTI launch help the tool provider identify the current user, context, and other relevant details.

There are three categories of parameters:
1. Standard parameters - the parameters defined in the specification. Sent by default in most LTI 1.1 launches.
2. Extension parameters - parameters not defined in the specification, but sent by default in most LTI 1.1 launches. These parameters begin with the `ext_` prefix.
3. Custom parameters - these are parameters can be either defined in the standard, or not. They must be specifically requested by the tool provider in the configuration XML in order to be sent in the launch. See [custom parameters](./08_custom_parameters.md) for more details.

As noted above, the first and second types of parameters are sent by default in _most_ LTI 1.1 launches, but not all. The set of parameters sent in the LTI 1.1 launch is determined by the "privacy level" of the tool.

There are four privacy levels that determine which standard and extension parameters as sent by default in a tool. The privacy level is determined by the `workflow_state` of the `ContextExternalTool` being launched:

### Public (`workflow_state == 'public'`)
This is the tier that send all standard and extend parameters + any custom parameters the tool provider has requested in their configuration (See [tool installation](./02_tool_installation.md)).

When the tool's privacy level is public, the LTI launch will include all standard and extension parameters. This includes parameters that include user PII. For example:

- `lis_person_name_full` (full name)
- `lis_person_contact_email_primary` (email address)
- `user_image` (user's avatar)
- etc.

### Email Only (`workflow_state == 'email_only'`)
The only PII sent in LTI 1.1 launches for this tier of privacy is the email address:

`lis_person_contact_email_primary` (email address)

Other PII values are not sent in the request.

### Name Only (`workflow_state = 'name_only`)
The only PII sent in the LTI 1.1 launches for this tier of privacy is name-related parameters:
- `lis_person_name_given`
- `lis_person_name_family`
- `lis_person_name_full`

### Anonymous (`workflow_state = 'anonymous'`)
No PII is sent in the LTI 1.1 launch in this privacy mode.

Note that a opaque, unique identifier is still sent.

## Authentication
LTI 1.1 uses [OAuth 1 request signing](https://oauth1.wp-api.org/docs/basics/Signing.html), which allows the tool provider to verify a trusted party sent the LTI launch. The client ID and secret for this signing is set up at installation time (See [Tool Installations](./02_tool_installation.md)).

## Resources
- [LTI 1.1 Implementation Guide](https://www.imsglobal.org/specs/ltiv1p1/implementation-guide)
- [LTI 1.1 Introduction](https://www.eduappcenter.com/docs/basics/index)