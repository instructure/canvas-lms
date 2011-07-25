OAuth
=====

OAuth2 is a protocol designed to let third-party applications request
authorization to perform actions as a user, without getting the user's
password. This is the preferred method of authentication and
authorization for the Canvas API, rather than HTTP Basic Auth.

You will need to register your application to get started. A registered
third-party application is assigned a unique client ID and client
secret. The secret should never be shared.

For desktop and mobile applications, it's recognized that the client
secret can never be completely secured against discovery. However,
clients should do their best to make the secret non-obvious through
obfuscation or other means.

Web Application Flow
--------------------

Continue to use HTTP Basic Authentication for now, as described in the
Basics section of this doc. The OAuth2 flow will be extended to support
web applications in the near future.

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
      optional. The URL where the user will be redirected after
authorization. Currently, the only supported value is
<code>urn:ietf:wg:oauth:2.0:oob</code>, signifying that the credentials will be
retrieved out-of-band using and embedded browser or other functionality.
This functionality will be expanded later, for third-party web
application usage.
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

### Step 4: Using the access token to access the API

The access token allows you to make requests to the API on behalf of the
user, e.g.

<div class="method_details">

<h3>GET https://&lt;canvas-install-url&gt;/api/v1/courses.json?access_token=&lt;token&gt;</h3>

</div>
