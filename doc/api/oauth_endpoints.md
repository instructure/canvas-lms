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

<h3 class="endpoint">GET https://&lt;canvas-install-url&gt;/login/oauth2/auth?client_id=XXX&response_type=code&redirect_uri=https://example.com/oauth_complete&state=YYY</h3>

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
        This can be used to specify what information the access token will provide access to.
        Scopes may be found beneath their corresponding endpoints in the "resources" documentation pages.
        If the developer key does not require scopes and no scope parameter is specified, the access token will have access to all scopes. If the developer key does require scopes and no scope parameter is specified, Canvas will respond with "invalid_scope."
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
        <td>Values currently supported "authorization_code", "refresh_token"</td>
      </tr>
      <tr>
        <td class="mono">client_id <span class="label required"></span></td>
        <td>The client id for your registered application.</td>
      </tr>
      <tr>
        <td class="mono">client_secret <span class="label required"></span></td>
        <td>The client secret for your registered application.</td>
      </tr>
      <tr>
        <td class="mono">redirect_uri <span class="label required"></span></td>
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
    </tbody>
  </table>


  <h4>Example responses</h4>

  When using grant_type=code:

  <pre class="example_code">
  {
    "access_token": "1/fFAGRNJru1FTz70BzhT3Zg",
    "token_type": "Bearer",
    "user": {"id":42, "name": "Jimi Hendrix"},
    "refresh_token": "tIh2YBWGiC0GgGRglT9Ylwv2MnTvy8csfGyfK2PqZmkFYYqYZ0wui4tzI7uBwnN2",
    "expires_in": 3600
  }
  </pre>

  When using grant_type=refresh_token, the response will not contain a new
  refresh token since the same refresh token can be used multiple times:

  <pre class="example_code">
  {
    "access_token": "1/fFAGRNJru1FTz70BzhT3Zg",
    "token_type": "Bearer",
    "user": {"id":42, "name": "Jimi Hendrix"},
    "expires_in": 3600
  }
  </pre>

  If scope=auth/userinfo was specified in the
  <a href=oauth_endpoints.html#get-login-oauth2-auth>GET login/oauth2/auth</a> request
  then the response that results from
  <a href=oauth_endpoints.html#post-login-oauth2-token>POST login/oauth2/token</a> would be:

  <pre class="example_code">
  {
    "access_token": null,
    "token_type": "Bearer",
    "user":{"id": 42, "name": "Jimi Hendrix"}
  }
  </pre>

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
        <td>The OAuth2 access token.</td>
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
    </tbody>
  </table>
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
        <td>Set this to '1' if you want to end all of the user's
  Canvas web sessions.  Without this argument, the endpoint will leave web sessions intact.</td>
      </tr>
    </tbody>
  </table>
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

  <pre class="example_code">
  {
    "session_url": "https://canvas.instructure.com/opaque_url"
  }
  </pre>
</div>
