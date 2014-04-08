OAuth
=====

OAuth2 is a protocol designed to let third-party applications
authenticate to perform actions as a user, without getting the user's
password. Canvas uses OAuth2 for authentication and
authorization of the Canvas API. HTTP Basic Auth is deprecated and will be removed.

Authenticating a Request
------------------------

Once you have an OAuth access token, you can use it to make API
requests. If possible, using the HTTP Authorization header is
recommended. Sending the access token in the query string or POST
parameters is also supported.

OAuth2 Token sent in header:

    curl -H "Authorization: Bearer <ACCESS-TOKEN>" https://canvas.instructure.com/api/v1/courses

OAuth2 Token sent in query string:

    curl https://canvas.instructure.com/api/v1/courses?access_token=<ACCESS-TOKEN>

Storing Tokens
--------------

When appropriate, applications should store the token locally, rather
the requesting a new token for the same user each time the user uses the
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

Manual Token Generation
-----------------------

If your application only needs to access the API as a single user, the
simplest option is to generate an access token on the user's profile page.

  1. Click the "profile" link in the top right menu bar, or navigate to
     `/profile`
  2. Under the "Approved Integrations" section, click the button to
     generate a new access token.
  3. Once the token is generated, you cannot view it again, and you'll
     have to generate a new token if you forget it. Remember that access
     tokens are password equivalent, so keep it secret.

Logging Out
-----------

<div class="method_details">

If your application supports logout functionality, you can revoke your own
access token. This is useful for security reasons, as well as removing your
application from the list of tokens on the user's profile page. Simply make
an authenticated request to the following endpoint:

<h3 class="endpoint">DELETE /login/oauth2/token</h3>

<h4>Parameters</h4>

<ul class="argument">
  <li>
    <span class="name">expire_sessions</span>
    <div class="inline">
      optional.  Set this to '1' if you want to end all of the user's
Canvas web sessions.  Without this argument, the endpoint will leave web sessions intact.
    </div>
  </li>
</ul>

</div>

Oauth2 Based Identity Service
-----------------------------
Your application can rely on canvas for a user's identity.  During step 1 of
the web application flow below, specify the optional scopes parameter as
scopes=/auth/userinfo.  When the user is asked to grant your application
access in step 2 of the web application flow, they will also be given an
option to remember their authorization.  If they grant access and remember
the authorization, Canvas will skip step 2 of the request flow for future requests.

Canvas will not give a token back as part of a userinfo request.  It will only
provide the current user's name and id.


OAuth2 Token Request Flow
-------------------------

If your application will be used by others, you will need to implement
the full OAuth2 token request workflow, so that you can request an access
token for each user of your application.

Performing the OAuth2 token request flow requires an application client
ID and client secret. To obtain these application credentials, you will
need to register your application.  The client secret should never be shared.

For Canvas Cloud, you can request a client ID and secret from
http://www.instructure.com/partners , or contact your account
representative.

For open source Canvas users, you can generate a client ID and secret in
the Site Admin account of your Canvas install. There will be a
"Developer Keys" tab on the left navigation sidebar.

Web Application Flow
--------------------

This is the OAuth flow for third-party web applications.

### Step 1: Redirect users to request Canvas access

<div class="method_details">

<h3 class="endpoint">GET https://&lt;canvas-install-url&gt;/login/oauth2/auth</h3>

<h4>Parameters</h4>

<ul class="argument">
  <li>
    <span class="name">client_id</span>
    <div class="inline">
      required. The client id for your registered application.
    </div>
  </li>
  <li>
    <span class="name">response_type</span>
    <div class="inline">
      required. The type of OAuth2 response requested. The only
currently supported value is <code>code</code>.
    </div>
  </li>
  <li>
    <span class="name">redirect_uri</span>
    <div class="inline">
      required. The URL where the user will be redirected after
authorization. The domain of this URL must match the domain of the
redirect_uri stored on the developer key, or it must be a subdomain of
that domain.
    </div>
  </li>
  <li>
    <span class="name">scopes</span>
    <div class="inline">
      optional. This can be used to specify what information the access token
      will provide access to.  By default an access token will have access to
      all api calls that a user can make.  The only other accepted value
      for this at present is '/auth/userinfo', which can be used to obtain
      the current canvas user's identity
    </div>
  </li>
  <li>
    <span class="name">purpose</span>
    <div class="inline">
      optional. This can be used to help the user identify which instance
      of an application this token is for. For example, a mobile device
      application could provide the name of the device.
    </div>
  </li>
  <li>
    <span class="name">force_login</span>
    <div class="inline">
      optional. Set to '1' if you want to force the user to enter their
      credentials, even if they're already logged into Canvas. By default,
      if a user already has an active Canvas web session, they will not be
      asked to re-enter their credentials.
    </div>
  </li>
</ul>

</div>

### Step 2: Redirect back to the request\_uri, or out-of-band redirect

If the user accepts your request, Canvas redirects back to your
request\_uri with a specific query string, containing the OAuth2
response:

<div class="method_details">
<h3>http://www.example.com/oauth2response?code=&lt;code&gt;</h3>
</div>

The app can then extract the code, and use it along with the
client_id and client_secret to obtain the final access_key.

