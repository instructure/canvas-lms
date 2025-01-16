# Privacy Level

> tl;dr
> A Canvas-specific extension to the LTI spec to support anonymous launches, plus some extras

### Possible values

- `anonymous` - send no user-identifying claims
  - **note:** this is called `Private` in the LTI Developer Key UI
- `name_only` - like anonymous, except send along only the user's name
- `email_only` - like anonymous, except send along the user's email
- `public` - send all user-identifying claims

### 1.1 Affected Fields

sent if privacy_level is `email_only` OR `public`:

- `lis_person_contact_email_primary`

sent if privacy_level is `name_only` OR `public`:

- `lis_person_name_given`
- `lis_person_name_family`
- `lis_person_name_full`

sent if privacy_level is `public`:

- `user_image`
- `custom_canvas_user_id`
- `lis_person_sourcedid`
- `custom_canvas_user_login_id`
- `custom_canvas_course_id` (for Course context)
- `custom_canvas_workflow_state` (for Course context)
- `lis_course_offering_sourcedid` (for Course context)
- `custom_canvas_account_id` (for Account or User context)
- `custom_canvas_account_sis_id` (for Account or User context)
- `custom_canvas_api_domain`
- `role_scope_mentor`

(none of these fields are sent if privacy_level is `anonymous`)

### 1.3 Affected Claims

sent if privacy_level is `email_only` OR `public`:

- `email`

sent if privacy_level is `name_only` OR `public`:

- `name`
- `given_name`
- `family_name`
- `https://purl.imsglobal.org/spec/lti/claim/lis`
  - `person_sourcedid`
  - `course_offering_sourcedid`

sent if privacy_level is `public`:

- `picture`
- `role_scope_mentor`

(none of these fields are sent if privacy_level is `anonymous`)

### NRPS Affected Fields

(specifically for the Member definition)

sent if privacy_level is `email_only` OR `public`:

- `email`

sent if privacy_level is `name_only` OR `public`:

- `name`
- `given_name`
- `family_name`
- `lis_person_sourcedid`

sent if privacy_level is `public`:

- `picture`

(none of these fields are sent if privacy_level is `anonymous`)

### External documentation

- for 1.1/External Tool API: `app/controllers/external_tools_controller.rb`
- for 1.3: `doc/api/lti_dev_key_config.md`

### Usage in code

The privacy level is stored on the ContextExternalTool in its `workflow_state` attribute, which was a little misguided since that also denotes whether the tool is disabled or deleted. That is a (relatively) easy thing to remedy by separating into its own column.

The ContextExternalTool has boolean-returning methods for each of the possible values: `include_email?`, `include_name?`, and `public?`. These methods are referenced in a few different places:

- `gems/lti_outbound/lib/lti_outbound/tool_launch.rb` - LTI 1.1 launches (technically references the LtiTool model, but that is populated by the ContextExternalTool)
- `lib/lti/messages/jwt_message.rb` - LTI 1.3 launches
- `app/serializers/lti/ims/names_and_roles_serializer.rb` - NRPS definitions

#### Installing an LTI 1.1 tool

##### Manually

The tool is created using the ExternalTool API, and the privacy_level is passed as a parameter and set directly on the tool.

##### Via XML Config

The tool is created using the ExternalTool API, and the `CC::Importer::BLTIConverter` transforms the provided `config_xml` to tool attributes. The privacy_level is taken from the `extensions` property of the XML as shown [here](../api/tools_xml.md).

#### Registering an LTI 1.3 tool

##### Via JSON Config

The user provides a JSON config in the Developer Keys UI, and saves the key. The tool is registered using a DeveloperKey and Lti::ToolConfiguration models. The privacy level is taken from the `extensions` property of the JSON tool configuration and stored in the Lti::ToolConfiguration's `privacy_level` column, and in its `settings` hash as well. During tool deployment (installation into a context), the `settings` hash is copied to the tool and the tool's workflow_state is set using the privacy_level.

##### Manually

The user fills out the form in the Developer Keys UI, including choosing between Public (`public`), and Private (`anonymous`) privacy levels. The privacy level is saved into the `extensions` property of the form's JSON state, and then is registered using the same flow as above.
