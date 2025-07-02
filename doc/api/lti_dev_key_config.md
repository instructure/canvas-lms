# Manually Configuring LTI Advantage Tools

<a name="top"></a>

<div class="warning-message">For versions of LTI previous to LTI 1.3, please
    refer to the <a href="file.tools_xml.html">older documentation</a></div>

For a successful launch to occur, LTI Advantage Tools require configuration
on both Canvas and inside the tool:

- [Manually Configuring LTI Advantage Tools](#manually-configuring-lti-advantage-tools)
- [Overview of an LTI Launch](file.lti_launch_overview.html)
- [Configuring Canvas in the Tool](#config-in-tool)
- [Configuring the Tool in Canvas](#config-in-canvas)
  - [Anatomy of a JSON configuration](#anatomy-of-a-json-configuration)

Overview of an LTI Launch <a name="launch-overview"></a>
=======================================

This section has moved to the [LTI Launch Overview page](file.lti_launch_overview.html).

Configuring Canvas in the Tool <a name="config-in-tool"></a>
=======================================
Tools will need to be aware of some Canvas-specific settings in order to accept a launch from Canvas and use the LTI Advantage Services:

- **Canvas Public JWKs**: When the tool receives the authentication response (<a href="file.lti_launch_overview.html#step-3" target="_blank">Step 3</a>), tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate that the request is actually coming from Canvas</a>. Canvas' public keys are environment-specific, but not domain-specific (the same key set can be used across all client accounts):
  - Production: `https://sso.canvaslms.com/api/lti/security/jwks`
  - Beta: `https://sso.beta.canvaslms.com/api/lti/security/jwks`
  - Test: `https://sso.test.canvaslms.com/api/lti/security/jwks`

    **Note:** The domain for this endpoint used to be `https://canvas.instructure.com`. The impetus for this change and other exact details are described in <a href="https://community.canvaslms.com/t5/The-Product-Blog/Minor-LTI-1-3-Changes-New-OIDC-Auth-Endpoint-Support-for/ba-p/551677" target="_blank">this Canvas Community article</a>. Tools wishing to implement the Platform Storage spec are required to use the new domain for this endpoint, and all other tools should update this endpoint in their configuration store as soon as possible. This change will eventually be enforced, but for now is not a breaking change - the old domain will continue to work. Any questions or issues are either addressed in the linked article or can be filed as a standard support/partner support case, referencing the OIDC Auth endpoint change.

- **Authorization Redirect URL**: The values and use of this are described in <a href="file.lti_launch_overview.html#step-2" target="_blank">Step 2</a>. Since the URL is static, you will want to configure this in your tool. Tools that wish to utilize <a href="file.lti_launch_overview.html#login-redirect" target="_blank">Step 1.5</a> need to include _all_ possible redirect URLs here.

- **Client ID**: The `client_id` of the Developer Key that's been configured in Canvas. Your tool will need to use this in the authentication response to Canvas (<a href="file.lti_launch_overview.html#step-2" target="_blank">Step 2</a>) and it is also used during the <a href="" target="_blank">Client Credentials Grant</a> to access <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">LTI Advantage Services</a>.

- **Deployment ID**: The `deployment_id` can be optionally configured in the tool. A single developer key may have many deployments, so the deployment ID can be used to identify which deployment is being launched. For more, refer to the LTI 1.3 core specification, <a href="https://www.imsglobal.org/spec/lti/v1p3/#lti_deployment_id-login-parameter" target="_blank">section 4.1.2</a>. The `deployment_id` in Canvas is exposed after a tool has been <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202" target="_blank">deployed using the `client_id`</a>.

Configuring the Tool in Canvas <a name="config-in-canvas"></a>
=======================================
With LTI Advantage, Canvas moved to using Developer Keys to store tool
configuration information. After a developer key is
<a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-LTI-key-for-an-account/ta-p/140" target="_blank">created and enabled</a>,
tools can be deployed to
<a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202" target="_blank">accounts/sub-accounts</a>
or <a href="https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-configure-an-external-app-for-a-course-using-a-client/ta-p/1071" target="_blank">courses</a>.

Developer Keys allow tools to set the required parameters to complete the
<a href="https://www.imsglobal.org/spec/security/v1p0#openid_connect_launch_flow"
target="_blank">OpenID Connect Launch Flow</a>, leverage
<a href="file.oauth.html#accessing-lti-advantage-services"
 target="_blank">LTI Advantage Services</a>, and configure other important settings.

With guidance from the tool developer, developer keys settings can be manually
entered by Account Admins. Tools providers can also supply Account Admins with
a JSON configuration or configuration URL containing the settings the tool
provider has verified to work.

In the manual case, since many of the extensions listed here require
more than a few lines of configuration, there is not currently an
interface for _every_ extension to be manually configured. Instead, we encourage
tool providers to expose a set of URL endpoints that return working
configuration options for their tool services.

If providing a URL configuration endpoint is not an option, you can also
provide your users with raw JSON that they can paste in for configuration.

## Anatomy of a JSON configuration

In this section, an example JSON configuration is shown followed by a table describing the
relevance of each field.

**NOTE**: Certain placement-specific settings may not be described here.
Some examples of JSON configuration snippets and placement-specific settings are
also found in the placements sub-menu in the left-navigation of this documentation.

```json
{
  "title": "The Best Tool",
  "description": "1.3 Test Tool used for documentation purposes.",
  "oidc_initiation_url": "https://your.oidc_initiation_url",
  "oidc_initiation_urls": {
    "eu-west-1": "https://your.eu-specific1.oidc_initiation_url",
    "eu-central-1": "https://your.eu-specific2.oidc_initiation_url"
  },
  "target_link_uri": "https://your.target_link_uri",
  "scopes": [
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
    "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"
  ],
  "extensions": [
    {
      "domain": "thebesttool.com",
      "tool_id": "the-best-tool",
      "platform": "canvas.instructure.com",
      "privacy_level": "public",
      "settings": {
        "text": "Launch The Best Tool",
        "labels": {
          "en": "Launch The Best Tool",
          "en-AU": "G'day, Launch The Best Tool",
          "es": "Lanzar la mejor herramienta",
          "zh-Hans": "启动最佳工具"
        },
        "icon_url": "https://some.icon.url/tool-level.png",
        "selection_height": 800,
        "selection_width": 800,
        "placements": [
          {
            "text": "User Navigation Placement",
            "icon_url": "https://some.icon.url/my_dashboard.png",
            "placement": "user_navigation",
            "message_type": "LtiResourceLinkRequest",
            "target_link_uri": "https://your.target_link_uri/my_dashboard",
            "canvas_icon_class": "icon-lti",
            "custom_fields": {
              "foo": "$Canvas.user.id"
            }
          },
          {
            "text": "Editor Button Placement",
            "icon_url": "https://some.icon.url/editor_tool.png",
            "placement": "editor_button",
            "message_type": "LtiDeepLinkingRequest",
            "target_link_uri": "https://your.target_link_uri/content_selector",
            "selection_height": 500,
            "selection_width": 500
          },
          {
            "text": "Course Navigation Placement",
            "icon_url": "https://static.thenounproject.com/png/131630-200.png",
            "placement": "course_navigation",
            "message_type": "LtiResourceLinkRequest",
            "target_link_uri": "https://your.target_link_uri/launch?placement=course_navigation",
            "required_permissions": "manage_calendar",
            "selection_height": 500,
            "selection_width": 500
          }
        ]
      }
    }
  ],
  "public_jwk": {
    "kty": "RSA",
    "alg": "RS256",
    "e": "AQAB",
    "kid": "8f796169-0ac4-48a3-a202-fa4f3d814fcd",
    "n": "nZD7QWmIwj-3N_RZ1qJjX6CdibU87y2l02yMay4KunambalP9g0fU9yZLwLX9WYJINcXZDUf6QeZ-SSbblET-h8Q4OvfSQ7iuu0WqcvBGy8M0qoZ7I-NiChw8dyybMJHgpiP_AyxpCQnp3bQ6829kb3fopbb4cAkOilwVRBYPhRLboXma0cwcllJHPLvMp1oGa7Ad8osmmJhXhM9qdFFASg_OCQdPnYVzp8gOFeOGwlXfSFEgt5vgeU25E-ycUOREcnP7BnMUk7wpwYqlE537LWGOV5z_1Dqcqc9LmN-z4HmNV7b23QZW4_mzKIOY4IqjmnUGgLU9ycFj5YGDCts7Q",
    "use": "sig"
  },
  "custom_fields": {
    "bar": "$Canvas.user.sisid"
  }
}
```

<a name="request-params"></a>

<table class="request-params">
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-req"></th>
      <th class="param-type">Type</th>
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
<!-- title -->
    <tr class="request-param">
      <td>title</td>
      <td>
        Required
      </td>
      <td>string</td>
      <td class="param-desc">
<p>The default name of the tool in the app index. This value is also displayed if no "text" field is provided within extension settings or placements.</p>
      </td>
    </tr>
<!-- description -->
    <tr class="request-param">
      <td>description</td>
      <td>
                Required
      </td>
      <td>string</td>
      <td class="param-desc">
<p>A description of the tool.</p>
      </td>
    </tr>
<!-- oidc_initiation_url -->
    <tr class="request-param">
      <td>oidc_initiation_url</td>
      <td>
        Required
      </td>
      <td>string</td>
      <td class="param-desc">
<p>The <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">login initiation url</a> that Canvas should redirect the User Agent to.
      </td>
    </tr>
<!-- oidc_initiation_urls -->
    <tr class="request-param">
      <td><a name="param-oidc-initial-urls"></a>oidc_initiation_urls</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
<p>Optional region-specific <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">login initiation urls</a> that Canvas should redirect the User Agent to. Each institution's Canvas install lives in a particular AWS region, typically one close to the institution's physical region. If this AWS region is listed as a key in this object, the URL in the value will override the default `oidc_initiation_url`. As of 2023, the regions used by Canvas are: us-east-1, us-west-2, ca-central-1, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2.
      </td>
    </tr>
<!-- target_link_uri -->
    <tr class="request-param">
      <td>target_link_uri</td>
      <td>
        Required
      </td>
      <td>string</td>
      <td class="param-desc">
<p>The <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">target_link_uri</a> that Canvas should pass in the to the login initiation endpoint. This allows tools to determine which redirect_uri to pass Canvas in the authorization redirect request and should be <a href="https://www.imsglobal.org/spec/lti/v1p3/impl#verify-the-target_link_uri" target="_blank">verified during the final
launch</a>. This can be set at the tool-level, or within the "placements" JSON
object for placement-specific target_link_uri's.</p>
      </td>
    </tr>
<!-- scopes -->
    <tr class="request-param">
      <td>scopes</td>
      <td>
      </td>
      <td>string array</td>
      <td class="param-desc">
<p>The comma separated list of scopes to be allowed when using the
    <a href="file.oauth.html#accessing-lti-advantage-services">client_credentials
     grant to access LTI services</a>.
     <p class="param-values">
          <span class="allowed">Allowed values:</span>
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/score"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"</code>,
          <code class="enum">"https://purl.imsglobal.org/spec/lti/scope/noticehandlers"</code>,
          <code class="enum">"https://canvas.instructure.com/lti/public_jwk/scope/update"</code>
     </p>
</p>
      </td>
    </tr>
<!-- extensions -->
    <tr class="request-param">
      <td>extensions</td>
      <td>
      </td>
      <td>array of JSON objects</td>
      <td class="param-desc">
<p>The set of Canvas extensions, including placements, that the tool should use. [See extensions parameters below.](#extension-params)</p>
      </td>
    </tr>


<!-- environments -->
    <tr class="request-param">
      <td>environments</td>
      <td>
        <strong style="color: red;">Ignored</strong>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
        <p>LTI 1.1 tools <a href="file.tools_xml.html">support environment-specific domains and launch urls</a>, used for launching
        from beta or test instances of Canvas. This config option is not supported for LTI 1.3. Tools instead should use the
        <code>canvas_environment</code> parameter of the OIDC Login request to redirect to environment-specific launch urls or
        instances of the tool, as specified in <a href="file.lti_dev_key_config.html#login-redirect">Step 1.5</a> above, and/or
        use the region-specific <a href="#param-oidc-initial-urls">oidc_initiation_urls</a>.
        </p>
      </td>
    </tr>
<!-- public_jwk -->
    <tr class="request-param">
      <td>public_jwk</td>
      <td>
          required, see notes
      </td>
      <td>JSON object</td>
      <td class="param-desc">
<p>Required if public_jwk_url is omitted. The tools <a href="https://www.imsglobal.org/spec/lti/v1p3/impl/#tool-s-jwk-set" target="_blank">public key</a> to be used during the client_credentials grant for <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">accessing LTI Advantage services</a>.</p>
      </td>
    </tr>
<!-- public_jwk_url -->
    <tr class="request-param">
      <td>public_jwk_url</td>
      <td>
          required, see notes
      </td>
      <td>string</td>
      <td class="param-desc">
<p>Required if public_jwk is omitted. The tools <a href="https://www.imsglobal.org/spec/lti/v1p3/impl/#tool-s-jwk-set" target="_blank">public key uri</a> to be used during the client_credentials grant for <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">accessing LTI Advantage services</a>.</p>
      </td>
    </tr>
<!-- custom_fields -->
    <tr class="request-param">
      <td>custom_fields</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
<p>Custom fields that will be sent to the tool consumer; can be set at the tool-level or within the "placement" JSON object for placement-specific custom fields. When the tool is launched, all custom fields will be sent to the tool as strings. Read more about <a href="file.tools_variable_substitutions.html" target="_blank">variable substitutions in custom fields.</a></p>
      </td>
    </tr>
  </tbody>
</table>

<a name="extension-params"></a>

### Extensions

The following fields can be put under `extensions`:

<table class="request-params">
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-req"></th>
      <th class="param-type">Type</th>
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class="request-param">
      <td>domain</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The domain Canvas should use to match clicked LTI links against. This is recommended if <a href="file.content_item.html">deep linking</a> is used.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>tool_id</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>Allows tools to set a unique identifier for the tool.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>platform</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The LMS platform that the extensions belong to. This should always be set to "canvas.instructure.com" for cloud-hosted Canvas.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>privacy_level</td>
      <td>
        Required
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>What level of user information to send to the external tool. Setting this to "name_only" will include fields that contain the user's name and sourcedid in the launch claims. "email_only" will include only the user's email. "public" includes all fields from "name_only", "email_only", and fields like the user's picture. "anonymous" will not include any of these fields. Note that the "sub" claim containing the user's ID is always included.</p>
        <p class="param-values">
          <span class="allowed">Allowed values:</span>
          <code class="enum">anonymous</code>, <code class="enum">public</code>
          <code class="enum">name_only</code>, <code class="enum">email_only</code>
        </p>
      </td>
    </tr>
    <tr class="request-param">
      <td>settings</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
        <p>The set of platform-specific settings to be used. <a href="#settings-params">See settings parameters below.</a></p>
      </td>
    </tr>
  </tbody>
</table>

<a name='settings-params'></a>

<h3>Settings</h3>

<p>The following can be put under <code>extensions.settings</code>:</p>

<table class="request-params">
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-req"></th>
      <th class="param-type">Type</th>
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class="request-param">
      <td>custom_fields</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
<p>Custom fields that will be sent to the tool consumer; can be set at the tool-level or within the "placement" JSON object for placement-specific custom fields. When the tool is launched, all custom fields will be sent to the tool as strings. Read more about <a href="file.tools_variable_substitutions.html" target="_blank">variable substitutions in custom fields.</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>icon_url</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The url of the icon to show for this tool. Can be set within the "settings" object for tool-level icons, or in the "placement" object for placement-specific icons. NOTE: Not all placements display an icon.</p>
    <tr class="request-param">
      <td>labels</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
        <p>An object for translations of the "text", used to support internationalization (i18n) / localization (l10n). If the user's Canvas interface is set to one of the languages listed, the tool will display the translated text in place of the value in the "text" field. This JSON object is in the format <code>{"en": "Name", "es": "Nombre"}</code>, where "en" and "es" are IETF language tags. More specific locales ("en-AU") are preferred over less specific ones ("en").  A partial list of language tags can be found <a href="https://en.wikipedia.org/wiki/IETF_language_tag#List_of_common_primary_language_subtags" target="_blank">here</a>. Can be set within "settings" or individual placements.
</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>placements</td>
      <td>
      </td>
      <td>array of JSON objects</td>
      <td class="param-desc">
<p>Settings to be used for specific tool placements. Values given in this <code>settings.placements</code> array will override the value given in the `settings` object for that particular placement. <a href="#placements-params">See placements parameters below.</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>required_permissions</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>Limits tool visibility to users with certain permissions, as defined on the user's built-in Canvas user roles AND the custom roles that you may have created in Canvas. This is a comma-separated string of one or more required permissions, such as <code>manage_groups_add,manage_groups_delete</code> or <code>read_outcomes</code>. The tool will be hidden for users without all specified permissions. If set in placement-specific settings, that placement will be hidden; if set at the tool-level (e.g. under <code>extensions[0]</code>), each of the tool's placements will be hidden. For true access control, please use (instead or in addition) the <a href="file.tools_variable_substitutions.html#Canvas-membership-permissions">Canvas.membership.permissions&lt;&gt;</a> custom variable expansion, and check its value in your tool. To learn more about roles and permissions, and to see the permissions available for this parameter, visit the <a href="roles.html" target="_blank">Roles API docs</a>.
        </p>
      </td>
    </tr>
    <tr class="request-param">
      <td>selection_height</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The display height of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>
    <tr class="request-param">
      <td>selection_width</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The display width of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>text</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The default text to show for this tool. Can be set within "settings" for the tool-level display text, or within "placements" object for placement-specific display text.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name='placements-params'></a>

### Placements

The following can be put under `extensions.settings.placements`. (Note: `extensions.settings.placements` is an array of JSON objects. This table shows the values that can be in those JSON objects.) Values given for a placement in this array will override the value given in `extensions.settings`.

<table class='request-params'>
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-req"></th>
      <th class="param-type">Type</th>
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class="request-param">
      <td>placement</td>
      <td>Required</td>
      <td>string</td>
      <td class="param-desc">
<p>Name of the placement that this settings object should apply to. <a href="file.placements_overview.html">See full list of placements here.</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>custom_fields</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
<p>Custom fields that will be sent to the tool consumer; can be set at the tool-level or within the "placement" JSON object for placement-specific custom fields. When the tool is launched, all custom fields will be sent to the tool as strings. Read more about <a href="file.tools_variable_substitutions.html" target="_blank">variable substitutions in custom fields.</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>enabled</td>
      <td>
      </td>
      <td>boolean</td>
      <td class="param-desc">
<p>Optional, defaults to `true`. Determines if the placement is enabled.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>icon_url</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The url of the icon to show for this tool. Can be set within the "settings" object for tool-level icons, or in the "placement" object for placement-specific icons. NOTE: Not all placements display an icon.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>labels</td>
      <td>
      </td>
      <td>JSON object</td>
      <td class="param-desc">
        <p>An object for translations of the "text", used to support internationalization (i18n) / localization (l10n). If the user's Canvas interface is set to one of the languages listed, the tool will display the translated text in place of the value in the "text" field. This JSON object is in the format <code>{"en": "Name", "es": "Nombre"}</code>, where "en" and "es" are IETF language tags. More specific locales ("en-AU") are preferred over less specific ones ("en").  A partial list of language tags can be found <a href="https://en.wikipedia.org/wiki/IETF_language_tag#List_of_common_primary_language_subtags" target="_blank">here</a>. Can be set within "settings" or individual placements.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>message_type</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The IMS message type to be sent in the launch. This is set at the placement level. Not all placements support both message_types.
          <p class="param-values">
           <span class="allowed">Allowed values:</span>
           <code class="enum">"LtiResourceLinkRequest"</code>,
           <code class="enum">"LtiDeepLinkingRequest"</code>
          </p>
        </p>
      </td>
    </tr>
    <tr class="request-param">
      <td>required_permissions</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>Limits tool visibility to users with certain permissions, as defined on the user's built-in Canvas user roles AND the custom roles that you may have created in Canvas. This is a comma-separated string of one or more required permissions, such as <code>manage_groups_add,manage_groups_delete</code> or <code>read_outcomes</code>. The tool will be hidden for users without all specified permissions. If set in placement-specific settings, that placement will be hidden; if set at the tool-level (e.g. under <code>extensions[0]</code>), each of the tool's placements will be hidden. For true access control, please use (instead or in addition) the <a href="file.tools_variable_substitutions.html#Canvas-membership-permissions">Canvas.membership.permissions&lt;&gt;</a> custom variable expansion, and check its value in your tool. To learn more about roles and permissions, and to see the permissions available for this parameter, visit the <a href="roles.html" target="_blank">Roles API docs</a>.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>selection_height</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The display height of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>selection_width</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The display width of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>text</td>
      <td>
      </td>
      <td>string</td>
      <td class="param-desc">
        <p>The default text to show for this tool. Can be set within "settings" for the tool-level display text, or within "placements" object for placement-specific display text.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="placement-specific-settings"></a>

### Placement-specific Settings

The following settings only apply to certain placements.

<table class='request-params'>
  <thead>
    <tr>
      <th class="param-name">Parameter</th>
      <th class="param-name">Placement</th>
      <th class="param-type">Type</th>
      <th class="param-desc">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class="request-param">
      <td>accept_media_types</td>
      <td>file_menu</td>
      <td>string</td>
      <td class="param-desc">
<p>A comma-separated list of MIME types, e.g.: <code>"image/jpeg,image/png"</code>. The LTI tool will be shown in the file_menu placement if the file's MIME type matches one of the MIME types in the list. <a href="file.placements_overview.html#file-menu" target="_blank">(Screenshot of the file_menu placement.)</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>default</td>
      <td>account_navigation, course_navigation</td>
      <td>string</td>
      <td class="param-desc">
        <p>Whether the tool should be shown in the sidebar.</p>
        <p class="param-values">
          <span class="allowed">Allowed values:</span>
          <code class="enum">enabled</code>, <code class="enum">disabled</code>
        </p>
      </td>
    </tr>
    <tr class="request-param">
      <td>icon_svg_path_64</td>
      <td>global_navigation</td>
      <td>string</td>
      <td class="param-desc">
<p>An SVG path to be used for the tool's icon in the global_navigation placement. Note: this should be the SVG path itself, not a URL to an SVG image. The value of this parameter will be used as the <code>d</code> attribute on the SVG's <code>path</code> element. <a href="https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d" target="_blank">See MDN for more information.</a></p>
      </td>
    </tr>
    <tr class="request-param">
      <td>use_tray</td>
      <td>editor_button</td>
      <td>boolean</td>
      <td class="param-desc">
<p>Whether the tool should open in the tray (a.k.a. sidebar) rather than a modal window. <code>True</code> means to use the tray, <code>false</code> means to use a modal window. The tray allows the user to still interact with the page while the tray is open; the modal window blocks the rest of the page while the modal window is open.</p>
      </td>
    </tr>
    <tr class="request-param">
      <td>windowTarget</td>
      <td>account_navigation, course_navigation, global_navigation, user_navigation</td>
      <td>string</td>
      <td class="param-desc">
        <p>Whether the tool should be launched in a new tab.</p>
        <p class="param-values">
          <span class="allowed">Allowed values:</span>
          <code class="enum">_blank</code>
        </p>
      </td>
    </tr>
  </tbody>
</table>