If the user doesn't accept the request for access, or if another error
occurs, Canvas redirects back to your request\_uri with an `error`
parameter, rather than a `code` parameter, in the query string.

<div class="method_details">
<h3>http://www.example.com/oauth2response?error=access_denied</h3>
</div>

`access_denied` is the only currently implemented error code.

### Step 3: Exchange the code for the final access token

<div class="method_details">

<h3 class="endpoint">POST /login/oauth2/token</h3>

<h4>Parameters</h4>

<ul class="argument">
  <li>
    <span class="name">client_id</span>
    <div class="inline">
      required. The client id for your registered application.
    </div>
  </li>
  <li>
    <span class="name">redirect_uri</span>
    <div class="inline">
      optional. If a redirect_uri was passed to the initial request in
      step 1, the same redirect_uri must be given here.
    </div>
  </li>
  <li>
    <span class="name">client_secret</span>
    <div class="inline">
      required. The client secret for your registered application.
    </div>
  </li>
  <li>
    <span class="name">code</span>
    <div class="inline">
      required. The code you received as a response to Step 2.
    </div>
  </li>
</ul>

<h4>Response</h4>

<p>
The response will be a JSON argument containing the access_token:
<pre class="example_code">
{
  access_token: "1/fFAGRNJru1FTz70BzhT3Zg",
}
</pre>
</p>

<ul class="argument">
  <li>
    <span class="name">access_token</span>
    <div class="inline">
      The OAuth2 access token.
    </div>
  </li>
</ul>

</div>

Native Application Flow
-----------------------

This is the OAuth flow for desktop client and mobile applications. The
application will need to embed a web browser view in order to detect and
read the out-of-band code response.

### Step 1: Redirect users to request Canvas access

<div class="method_details">

<h3 class="endpoint">GET https://&lt;canvas-install-url&gt;/login/oauth2/auth</h3>

<h4>Parameters</h4>

<ul class="argument">
  <li>
    <span class="name">client_id</span>
    <div class="inline">
      required. The client id for your registered application.
    </div>
  </li>
  <li>
    <span class="name">response_type</span>
    <div class="inline">
      required. The type of OAuth2 response requested. The only
currently supported value is <code>code</code>.
    </div>
  </li>
  <li>
    <span class="name">redirect_uri</span>
    <div class="inline">
      required. For native applications, currently the only supported value is
<code>urn:ietf:wg:oauth:2.0:oob</code>, signifying that the credentials will be
retrieved out-of-band using an embedded browser or other functionality.
    </div>
  </li>
  <li>
    <span class="name">scopes</span>
    <div class="inline">
      optional. This can be used to specify what information the access token
      will provide access to.  By default an access token will have access to
      all api calls that a user can make.  The only other accepted value
      for this at present is '/auth/userinfo', which can be used to obtain
      the current canvas user's identity
    </div>
  </li>
  <li>
    <span class="name">purpose</span>
    <div class="inline">
      optional. This can be used to help the user identify which instance
      of an application this token is for. For example, a mobile device
      application could provide the name of the device.
    </div>
  </li>
</ul>

</div>

### Step 2: Redirect back to the request\_uri, or out-of-band redirect

If the user accepts your request, Canvas redirects back to your
request\_uri (not yet implemented), or for out-of-band redirecting, to a
page on canvas with a specific query string, containing the OAuth2
response:

<div class="method_details">
<h3>/login/oauth2/auth?code=&lt;code&gt;</h3>
</div>

At this point the app should notice that the URL of the webview has
changed to contain <code>code=&lt;code&gt;</code> somewhere in the query
string. The app can then extract the code, and use it along with the
client_id and client_secret to obtain the final access_key.

If the user doesn't accept the request for access, or if another error
occurs, Canvas will add an `error`
parameter, rather than a `code` parameter, to the query string.

<div class="method_details">
<h3>/login/oauth2/auth?error=access_denied</h3>
</div>

`access_denied` is the only currently implemented error code.

### Step 3: Exchange the code for the final access token

<div class="method_details">

<h3 class="endpoint">POST /login/oauth2/token</h3>

<h4>Parameters</h4>

<ul class="argument">
  <li>
    <span class="name">client_id</span>
    <div class="inline">
      required. The client id for your registered application.
    </div>
  </li>
  <li>
    <span class="name">redirect_uri</span>
    <div class="inline">
      optional. If a redirect_uri was passed to the initial request in
      step 1, the same redirect_uri must be given here.
    </div>
  </li>
  <li>
    <span class="name">client_secret</span>
    <div class="inline">
      required. The client secret for your registered application.
    </div>
  </li>
  <li>
    <span class="name">code</span>
    <div class="inline">
      required. The code you received as a response to Step 2.
    </div>
  </li>
</ul>

<h4>Response</h4>

<p>
The response will be a JSON argument containing the access_token:
<pre class="example_code">
{
  access_token: "1/fFAGRNJru1FTz70BzhT3Zg",
}
</pre>
</p>

<ul class="argument">
  <li>
    <span class="name">access_token</span>
    <div class="inline">
      The OAuth2 access token.
    </div>
  </li>
</ul>

</div>
