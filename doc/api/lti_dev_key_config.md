# Manually Configuring LTI Advantage Tools

<a name="top"></a>

<div class="warning-message">For versions of LTI previous to LTI 1.3, please
    refer to the <a href="file.tools_xml.html">older documentation</a></div>

For a successful launch to occur, LTI Advantage Tools require configuration
on both Canvas and inside the tool:

- [Manually Configuring LTI Advantage Tools](#configuring-lti-advantage-tools)
- [Overview of an LTI Launch](#overview-of-an-lti-launch)
- [Configuring Canvas in the Tool](#configuring-canvas-in-the-tool)
- [Configuring the Tool in Canvas](#configuring-the-tool-in-canvas)
  - [Anatomy of a JSON configuration](#anatomy-of-a-json-configuration)

But first, the importance of each configuration setting can only be understood
with a basic understanding of how an LTI launch occurs.

<a name="launch-overview"></a>
Overview of an LTI Launch
=======================================
The <a href="http://www.imsglobal.org/spec/security/v1p0/" target="_blank">IMS Security Framework</a> uses an
<a href="http://www.imsglobal.org/spec/security/v1p0/#openid_connect_launch_flow" target="_blank">Open ID Connect (OIDC)</a> third-party flow. You'll want to read these specifications in detail, but the following is a Canvas-specific summary:

<a name="step-1"></a>
###Step 1: Login Initiation
Canvas <a href="http://www.imsglobal.org/spec/security/v1p0/#step-1-third-party-initiated-login" target="_blank">initiates a login request</a> to the `oidc_initiation_url` that is <a href="#config-in-canvas">configured on the LTI developer key</a>. This requests contains an issuer identifier (`iss`) to recognize Canvas is launching the tool. As the issuer, Instructure-hosted Canvas instances all use the following, regardless of the specific account domain(s) that the tool was launched from:

- https://canvas.instructure.com (Production environment launches)
- https://canvas.beta.instructure.com (Beta environment launches)
- https://canvas.test.instructure.com (Test environment launches)

The request also includes a `login_hint` that is passed in the next step. Last, the request include the `target_link_uri` that has been configured on the Developer key; this is later used by the tool as a recommended final redirect.

<table>
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="mono">iss</td>
      <td>The issuer, as described above.</td>
    </tr>
    <tr>
      <td class="mono">login_hint</td>
      <td>Opaque value that must be passed back to Canvas in the next step.</td>
    </tr>
    <tr>
      <td class="mono">target_link_uri</td>
      <td>The recommended final redirect for the tool; not required.</td>
    </tr>
    <tr>
      <td class="mono">client_id</td>
      <td>The OAuth2 client id, or Developer Key id, for convenience.</td>
    </tr>
    <tr>
      <td class="mono">deployment_id</td>
      <td>Unique identifier for the specific deployment of this tool, for convenience.</td>
    </tr>
    <tr>
      <td class="mono">canvas_region</td>
      <td>For hosted Canvas, the AWS region (e.g. us-east-1) in which the institution that provided this token resides. For local or open source Canvas, this will have a value of "unknown". This field is safe to ignore. This can be used for tools that are hosted in multiple regions to launch to one url and redirect to the correct region.</td>
    </tr>
    <tr>
      <td class="mono">canvas_environment</td>
      <td>For hosted Canvas, the environment (e.g. "production", "beta", or "test") from which the tool is being launched. For local or open source Canvas, this will have a value of "production". This field is safe to ignore. Tools can use this to redirect to beta- or test-specific instances of their tool on launch. This is in place of the LTI 1.1 `environments` tool config option, which is not recognized for 1.3 tools.</td>
    </tr>
  </tbody>
</table>

<a name="login-redirect"></a>
####Step 1.5: Optional Tool-to-tool Redirect

There are situations where a tool wants to use a region-specific or environment-specific instance of itself to respond to the LTI launch, like keeping traffic within the same region as the instance of Canvas, or using a different domain or even launch URL when launched from beta Canvas vs normal production.

Tools can use the `canvas_region` or `canvas_environment` parameters specified above, or even the Canvas URL from the request's referrer, to decide if they want to redirect.

Example of redirecting to a different domain based on region and environment:

- Login request is made to the tool's OIDC initiation URL, `mytool.net/login`, and contains `canvas_region: us-west-2, canvas_environment: beta`.
- The tool redirects to `beta-pdx.mytool.net/login`, forwarding all of the request parameters.
- The beta-pdx instance of the tool responds by continuing on to Step 2 below.

Example of redirecting to a different launch URL based on environment:

- Login request is made to the tool's OIDC initiation URL, `mytool.net/login`, and contains `canvas_environment: beta, target_link_uri: mytool.net/launch`.
- The tool continues on to Step 2 below, but sends `redirect_uri: mytool.net/beta_launch` instead of using the target_link_uri.

Tools that wish to utilize this redirect need to make sure that all possible initiation URLs, whether the domains or paths vary, are added to the redirect URIs list on their corresponding Developer Key, so that the auth request in Step 2 succeeds.

Tools that utilize different instances for beta and test must also make sure that they are storing the correct corresponding values for Canvas URLS like the OIDC Auth URL, JWKs URL, and the Issuer/`iss`, and that they use the beta or test versions of all of those URLs when the tool is launched from beta or test Canvas.

Using the `oidc_initiation_urls` option described [in the JSON tool config](#request-params) can also produce a similar outcome while removing the need for the tool to perform an internal redirect.

<a name="step-2"></a>
###Step 2: Authentication Request
To complete authentication, tools are expected to send back an <a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">authentication request</a> to an "OIDC Authorization end-point". This can be a GET or POST, however, this request needs to be a redirect in the user’s browser and not made server to server as we need to validate the current user's session data. For cloud-hosted Canvas, regardless of the domain used by the client, the endpoint is always:

> - `https://sso.canvaslms.com/api/lti/authorize_redirect` (if launched from a **production** environment)
> - `https://sso.beta.canvaslms.com/api/lti/authorize_redirect` (if launched from a **beta** environment)
> - `https://sso.test.canvaslms.com/api/lti/authorize_redirect` (if launched from a **test** environment)

> The domain for this endpoint used to be `https://canvas.instructure.com`. The impetus for this change and other exact details are described in <a href="https://community.canvaslms.com/t5/The-Product-Blog/Minor-LTI-1-3-Changes-New-OIDC-Auth-Endpoint-Support-for/ba-p/551677" target="_blank">this Canvas Community article</a>. Tools wishing to implement the Platform Storage spec are required to use the new domain for this endpoint, and all other tools should update this endpoint in their configuration store as soon as possible. This change will eventually be enforced, but for now is not a breaking change - the old domain will continue to work. Any questions or issues are either addressed in the linked article or can be filed as a standard support/partner support case, referencing the OIDC Auth endpoint change.

Among the <a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">required variables</a> the request should include:

- a `redirect_uri`, which must match at least one configured on the developer key.
- a `client_id` that matches the developer key. This must be <a href="#config-in-tool">registered in the tool</a> before the launch occurs.
- the same `login_hint` that Canvas sent in Step 1.
- a `state` parameter the tool will use to validate the request in Step 4.

<a name="step-3"></a>
###Step 3: Authentication Response (LTI Launch)
Canvas will use the `client_id` to lookup which developer key to use and then check the `redirect_uri` that was sent in the previous step and ensure that there is a exact-matching `redirect_uri` on the developer key. Canvas then sends its <a href="http://www.imsglobal.org/spec/security/v1p0/#step-3-authentication-response" target="_blank">authentication response</a> to the `redirect_uri` that the tool provided in Step 2. The request will include an `id_token` which is a signed JWT containing the LTI payload (user identifiers, course contextual data, custom data, etc.). Tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate the request is actually coming from Canvas</a> using <a href="#config-in-tool" target="_blank">Canvas' public JWKs</a>.

<a name="step-4"></a>
###Step 4: Resource Display
The tool then validates the `state` parameter matches the one sent in Step 2 and redirects the User Agent to the `target_link_uri` that was sent in Step 1 (or some other location of its choice) to <a href="http://www.imsglobal.org/spec/security/v1p0/#step-4-resource-is-displayed" target="_blank">display the final resource</a>. This redirect occurs in an iframe unless the tool is configured otherwise.

<a name="cookie-less"></a>
###Launching without Cookies

Safari blocking cookies inside 3rd-party iframes made it necessary to create a workaround for storing the `state` property between the login and launch requests, to prevent MITM attacks. The newly finalized LTI Platform Storage spec provides a way for tools that are launching in Safari
or another situation where cookies can't get set to still store data across requests in a secure fashion. Tools can send `window.postMessage`s to
Canvas asking it to store and retrieve arbitrary data, which acts as a cookie-like proxy.

The LTI Platform Storage spec includes an [implementation guide](https://www.imsglobal.org/spec/lti-cs-oidc/v0p1)
which **needs to be the primary resource for implementing this**, though a brief usage overview is included below.

Support for this API is determined by either:

1. the presence of the `lti_storage_target` as an extra body parameter in both the login (Step 1) and launch (Step 3) requests, or
2. a response postMessage to the `lti.capabilities` postMessage that contains the `lti.get_data` and `lti.put_data` subjects.

If the `lti_storage_target` parameter is absent, or the tool doesn't receive a response postMessage for `lti.capabilities`, then the tool
should not attempt to use this API and should fall back to cookies to verify the launch `state` parameter.

When the tool sees either of the above signals that Canvas supports this API, then:

1. In Step 2, instead of storing the `state` parameter in a cookie the tool should store it in Canvas's LTI Platform Storage using the `lti.put_data` postMessage. It's recommended that the key include the value (eg key: "state-1234", value: "1234") to avoid any collisions during multiple launches, and to make recovering the value easy.

2. In Step 4, instead of comparing the `state` parameter to the stored value in the cookie, the tool should retrieve it using the `lti.get_data` postMessage. Since this comparison has to happen in Javascript instead of on the server, the tool should render _something_, then check these values. If the values don't match, the tool can then log the user out or render an error.

According to the spec, the target origin for these postMessages must be the OIDC Auth domain (e.g. `https://sso.canvaslms.com`). Since every institution's domain varies, Canvas renders a frame at this domain that will respond to postMessages, and the name of this frame is supplied in the `lti_storage_target` parameter, provided as a body parameter in both login and launch requests. Tools should send their `lti.put_data` and `lti.get_data` postMessages to that frame, but can continue to send all other postMessage types to the parent window.

The LTI Platform Storage spec docs:

- [LTI OIDC Login with LTI Client Side postMessages](https://www.imsglobal.org/spec/lti-cs-oidc/v0p1)
- [Client-side postMessages](https://www.imsglobal.org/spec/lti-cs-pm/v0p1)
- [postMessage Platform Storage](https://www.imsglobal.org/spec/lti-pm-s/v0p1)
- [Canvas postMessage documentation](file.lti_window_post_message.html)

<a name="config-in-tool"></a>
Configuring Canvas in the Tool
=======================================
Tools will need to be aware of some Canvas-specific settings in order to accept a launch from Canvas and use the LTI Advantage Services:

- **Canvas Public JWKs**: When the tool receives the authentication response ([Step 3](#step-3)), tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate that the request is actually coming from Canvas</a>. Canvas' public keys are environment-specific, but not domain-specific (the same key set can be used across all client accounts):

> - Production: `https://sso.canvaslms.com/api/lti/security/jwks`
> - Beta: `https://sso.beta.canvaslms.com/api/lti/security/jwks`
> - Test: `https://sso.test.canvaslms.com/api/lti/security/jwks`

> **Note:** The domain for this endpoint used to be `https://canvas.instructure.com`. The impetus for this change and other exact details are described in <a href="https://community.canvaslms.com/t5/The-Product-Blog/Minor-LTI-1-3-Changes-New-OIDC-Auth-Endpoint-Support-for/ba-p/551677" target="_blank">this Canvas Community article</a>. Tools wishing to implement the Platform Storage spec are required to use the new domain for this endpoint, and all other tools should update this endpoint in their configuration store as soon as possible. This change will eventually be enforced, but for now is not a breaking change - the old domain will continue to work. Any questions or issues are either addressed in the linked article or can be filed as a standard support/partner support case, referencing the OIDC Auth endpoint change.

- **Authorization Redirect URL**: The values and use of this are described in [Step 2](#step-2). Since the URL is static, you will want to configure this in your tool. Tools that wish to utilize [Step 1.5](#login-redirect) need to include _all_ possible redirect URLs here.

- **Client ID**: The `client_id` of the Developer Key that's been configured in Canvas. Your tool will need to use this in the authentication response to Canvas ([Step 2](#step-2)) and it is also used during the <a href="" target="_blank">Client Credentials Grant</a> to access <a href="file.oauth.html#accessing-lti-advantage-services" target="_blank">LTI Advantage Services</a>.

- **Deployment ID**: The `deployment_id` can be optionally configured in the tool. A single developer key may have many deployments, so the deployment ID can be used to identify which deployment is being launched. For more, refer to the LTI 1.3 core specification, <a href="https://www.imsglobal.org/spec/lti/v1p3/#lti_deployment_id-login-parameter" target="_blank">section 4.1.2</a>. The `deployment_id` in Canvas is exposed after a tool has been <a href="https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-an-external-app-for-an-account-using-a-client/ta-p/202" target="_blank">deployed using the `client_id`</a>.

<a name="config-in-canvas"></a>
Configuring the Tool in Canvas
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
<a href="https://canvas.instructure.com/doc/api/file.oauth.html#accessing-lti-advantage-services"
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

    <tr class="request-param ">
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

    <tr class="request-param ">
      <td>description</td>
      <td>

                Required

      </td>
      <td>string</td>



      <td class="param-desc">

<p>A description of the tool</p>

      </td>
    </tr>

<!-- oidc_initiation_url -->

    <tr class="request-param ">
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

    <tr class="request-param ">
      <td><a name="param-oidc-initial-urls"></a>oidc_initiation_urls</td>
      <td>

      </td>
      <td>JSON object</td>



      <td class="param-desc">

<p>Optional region-specific <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">login initiation urls</a> that Canvas should redirect the User Agent to. Each institution's Canvas install lives in a particular AWS region, typically one close to the institution's physical region. If ths AWS region is listed as a key in this object, the URL in the value will override the default `oidc_initiation_url`. As of 2023, the regions used by Canvas are: us-east-1, us-west-2, ca-central-1, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2.

      </td>
    </tr>

<!-- target_link_uri -->

    <tr class="request-param ">
      <td>target_link_uri</td>
      <td>

        Required

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The <a href="https://www.imsglobal.org/spec/security/v1p0#step-1-third-party-initiated-login" target="_blank">target_link_uri</a> that Canvas should pass in the to the login initiation endpoint. This allows tools to determine which redirect_uri to pass Canvas in the authorization redirect request and should be <a href="https://www.imsglobal.org/spec/lti/v1p3/impl#verify-the-target_link_uri" target="_blank">verified during the final
launch</a>. This can be set at the tool-level, or within the "placements" JSON
object for placement-specific target_link_uri's</p>

      </td>
    </tr>

<!-- scopes -->

    <tr class="request-param ">
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
          <code class="enum">"https://canvas.instructure.com/lti/public_jwk/scope/update"</code>

     </p>

</p>

      </td>
    </tr>

<!-- extensions -->

    <tr class="request-param ">
      <td>extensions</td>
      <td>

      </td>
      <td>array of JSON objects</td>



      <td class="param-desc">

<p>The set of Canvas extensions, including placements, that the tool should use
</p>

      </td>
    </tr>

<!-- domain -->

    <tr class="request-param ">
      <td>domain</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The domain Canvas should use to match clicked LTI links against. This is recommended if <a href="file.content_item.html">deep linking</a> is used</p>.

      </td>
    </tr>

<!-- tool_id -->

    <tr class="request-param ">
      <td>tool_id</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>Allows tools to set a unique identifier for the tool.</p>.

      </td>
    </tr>

<!-- platform -->

    <tr class="request-param ">
      <td>platform</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The LMS platform that the extensions belong to. This should always be set to "canvas.instructure.com" for cloud-hosted Canvas</p>

      </td>
    </tr>

<!-- privacy_level -->

    <tr class="request-param ">
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

<!-- settings -->

    <tr class="request-param ">
      <td>settings</td>
      <td>

      </td>
      <td>JSON object</td>



      <td class="param-desc">

<p>The set of platform-specific settings to be used.</p>

      </td>
    </tr>

<!-- icon_url -->

    <tr class="request-param ">
      <td>icon_url</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The url of the icon to show for this tool. Can be set within the "settings" object for tool-level icons, or in the "placement" object for placement-specific icons. NOTE: Not all placements display an icon.</p>

<!-- selection_height -->

    <tr class="request-param ">
      <td>selection_height</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The display height of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>

<!-- selection_width -->

    <tr class="request-param ">
      <td>selection_width</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The display width of the iframe. This may be ignored or overridden for some LTI placements due to other UI requirements set by Canvas. Tools are advised to experiment with this setting to see what makes the most sense for their application.</p>

<!-- text -->

      </td>
    </tr>

    <tr class="request-param ">
      <td>text</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

<p>The default text to show for this tool. Can be set within "settings" for the tool-level display text, or within "placements" object for placement-specific display text.</p>

      </td>
    </tr>

<!-- enabled -->

    <tr class="request-param ">
      <td>enabled</td>
      <td>

      </td>
      <td>boolean</td>



      <td class="param-desc">

<p>Optional, defaults to `true`. Set within the "placements" object to to determine if the placement is enabled.</p>

      </td>
    </tr>

<!-- message_type -->

    <tr class="request-param ">
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

<!-- required_permissions -->

    <tr class="request-param ">
      <td>required_permissions</td>
      <td>

      </td>
      <td>string</td>



      <td class="param-desc">

        <p>Allows role-based access control based on the built-in Canvas user roles AND the custom roles that you may have created in Canvas. This parameter can be a comma-separated string of one or more required permissions. As expected, if "required_permissions" is included in the configuration, the user will need to have a role with the permissions listed (or all the permissions listed, if multiple) to access the tool. To learn more about roles and permissions, and to see the permissions available for this parameter visit the <a href="roles.html" target="blank">Roles API docs</a>.
        </p>


      </td>
    </tr>

<!-- environments -->

    <tr class="request-param ">
      <td>environments</td>
      <td>
        <strong style="color: red;">Ignored<strong>
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

    <tr class="request-param ">
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

    <tr class="request-param ">
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

    <tr class="request-param ">
      <td>custom_fields</td>
      <td>

      </td>
      <td>JSON object</td>



      <td class="param-desc">

<p>Custom fields that will be sent to the tool consumer; can be set at the tool-level or within the "placement" JSON object for placement-specific custom fields.</p>

      </td>
    </tr>

  </tbody>
</table>
