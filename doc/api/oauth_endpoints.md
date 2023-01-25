OAuth2 Endpoints
================

<div class="warning-message"> Developer keys issued after Oct 2015 generate tokens with a 1 hour expiration. Applications must use <a href="file.oauth.html#using-refresh-tokens">refresh tokens</a> to generate new access tokens.</div>

- [GET login/oauth2/auth](#get-login-oauth2-auth)
- [POST login/oauth2/token](#post-login-oauth2-token)
- [DELETE login/oauth2/token](#delete-login-oauth2-token)
- [GET login/session_token](#get-login-session-token)

<a name="get-login-oauth2-auth"></a>
## GET login/oauth2/auth

<div class="method_details">

<h3 class="endpoint">GET https://&lt;canvas-install-url&gt;/login/oauth2/auth?client_id=XXX&response_type=code&redirect_uri=https://example.com/oauth_complete&state=YYY&scope=&lt;value_1&gt;%20&lt;value_2&gt;%20&lt;value_n&gt;</h3>

<h4>Parameters</h4>

<table>
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Description</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td class="mono">client_id <span class="label required"></span></td>
      <td>The client id for your registered application.</td>
    </tr>
    <tr>
      <td class="mono">response_type <span class="label required"></span></td>
      <td>The type of OAuth2 response requested. The only
currently supported value is <code>code</code>.</td>
    </tr>
    <tr>
      <td class="mono">redirect_uri <span class="label required"></span></td>
      <td>The URL where the user will be redirected after
authorization. The domain of this URL must match the domain of the
redirect_uri stored on the developer key, or it must be a subdomain of
that domain.

For native applications, currently the only supported value is
<code>urn:ietf:wg:oauth:2.0:oob</code>, signifying that the credentials will be
retrieved out-of-band using an embedded browser or other functionality.
</td>
    </tr>
    <tr>
      <td class="mono">state <span class="label optional"></span></td>
      <td>Your application can pass Canvas an arbitrary piece of
state in this parameter, which will be passed back to your application
in Step 2. It's strongly encouraged that your application pass a unique
identifier in the state parameter, and then verify in Step 2 that the
state you receive back from Canvas is the same expected value. Failing
to do this opens your application to the possibility of logging the
wrong person in, as <a href="http://homakov.blogspot.com/2012/07/saferweb-most-common-oauth2.html">described here</a>.</td>
    </tr>
    <tr>
      <td class="mono">scope<span class="label optional"></span></td>
      <td>
        This can be used to specify what information the Canvas API access token will provide access to.
        Canvas API scopes may be found beneath their corresponding endpoints in the "resources" documentation pages.
        If the developer key does not require scopes and no scope parameter is specified, the access token will have access to all scopes. If the developer key does require scopes and no scope parameter is specified, Canvas will respond with "invalid_scope."
        To successfully pass multiple scope values, the scope parameter is included once, with multiple values separated by spaces.
        Passing multiple scope parameters, as is common in other areas of Canvas, causes only the last value to be applied to the generated token.
      </td>
    </tr>
    <tr>
      <td class="mono">purpose<span class="label optional"></span></td>
      <td>This can be used to help the user identify which instance
      of an application this token is for. For example, a mobile device
      application could provide the name of the device.</td>
    </tr>
    <tr>
      <td class="mono">force_login<span class="label optional"></span></td>
      <td>Set to '1' if you want to force the user to enter their
      credentials, even if they're already logged into Canvas. By default,
      if a user already has an active Canvas web session, they will not be
      asked to re-enter their credentials.</td>
    </tr>
    <tr>
      <td class="mono">unique_id<span class="label optional"></span></td>
      <td>Set to the user's username to be populated in the login form in the event
      that the user must authenticate.</td>
    </tr>
    <tr>
      <td class="mono">prompt<span class="label optional"></span></td>
      <td>If set to <code>none</code>, Canvas will immediately redirect to the
      <code>redirect_uri</code>. If the caller has a valid session with a
      &quot;remember me&quot; token or a token from a trusted Developer Key,
      the redirect will contain a <code>code=XYZ</code> param. If the caller
      has no session, the redirect will contain an
      <code>error=login_required</code> param. If the caller has a session, but
      no &quot;remember me&quot; or trusted token, the redirect will contain an
      <code>error=interaction_required</code> param.</td>
    </tr>
  </tbody>
</table>
</div>



<a name="post-login-oauth2-token"></a>
## POST login/oauth2/token
<div class="method_details">

See <a href="http://tools.ietf.org/html/rfc6749#section-4.1.3">Section 4.1.3</a> of the OAuth2 RFC for more information about this process.

  <h3 class="endpoint">POST /login/oauth2/token</h3>
  <h4>Parameters</h4>
  <table>
    <thead>
      <tr>
        <th>Parameter</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="mono">grant_type <span class="label required"></span></td>
        <td>Values currently supported "authorization_code", "refresh_token", and "client_credentials"</td>
      </tr>
      <tr>
        <td class="mono">client_id <span class="label required-for">grant_types: authorization_code refresh_token</span></td>
        <td>The client id for your registered application.</td>
      </tr>
      <tr>
        <td class="mono">client_secret <span class="label required-for">grant_types: authorization_code refresh_token</span></td>
        <td>The client secret for your registered application.</td>
      </tr>
      <tr>
        <td class="mono">redirect_uri <span class="label required-for">grant_types: authorization_code refresh_token</span></td>
        <td>If a redirect_uri was passed to the initial request in
        step 1, the same redirect_uri must be given here.</td>
      </tr>
      <tr>
        <td class="mono">code <span class="label required-for">grant_type: authorization_code</span></td>
        <td>Required if grant_type is authorization_code. The code you received in a redirect response.</td>
      </tr>
      <tr>
        <td class="mono">refresh_token <span class="label required-for">grant_type: refresh_token</span></td>
        <td>Required if grant_type is refresh_token. The refresh_token you received in a redirect response.</td>
      </tr>
      <tr>
        <td class="mono">client_assertion_type <span class="label required-for">grant_type: client_credentials</span></td>
        <td>Currently the only supported value for this field is `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`</td>
      </tr>
      <tr>
        <td class="mono">client_assertion <span class="label required-for">grant_type: client_credentials</span></td>
        <td>The signed jwt used to request an access token. Includes the value of Developer Key id
        as the sub claim of the jwt body. Should be signed by the private key of the stored public key on the DeveloperKey.</td>
      </tr>
      <tr>
        <td class="mono">scope <span class="label required-for">grant_type: client_credentials</span></td>
        <td>A list of scopes to be granted to the token. Currently only IMS defined scopes may be used.</td>
      </tr>
    </tbody>
  </table>


  <h4>Canvas API example responses</h4>
  <p>For grant_type of code or refresh_token:</p>
  <table>
    <thead>
      <tr>
        <th>Parameter</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="mono">access_token</td>
        <td>The OAuth2 Canvas API access token.</td>
      </tr>
      <tr>
        <td class="mono">token_type</td>
        <td>The type of token that is returned.</td>
      </tr>
      <tr>
        <td class="mono">user</td>
        <td>A JSON object of canvas user id and user name.</td>
      </tr>
      <tr>
        <td class="mono">refresh_token</td>
        <td>The OAuth2 refresh token.</td>
      </tr>
      <tr>
        <td class="mono">expires_in</td>
        <td>Seconds until the access token expires.</td>
      </tr>
      <tr>
        <td class="mono">canvas_region</td>
        <td>For hosted Canvas, the AWS region (e.g. us-east-1) in which the institution that provided this token resides. For local or open source Canvas, this will have a value of "unknown". This field is safe to ignore.</td>
      </tr>
    </tbody>
  </table>

  <p>When using grant_type=code (ex: for Canvas API access):</p>

  <pre class="example code prettyprint">
  {
    "access_token": "1/fFAGRNJru1FTz70BzhT3Zg",
    "token_type": "Bearer",
    "user": {"id":42, "name": "Jimi Hendrix"},
    "refresh_token": "tIh2YBWGiC0GgGRglT9Ylwv2MnTvy8csfGyfK2PqZmkFYYqYZ0wui4tzI7uBwnN2",
    "expires_in": 3600,
    "canvas_region": "us-east-1"
  }
  </pre>
  
  <p>When using grant_type=refresh_token, the response will not contain a new
  refresh token since the same refresh token can be used multiple times:</p>

  <pre class="example code prettyprint">
  {
    "access_token": "1/fFAGRNJru1FTz70BzhT3Zg",
    "token_type": "Bearer",
    "user": {"id":42, "name": "Jimi Hendrix"},
    "expires_in": 3600
  }
  </pre>

  <p>If scope=/auth/userinfo was specified in the
  <a href=oauth_endpoints.html#get-login-oauth2-auth>GET login/oauth2/auth</a> request (ex: when using Canvas as an authentication service)
  then the response that results from
  <a href=oauth_endpoints.html#post-login-oauth2-token>POST login/oauth2/token</a> would be:</p>

  <pre class="example code prettyprint">
  {
    "access_token": null,
    "token_type": "Bearer",
    "user":{"id": 42, "name": "Jimi Hendrix"}
  }
  </pre>

<h4>Examples using client_credentials</h4>
  

  <p>When using grant_type=client_credentials (ex: <a href="/doc/api/file.oauth.html#accessing-lti-advantage-services">to access LTI Advantage Services</a>):</p>

<h5>Example request</h5>
  
<p>This request must be signed by an RSA256 private key with a public key that is configured on the developer key as described in <a href="/doc/api/file.oauth.html#developer-key-setup" target="_blank">Step 1: Developer Key Setup</a>.</p>

  <pre class="example code prettyprint">
  {
    "grant_type": "client_credentials",
    "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
    "client_assertion": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjIwMTktMDYtMjFUMTQ6NTk6MzBaIn0.eyJpc3MiOiJodHRwczovL3d3dy5teS10b29sLmNvbSIsInN1YiI6Ilx1MDAzY2NsaWVudF9pZFx1MDAzZSIsImF1ZCI6Imh0dHA6Ly9cdTAwM2NjYW52YXNfZG9tYWluXHUwMDNlL2xvZ2luL29hdXRoMi90b2tlbiIsImlhdCI6MTU2MTc1MDAzMSwiZXhwIjoxNTYxNzUwNjMxLCJqdGkiOiJkZmZkYmRjZS1hOWYxLTQyN2ItOGZjYS02MDQxODIxOTg3ODMifQ.lUHCwDqx2ukKQ2vwoz_824IVcyq-rNdJKVpGUiJea5-Ybk_VfyKW5v0ky-4XTJrGHkDcj0T9J8qKfYbikqyetK44yXx1YGo-2Pn2GEZ26bZxCnuDUDhbqN8OZf4T8DnZsYP4OyhOseHERsHCzKF-SD2_Pk6ES5-Z8J55_aMyS3w3tl4nJtwsMm6FbMDp_FhSGE4xTwkBZ2KNM4JqkCwHGX_9KcpsPsHRFQjn9ysTeg-Qf7H2QFgFMFjsfQX-iSL_bQoC2npSz7rQ8awKMhCEYdMYZk2vVhQ7XQ8ysAyf3m1vlLbHjASpztcAB0lz_DJysT0Ep-Rh311Qf_vXHexjVA",
    "scope": "https://purl.imsglobal.org/spec/lti-ags/lineitem https://purl.imsglobal.org/spec/lti-ags/result/read"
  }
  </pre>

<p>Below is an example of the decoded client_assertion JWT in the above request:</p>

  <pre class="example code prettyprint">
  {
    "iss": "https://www.my-tool.com",
    "sub": "&lt;client_id&gt;",
    "aud": "https://&lt;canvas_domain&gt;/login/oauth2/token",
    "iat": 1561750031,
    "exp": 1561750631,
    "jti": "dffdbdce-a9f1-427b-8fca-604182198783"
  }
  </pre>
 
<p>NOTE:</p>

<ul>
 <li> the value of the sub claim should match the client_id of the developer key in Canvas.</li>
 <li> the value of the aud claim should contain either the domain of the Canvas account where the desired data resides, or the domain of the LTI 1.3 OIDC Auth endpoint, as described <a href="/doc/api/file.lti_dev_key_config.html#step-2" target="_blank">here</a>.</li>
</ul>


  <h5>Example Response</h5>
  <table>
    <thead>
      <tr>
        <th>Parameter</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="mono">access_token</td>
        <td>The OAuth2 client_credentials access token.</td>
      </tr>
      <tr>
        <td class="mono">token_type</td>
        <td>The type of token that is returned.</td>
      </tr>
      <tr>
        <td class="mono">expires_in</td>
        <td>Seconds until the access token expires.</td>
      </tr>      
      <tr>
        <td class="mono">scope</td>
        <td>The scope or space delimited list of scopes granted for the access token.</td>
      </tr>
    </tbody>
  </table>
  <pre class="example code prettyprint">
  {
    "access_token" : "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3d3cuZXhhbXBsZS5jb20iLCJpYXQiOiIxNDg1OTA3MjAwIiwiZXhwIjoiMTQ4NTkwNzUwMCIsImltc2dsb2JhbC5vcmcuc2VjdXJpdHkuc2NvcGUiOiJMdGlMaW5rU2V0dGluZ3MgU2NvcmUuaXRlbS5QVVQifQ.UWCuoD05KDYVQHEcciTV88YYtWWMwgb3sTbrjwxGBZA",
    "token_type" : "Bearer",
    "expires_in" : 3600,
    "scope" : "https://purl.imsglobal.org/spec/lti-ags/lineitem https://purl.imsglobal.org/spec/lti-ags/result/read"
  }
  </pre>
</div>

<a name="delete-login-oauth2-token"></a>
## DELETE login/oauth2/token


<div class="method_details">

  If your application supports logout functionality, you can revoke your own
  access token. This is useful for security reasons, as well as removing your
  application from the list of tokens on the user's profile page. Simply make
  an authenticated request to the following endpoint by including an Authorization
  header or providing the access_token as a request parameter.

  <h3 class="endpoint">DELETE /login/oauth2/token</h3>

  <h4>Parameters</h4>
  <table>
    <thead>
      <tr>
        <th>Parameter</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="mono">expire_sessions <span class="label optional"></span></td>
        <td><p>Set this to '1' if you want to end all of the user's
        Canvas web sessions.  Without this argument, the endpoint will leave web sessions intact.</p>

        <p>Additionally, if the user logged in to Canvas via a delegated authentication provider,
        and the provider supports Single Log Out functionality, the response will contain a 
        forward_url key. If you are still in control of the user's browsing session, it is
        recommended to then redirect them to this URL, in order to also log them out from
        where their session originated. Beware that it is unlikely that control will be returned
        to your application after this redirect.</p>
        </td>
      </tr>
    </tbody>
  </table>

  <h4>Example responses</h4>

  <pre class="example_code">
  {
    "forward_url": "https://idp.school.edu/opaque_url"
  }
  </pre>
</div>

<a name="get-login-session-token"></a>
## GET login/session_token


<div class="method_details">

  If your application needs to begin a normal web session in order to access
  features not supported via API (such as quiz taking), you can use your API
  access token in order to get a time-limited URL that can be fed to a
  browser or web view to begin a new web session.

  <h3 class="endpoint">GET /login/session_token</h3>

  <h4>Parameters</h4>
  <table>
    <thead>
      <tr>
        <th>Parameter</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="mono">return_to <span class="label optional"></span></td>
        <td>An optional URL to begin the web session at. Otherwise the user will be sent to the dashboard.</td>
      </tr>
    </tbody>
  </table>


  <h4>Example responses</h4>

  <pre class="example code prettyprint">
  {
    "session_url": "https://canvas.instructure.com/opaque_url"
  }
  </pre>
</div>
