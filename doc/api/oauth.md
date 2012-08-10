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

OAuth2 Token Request Flow
-------------------------

If your application will be used by others, you will need to implement
the full OAuth2 token request workflow, so that you can request an access
token for each user of your application.

Performing the OAuth2 token request flow requires an application client
ID and client secret. To obtain these application credentials, you will
need to register your application.  The client secret should never be shared.

For open source Canvas users, you will need to generate a client\_id and
client\_secret for your application. There isn't yet any UI for
generating these keys, so you will need to generate an API key from the Rails console:

    $ script/console
    > key = DeveloperKey.create! { |k|
        k.email = 'your_email'
        k.user_name = 'your name'
        k.account = Account.default
      }
    > puts "client_id: #{key.global_id} client_secret: #{key.api_key}"

Web Application Flow
--------------------

This is the OAuth flow for third-party web applications.

### Step 1: Redirect users to request Canvas access

<div class="method_details">

<h3>GET https://&lt;canvas-install-url&gt;/login/oauth2/auth</h3>

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
redirect_uri stored on the developer key, though the rest of the path
may differ.
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

<h3>POST /login/oauth2/token</h3>

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

<h3>GET https://&lt;canvas-install-url&gt;/login/oauth2/auth</h3>

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

<h3>POST /login/oauth2/token</h3>

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
