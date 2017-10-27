OAuth2
======
<a name="top"></a>
<div class="warning-message"> Developer keys issued after Oct 2015 generate tokens with a 1 hour expiration. Applications must use <a href="file.oauth.html#using-refresh-tokens">refresh tokens</a> to generate new access tokens.</div>

[OAuth2](http://oauth.net/2/) is a protocol designed to let third-party applications
authenticate to perform actions as a user, without getting the user's
password. Canvas uses OAuth2 (specifically [RFC-6749](http://tools.ietf.org/html/rfc6749))
for authentication and authorization of the Canvas API.
<a name="top"></a>
- [Storing Tokens](#storing-access-tokens)
- [Manual Token Generation](#manual-token-generation)
- [Oauth2 Flow](#oauth2-flow)
  - [Getting OAuth2 Client ID/Secret](#oauth2-flow-0)
  - [Step 1: Redirect users to request Canvas access](#oauth2-flow-1)
  - [Step 2: Redirect back to the request\_uri, or out-of-band redirect](#oauth2-flow-2)
    - [Note for native apps](#oauth2-flow-2.1)
  - [Step 3: Exchange the code for the final access token](#oauth2-flow-3)
- [Using an Access Token to authenticate requests](#using-access-tokens)
- [Using a Refresh Token to get a new Access Token](#using-refresh-tokens)
- [Logging Out](file.oauth_endpoints.html#delete-login-oauth2-token)
- [Endpoints](file.oauth_endpoints.html)
  - [GET login/oauth2/auth](file.oauth_endpoints.html#get-login-oauth2-auth)
  - [POST login/oauth2/token](file.oauth_endpoints.html#post-login-oauth2-token)
  - [DELETE login/oauth2/token](file.oauth_endpoints.html#delete-login-oauth2-token)
  - [GET login/session_token](file.oauth_endpoints.html#get-login-session-token)

<a name="storing-access-tokens"></a>
## [Storing Tokens](#storing-access-tokens)
<small><a href="#top">Back to Top</a></small>

When appropriate, applications should store the token locally, rather
than requesting a new token for the same user each time the user uses the
application. If the token is deleted or expires, the application will
get a 401 Unauthorized error from the API, in which case the application should
perform the OAuth flow again to receive a new token. You can differentiate this
401 Unauthorized from other cases where the user simply does not have
permission to access the resource by checking that the WWW-Authenticate header
is set.

Storing a token is in many ways equivalent to storing the user's
password, so tokens should be stored and used in a secure manner,
including but not limited to:

  * Don't embed tokens in web pages.
  * Don't pass tokens or session IDs around in URLs.
  * Properly secure the database or other data store containing the
    tokens.
  * For web applications, practice proper techniques to avoid session
    attacks such as cross-site scripting, request forgery, replay
    attacks, etc.
  * For native applications, take advantage of user keychain stores and
    other operating system functionality for securely storing passwords.


<a name="manual-token-generation"></a>
## [Manual Token Generation](#manual-token-generation)
<small><a href="#top">Back to Top</a></small>

For testing your application before you've implemented OAuth, the
simplest option is to generate an access token on your user's profile
page. Note that asking any other user to manually generate a token and
enter it into your application is a violation of Canvas' terms of
service. *Applications in use by multiple users **MUST** use OAuth to obtain
tokens*.

To manually generate a token for testing:

  1. Click the "profile" link in the top right menu bar, or navigate to
     `/profile`
  2. Under the "Approved Integrations" section, click the button to
     generate a new access token.
  3. Once the token is generated, you cannot view it again, and you'll
     have to generate a new token if you forget it. Remember that access
     tokens are password equivalent, so keep it secret.


<a name="oauth2-flow"></a>
## [Oauth2 Flow](#oauth2-flow)
<small><a href="#top">Back to Top</a></small>

Your application can rely on canvas for a user's identity.  During step 1 of
the web application flow below, specify the optional scope parameter as
scope=/auth/userinfo.  When the user is asked to grant your application
access in step 2 of the web application flow, they will also be given an
option to remember their authorization.  If they grant access and remember
the authorization, Canvas will skip step 2 of the request flow for future requests.

Canvas will not give a token back as part of a userinfo request.  It will only
provide the current user's name and id.

<a name="oauth2-flow-0"></a>
### [Getting OAuth2 Client ID/Secret](#oauth2-flow-0)

If your application will be used by others, you will need to implement
the full OAuth2 token request workflow, so that you can request an access
token for each user of your application.

Performing the OAuth2 token request flow requires an application client
ID and client secret. To obtain these application credentials, you will
need to register your application.  The client secret should never be shared.

For Canvas Cloud (hosted by Instructure), developer keys are
[issued by the admin of the institution](https://community.canvaslms.com/docs/DOC-5141).

<b>NOTE for LTI providers:</b> Since developer keys are scoped to the institution they are issued
from, tool providers that serve multiple institutions should store and look up the correct
developer key based on the launch parameters (eg. custom_canvas_api_domain) sent during the LTI
launch.

For [open source Canvas users](https://github.com/instructure/canvas-lms/wiki),
you can [generate a client ID](https://community.canvaslms.com/docs/DOC-5141)
and secret in the Site Admin account of your Canvas install.

<a name="oauth2-flow-1"></a>
### [Step 1: Redirect users to request Canvas access](#oauth2-flow-1)
<small><a href="#top">Back to Top</a></small>

A basic request looks like:

<div class="method_details">
<h3 class="endpoint">GET https://&lt;canvas-install-url&gt;/login/oauth2/auth?client_id=XXX&response_type=code&state=YYY&redirect_uri=https://example.com/oauth_complete</h3>
</div>

See [GET login/oauth2/auth](file.oauth_endpoints.html#get-login-oauth2-auth) for details.

<a name="oauth2-flow-2"></a>
### [Step 2: Redirect back to the request\_uri, or out-of-band redirect](#oauth2-flow-2)
<small><a href="#top">Back to Top</a></small>

If the user accepts your request, Canvas redirects back to your
request\_uri with a specific query string, containing the OAuth2
response:

<div class="method_details">
<h3 class="endpoint">http://www.example.com/oauth2response?code=XXX&state=YYY</h3>
</div>

The app can then extract the code, and use it along with the
client_id and client_secret to obtain the final access_key.

If your application passed a state parameter in step 1, it will be
returned here in step 2 so that your app can tie the request and
response together.

If the user doesn't accept the request for access, or if another error
occurs, Canvas redirects back to your request\_uri with an `error`
parameter, rather than a `code` parameter, in the query string.

<div class="method_details">
<h3 class="endpoint">http://www.example.com/oauth2response?error=access_denied</h3>
</div>

`access_denied` is the only currently implemented error code.

<a name="oauth2-flow-2.1"></a>
#### [Note for native apps](#oauth2-flow-2.1)
<small><a href="#top">Back to Top</a></small>

Canvas redirects to a page on canvas with a specific query string, containing parameters from the OAuth2 response:

<pre class="example_code">
/login/oauth2/auth?code=&lt;code&gt;
</pre>

<div class="method_details">
<h3>/login/oauth2/auth?code=&lt;code&gt;</h3>
</div>

At this point the app should notice that the URL of the webview has
changed to contain <code>code=&lt;code&gt;</code> somewhere in the query
string. The app can then extract the code, and use it along with the
client_id and client_secret to obtain the final access_key.

<a name="oauth2-flow-3"></a>
### [Step 3: Exchange the code for the final access token](#oauth2-flow-3)
<small><a href="#top">Back to Top</a></small>

To get a new access token and refresh token, send a
[POST request to login/oauth2/token](file.oauth_endpoints.html#post-login-oauth2-token)
with the following parameters:

<h4>Parameters</h4>
<table>
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="mono">grant_type</td>
      <td>authorization_code</td>
    </tr>
    <tr>
      <td class="mono">client_id</td>
      <td><span class="label">Your client_id</span></td>
    </tr>
    <tr>
      <td class="mono">client_secret</td>
      <td><span class="label">Your client_secret</span></td>
    </tr>
    <tr>
      <td class="mono">redirect_uri</td>
      <td>If a redirect_uri was passed to the initial request in
      step 1, the same redirect_uri must be given here.</td>
    </tr>
    <tr>
      <td class="mono">code</td>
      <td><span class="label">code from canvas</span></td>
    </tr>
    <tr>
      <td class="mono">replace_tokens</td>
      <td>(optional) If this option is provided, existing access tokens issued for this developer key/secret will be destroyed and replaced with the new token that is returned from this request</td>
    </tr>
  </tbody>
</table>

<a name="using-access-tokens"></a>
## [Using an Access Token to authenticate requests](#using-access-tokens)
<small><a href="#top">Back to Top</a></small>

Once you have an OAuth access token, you can use it to make API
requests. If possible, using the HTTP Authorization header is
recommended.

OAuth2 Token sent in header:

```bash
curl -H "Authorization: Bearer <ACCESS-TOKEN>" "https://canvas.instructure.com/api/v1/courses"
```

Sending the access token in the query string or POST
parameters is also supported, but discouraged as it increases the
chances of the token being logged or leaked in transit.

OAuth2 Token sent in query string:

```bash
curl "https://canvas.instructure.com/api/v1/courses?access_token=<ACCESS-TOKEN>"
```

<a name="using-refresh-tokens"></a>
## [Using a Refresh Token to get a new Access Token](#using-refresh-tokens)
<small><a href="#top">Back to Top</a></small>

Access tokens have a 1 hour lifespan. When the refresh flow is taken, Canvas
will update the access token to a new value, reset the expiration timer, and
return the new access token as part of the response. When refreshing tokens the
user will not be asked to authorize the application again.

To refresh the access token, send a
[POST request to login/oauth2/token](file.oauth_endpoints.html#post-login-oauth2-token)
with the following parameters:

<h4>Parameters</h4>
<table>
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="mono">grant_type</td>
      <td>refresh_token</td>
    </tr>
    <tr>
      <td class="mono">client_id</td>
      <td><span class="label">Your client_id</span></td>
    </tr>
    <tr>
      <td class="mono">client_secret</td>
      <td><span class="label">Your client_secret</span></td>
    </tr>
    <tr>
      <td class="mono">refresh_token</td>
      <td><span class="label">refresh_token from initial access_token request</span></td>
    </tr>
  </tbody>
</table>

The response to this request will not contain a new refresh token; the same
refresh token is to be reused.



## [Logging Out](file.oauth_endpoints.html#delete-login-oauth2-token)
<small><a href="#top">Back to Top</a></small>

To logout, simply send a [DELETE request to login/oauth2/token](file.oauth_endpoints.html#delete-login-oauth2-token)
