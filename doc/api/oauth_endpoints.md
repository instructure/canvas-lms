OAuth2 Endpoints
================

<div class="warning-message"> We have started rolling out short lived access tokens. You will need to start using <a href="file.oauth.html#using-refresh-tokens">refresh tokens</a> to generate new access tokens.</div>

- [GET login/oauth2/auth](#get-login-oauth2-auth)
- [POST login/oauth2/token](#post-login-oauth2-token)
- [DELETE login/oauth2/token](#delete-login-oauth2-token)

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
      <td>This can be used to specify what information the access token
      will provide access to.  By default an access token will have access to
      all api calls that a user can make.  The only other accepted value
      for this at present is '/auth/userinfo', which can be used to obtain
      the current canvas user's identity</td>
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


  <h4>Response</h4>
  The response will be a JSON argument containing the access_token:

  <pre class="example_code">
  {
    access_token: "1/fFAGRNJru1FTz70BzhT3Zg",
    refresh_token: "tIh2YBWGiC0GgGRglT9Ylwv2MnTvy8csfGyfK2PqZmkFYYqYZ0wui4tzI7uBwnN2"
    expires_in: 3600
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
        <td class="mono">refresh_token</td>
        <td>The OAuth2 refresh token.</td>
      </tr>
      <tr>
        <td class="mono">expires_in</td>
        <td>Seconds until the access token expires</td>
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
  an authenticated request to the following endpoint:

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
