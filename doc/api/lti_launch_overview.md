Overview of an LTI Launch <a name="launch-overview"></a>
=======================================

<a name="top"></a>

The <a href="http://www.imsglobal.org/spec/security/v1p0/" target="_blank">IMS Security Framework</a> uses an
<a href="http://www.imsglobal.org/spec/security/v1p0/#openid_connect_launch_flow" target="_blank">Open ID Connect (OIDC)</a> third-party flow. You'll want to read these specifications in detail, but the following is a Canvas-specific summary:

### Step 1: Login Initiation <a name="step-1"></a>
Canvas <a href="http://www.imsglobal.org/spec/security/v1p0/#step-1-third-party-initiated-login" target="_blank">initiates a login request</a> to the `oidc_initiation_url` that is <a href="file.lti_dev_key_config.html#config-in-canvas">configured on the LTI developer key</a>. This request contains an issuer identifier (`iss`) to recognize that Canvas is launching the tool. As the issuer, Instructure-hosted Canvas instances all use the following, regardless of the specific account domain(s) that the tool was launched from:

- <https://canvas.instructure.com> (Production environment launches)
- <https://canvas.beta.instructure.com> (Beta environment launches)
- <https://canvas.test.instructure.com> (Test environment launches)

On self-hosted Canvas, the `iss` value must be updated to your Canvas instance's hostname in the `config/security.yml` file, as the default is <https://canvas.instructure.com>.

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

#### Step 1.5: Optional Tool-to-tool Redirect <a name="login-redirect"></a>

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

Using the `oidc_initiation_urls` option described [in the JSON tool config](file.lti_dev_key_config.html#request-params) can also produce a similar outcome while removing the need for the tool to perform an internal redirect.

### Step 2: Authentication Request <a name="step-2"></a>

To complete authentication, tools are expected to send back an <a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">authentication request</a> to an "OIDC Authorization end-point". This can be a GET or POST, however, this request needs to be a redirect in the user’s browser and not made server to server as we need to validate the current user's session data. For cloud-hosted Canvas, regardless of the domain used by the client, the endpoint is always:

- `https://sso.canvaslms.com/api/lti/authorize_redirect` (if launched from a **production** environment)
- `https://sso.beta.canvaslms.com/api/lti/authorize_redirect` (if launched from a **beta** environment)
- `https://sso.test.canvaslms.com/api/lti/authorize_redirect` (if launched from a **test** environment)

  The domain for this endpoint used to be `https://canvas.instructure.com`. The impetus for this change and other exact details are described in <a href="https://community.canvaslms.com/t5/The-Product-Blog/Minor-LTI-1-3-Changes-New-OIDC-Auth-Endpoint-Support-for/ba-p/551677" target="_blank">this Canvas Community article</a>. Tools wishing to implement the Platform Storage spec are required to use the new domain for this endpoint, and all other tools should update this endpoint in their configuration store as soon as possible. This change will eventually be enforced, but for now is not a breaking change - the old domain will continue to work. Any questions or issues are either addressed in the linked article or can be filed as a standard support/partner support case, referencing the OIDC Auth endpoint change.

Among the <a href="http://www.imsglobal.org/spec/security/v1p0/#step-2-authentication-request" target="_blank">required variables</a> the request should include:

- a `redirect_uri`, which must match at least one configured on the developer key.
- a `client_id` that matches the developer key. This must be <a href="file.lti_dev_key_config.html#config-in-tool">registered in the tool</a> before the launch occurs.
- the same `login_hint` that Canvas sent in Step 1.
- a `state` parameter the tool will use to validate the request in Step 4.

### Step 3: Authentication Response (LTI Launch) <a name="step-3"></a>

Canvas will use the `client_id` to lookup which developer key to use and then check the `redirect_uri` that was sent in the previous step and ensure that there is a exact-matching `redirect_uri` on the developer key. Canvas then sends its <a href="http://www.imsglobal.org/spec/security/v1p0/#step-3-authentication-response" target="_blank">authentication response</a> to the `redirect_uri` that the tool provided in Step 2. The request will include an `id_token` which is a signed JWT containing the LTI payload (user identifiers, course contextual data, custom data, etc.). Tools must <a href="http://www.imsglobal.org/spec/security/v1p0/#authentication-response-validation" target="_blank">validate the request is actually coming from Canvas</a> using <a href="file.lti_dev_key_config.html#config-in-tool" target="_blank">Canvas' public JWKs</a>.

### Step 4: Resource Display <a name="step-4"></a>
The tool then validates the `state` parameter matches the one sent in Step 2 and redirects the User Agent to the `target_link_uri` that was sent in Step 1 (or some other location of its choice) to <a href="http://www.imsglobal.org/spec/security/v1p0/#step-4-resource-is-displayed" target="_blank">display the final resource</a>. This redirect occurs in an iframe unless the tool is configured otherwise.

### Launching without Cookies <a name="cookie-less"></a>

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

