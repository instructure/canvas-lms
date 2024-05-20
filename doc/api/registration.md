# Registering an LTI Tool

<!-- Introduction & motivation -->

In order to enable an Administrator to install an application in Canvas, a tool can support the
automated registration process, built on the Dynamic Registration specification mentioned
[here](https://www.imsglobal.org/activity/learning-tools-interoperability-lti%C2%AE). This
replaces the [manual configuration](file.lti_dev_key_config.html) process
previously used to install applications to Canvas.

<!-- Overview -->

## Overview

The automated registration process allows tools to install themselves into Canvas automatically
without requiring an Administrator to manually enter configuration values. Tools provide a Canvas
administrator with a pre-determined URL, which the user enters into Canvas. Canvas will direct the
user to that URL, where the tool can request Canvas' OpenID configuration and provide the user with
an installation UI, where they can choose tool-specific settings. The tool then installs itself using
a registration token to access the registration REST JSON service. After installing, the user is
returned to Canvas to confirm the installation and enable the tool.

<!-- Technical Diagram -->

![Dynamic Registration Sequence Diagram](./images/dynamic-registration-sequence-diagram.png)

<!-- Initiation Request -->

## Initiation Request

The first part of the registration process is the registration initiation request. When an administrator
enters the tool's dynamic registration URL, Canvas redirects the user with a GET request by embedding an
iframe pointed to that URL with two parameters added, `openid_configuration`, and `registration_token`.
The `openid_configuration` parameter contains the URL that the tool can use to retrieve Canvas' OpenID
Configuration, and the `registration_token` parameter is the token used to access that URL.

At the registration initiation url, the tool should show a UI that guides the user through setting up a registration. This
can include deployment-specific options for the tool. The tool can also guard this UI with a login, access
code, or some other form of authentication, since the dynamic registration URL is meant to be shared publicly.

<!-- Canvas OpenID Configuration -->

## Canvas OpenID Configuration

During registration, the tool can request Canvas' OpenID configuration by sending a `GET` request to the url
included in the `openid_configuration` redirect url. The tool also needs to include the `registration_token`
in the `GET` request, as the bearer token in the `Authorization` http header:

```sh
curl -v https://canvas.instructure.com/api/lti/security/openid-configuration \
  -H "Accept: application/json" \
  -H "Authorization: Bearer {registration_token}"
```

Canvas' Open ID configuration contains details about itself that the tool can use to make decisions. It contains
claims supported, message types, placements, variables, and information about the account the administrator is
installing the tool into.

A example response looks like:

```json
{
  "issuer": "http://canvas.instructure.com",
  "authorization_endpoint": "http://canvas.instructure.com/api/lti/authorize_redirect",
  "registration_endpoint": "http://canvas.instructure.com/api/lti/registrations",
  "jwks_uri": "http://canvas.instructure.com/login/oauth2/jwks",
  "token_endpoint": "http://canvas.instructure.com/login/oauth2/token",
  "token_endpoint_auth_methods_supported": ["private_key_jwt"],
  "token_endpoint_auth_signing_alg_values_supported": ["RS256"],
  "scopes_supported": [
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly",
    "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
    "https://purl.imsglobal.org/spec/lti-ags/scope/score",
    "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly",
    "https://canvas.instructure.com/lti/public_jwk/scope/update",
    "https://canvas.instructure.com/lti/account_lookup/scope/show",
    "https://canvas.instructure.com/lti-ags/progress/scope/show"
  ],
  "response_types_supported": ["id_token"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "claims_supported": [
    "sub",
    // ... more here
    "locale"
  ],
  "subject_types_supported": ["public"],
  "authorization_server": "canvas.instructure.com",
  "https://purl.imsglobal.org/spec/lti-platform-configuration": {
    "product_family_code": "canvas",
    "version": "vCloud",
    "messages_supported": [
      {
        "type": "LtiResourceLinkRequest",
        "placements": [
          "account_navigation",
          // ... more here
          "wiki_page_menu"
        ]
      },
      {
        "type": "LtiDeepLinkingRequest",
        "placements": [
          "assignment_selection",
          // ... more here
          "submission_type_selection"
        ]
      }
    ],
    "variables": [
      "ResourceLink.id",
      // ... more here
      "Canvas.environment.test"
    ],
    "https://canvas.instructure.com/lti/account_name": "Test University",
    "https://canvas.instructure.com/lti/account_lti_guid": "pNu5F9EoIATW6XqZ33C5tiqomb7bFJ4IGWFoCFy6:canvas-lms"
  }
}
```

<!-- Registration Request -->

## Registration Creation

Canvas includes a URL in the OpenID configuration under the `registration_endpoint` key which can be used
by the tool to create a registration. The tool must send a `POST` request to this endpoint with the tool's
[LTI Registration](#lti-registration-schema) in the body and the `registration_token` as the bearer token
in the `Authorization` http header.

An example request looks like:

```shell
curl \
  --header "Content-Type: application/json" \
  --request POST \
  --data '<lti_registration_body>' \
  http://canvas.instructure.com/api/lti/registrations
```

#### LTI Registration schema

| Name                                                                | Type                                                     | Required | Description                                                                          |
| ------------------------------------------------------------------- | -------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| application_type                                                    | "web"                                                    | yes      |                                                                                      |
| grant_types                                                         | ["client_credentials", "implicit"]                       | yes      |                                                                                      |
| initiate_login_uri                                                  | string                                                   | yes      | The url that Canvas should use to initiate an LTI launch request                     |
| redirect_uris                                                       | string                                                   | yes      | Any urls that the tool can launch to.                                                |
| response_types                                                      | "id_token"                                               | yes      |                                                                                      |
| client_name                                                         | string                                                   | yes      | The name of the tool as it will appear to Administrators maintaining the integration |
| jwks_uri                                                            | string                                                   | yes      | The url of the tool's JSON Web Key Set                                               |
| token_endpoint_auth_method                                          | "private_key_jwt"                                        | yes      |                                                                                      |
| scope                                                               | string                                                   | yes      | A space-separated list of scopes the tool requests access to.                        |
| ht<span>tps://</span>purl.imsglobal.org/spec/lti-tool-configuration | [Lti Tool Configuration](#lti-tool-configuration-schema) | yes      | none                                                                                 |

#### LTI Tool Configuration schema

| Name                                                          | Type                                                               | Required | Description                                                                                             |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------------------------- |
| domain                                                        | string                                                             | yes      | The primary domain used by this tool.                                                                   |
| secondary_domains                                             | Array<string>                                                      | no       | Additional domains used by this tool.                                                                   |
| target_link_uri                                               | string                                                             | yes      | The default launch url if not defined in a message                                                      |
| custom_parameters                                             | JSON object                                                        | no       | Custom parameters to be included in each launch. Values must be a string                                |
| description                                                   | string                                                             | no       | A short description of the tool.                                                                        |
| messages                                                      | Array<[message](#lti-message-schema)>                              | yes      | Messages supported by the tool.                                                                         |
| claims                                                        | Array<string>                                                      | yes      | An array of claims to be included in each launch token.                                                 |
| ht<span>tps://</span>canvas.instructure.com/lti/privacy_level | "public" &#124; "name_only" &#124; "email_only" &#124; "anonymous" | no       | The tool's default privacy level, (determines the PII fields the tool is sent.) defaults to "anonymous" |

#### LTI Message schema

| Name                                                                              | Type                                                    | Required | Description                                                                                                                                                                                                                                                                                                                                                                                     |
| --------------------------------------------------------------------------------- | ------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| type                                                                              | "LtiResourceLinkRequest" &#124; "LtiDeepLinkingRequest" | yes      | The message type.                                                                                                                                                                                                                                                                                                                                                                               |
| target_link_uri                                                                   | string                                                  | no       | The URL to launch to.                                                                                                                                                                                                                                                                                                                                                                           |
| label                                                                             | string                                                  | no       | The user-facing label to show when launching a tool.                                                                                                                                                                                                                                                                                                                                            |
| icon_uri                                                                          | string                                                  | no       | URL to an icon that will be added to the link (only for applicable placements)                                                                                                                                                                                                                                                                                                                  |
| custom_parameters                                                                 | JSON object                                             | no       | Custom parameters to be included in each launch. Values must be a string                                                                                                                                                                                                                                                                                                                        |
| placements                                                                        | Array<string>                                           | no       | An array of placements to apply to this launch                                                                                                                                                                                                                                                                                                                                                  |
| ht<span>tps://</span>canvas.instructure.com/lti/course_navigation/default_enabled | boolean                                                 | no       | Only applies if the placement is "course_navigation". If false, the tool will not appear in the course navigation bar, but can still be re-enabled by admins and teachers. Defaults to 'true'. See the "default" setting as discussed in the [Navigation Tools](file.navigation_tools.html#settings) docs.                                                                                      |
| ht<span>tps://</span>canvas.instructure.com/lti/visibility                        | "admins" &#124; "members" &#124; "public"               | no       | Determines what users can see a link to launch this message. The "admins" value indicates users that can manage the link can see it, which for the Global Navigation placement means administrators, but in courses means administrators and instructors. The "members" value indicates that any member of the context the link appears in can see the link, and "public" means visible to all. |

example LTI Registration body:

```json
{
  "application_type": "web",
  "client_name": "Lti Tool",
  "client_uri": "http://tool.com",
  "grant_types": ["client_credentials", "implicit"],
  "jwks_uri": "http://tool.com/jwks",
  "initiate_login_uri": "http://tool.com/login",
  "redirect_uris": ["http://tool.com/launch"],
  "response_types": ["id_token"],
  "scope": "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly",
  "token_endpoint_auth_method": "private_key_jwt",
  "logo_uri": "http://tool.com/icon.svg",
  "https://purl.imsglobal.org/spec/lti-tool-configuration": {
    "claims": [
      "sub",
      "iss",
      "name",
      "given_name",
      "family_name",
      "nickname",
      "picture",
      "email",
      "locale"
    ],
    "custom_parameters": {},
    "domain": "tool.com",
    "messages": [
      {
        "type": "LtiResourceLinkRequest",
        "icon_uri": "http://tool.com/icon.svg",
        "label": "Lti Tool",
        "custom_parameters": {
          "foo": "bar",
          "context_id": "$Context.id"
        },
        "placements": ["course_navigation"],
        "roles": [],
        "target_link_uri": "http://tool.com/launch?placement=course_navigation"
      }
    ],
    "target_link_uri": "http://tool.com/launch",
    "https://canvas.instructure.com/lti/privacy_level": "public"
  }
}
```

#### Registration Response

Upon successful creation, the registration endpoint will respond with the created registration, along with an additional field, `client_id`:

```json
{
  "application_type": "web",
  "client_name": "Lti Tool",
  ...
  "client_id": "10000000000001"
}
```

The tool will use this `client_id` when requesting tokens and accessing LTI Services.

#### Returning the Administrator to Canvas

After the registration is created successfully, the tool should return the user to Canvas by sending a post message to the parent Canvas window:

```js
window.parent.postMessage({subject: 'org.imsglobal.lti.close'}, '*')
```

Canvas will listen for this message and close the iframe, presenting the user with a summary of the registration the tool returned. The administrator will then be able to make some modifications to the registration. It's important to note that these modifications may alter how the tool is finally configured and launched. For example, the tool may request a certain number of scopes, but the administrator could restrict access to certain scopes. The tool should detect this and warn the user if modifications need to be made to the configuration.
