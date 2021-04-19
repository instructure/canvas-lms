Developer Keys
==============

Developer keys are OAuth2 client ID and secret pairs stored in Canvas that allow third-party applications to request access to Canvas API endpoints via the [OAuth2 flow](file.oauth.html). Access is granted after a user authorizes an app and Canvas creates an API access token that’s returned in the final request of the OAuth2 flow.

Developer keys created in a root account, by root account administrators or Instructure employees, are only functional for the account they are created in and its sub-accounts. Developer keys created globally, by an Instructure employee, are functional in any Canvas account where they are enabled.

By scoping the tokens, Canvas allows root account administrators to manage the specific API endpoints that tokens issued from a developer key have access to.

## Developer Key Scopes
Developer key scopes allow root account administrators to restrict the tokens issued from developer keys to a subset of Canvas API endpoints in their account.

Developer keys may be scoped or unscoped. Unscoped keys will have access to all Canvas resources available to the authorizing user. The following applies to scoped developer keys only:

### What are developer key scopes in Canvas?
Each Canvas API endpoint has an associated scope. Canvas developer key scopes can only be enabled/disabled by a root account administrator or an Instructure employee.

Scopes take the following form:
```
url:<HTTP Verb>|<Canvas API Endpoint Path>
```
For example, the corresponding scope for the `GET /api/v1/courses/:course_id/rubrics` API endpoint would be
```
url:GET|/api/v1/courses/:course_id/rubrics
```
### How do developer key scopes function?
When requesting an access token, third-party applications should specify a `scope` parameter (see the [oauth endpoints documentation](file.oauth_endpoints.html#get-login-oauth2-auth)). The requested scopes must be a subset of the scopes set for the developer key.

When a client makes any API request, Canvas will verify the requested endpoint's scope has been granted by the account administrator to the developer key of the request's access token.

If the requested endpoint's scope has not been granted Canvas will respond with `401 Unauthorized`.

### Who can grant or revoke scopes for a developer key?
For developer keys created in a specific root account, administrators for that account may grant or revoke scopes. When requesting a developer key, application owners should communicate with administrators which scopes their integrations require.

For global developer keys, an Instructure employee may grant or revoke scopes.

*Note:* If a scope is removed from a developer key, all access tokens derived from that key will be invalidated. In this case, clients should request a new access token.

### Where can I see what scopes are available?
View the complete list of [token scopes](api_token_scopes.html).
Scopes may also be found beneath their corresponding endpoints in the "resources" documentation pages.

## Developer Key Management
Developer key management features allow root account administrators to turn global developer keys "on" and "off" for only their account.

### What management features are available?
Root account administrators may enable or disable global developer keys for their specific account. This means that vendors who wish to have integrations that work in any Canvas account may request a global developer key from Instructure allowing account administrators enable the key for their account.

### How do management features function?
When a client uses the [OAuth2 Auth endpoint](file.oauth_endpoints.html#get-login-oauth2-auth) as part of the flow to retrieve an access token canvas will check the developer key associated with the `client_id`. If the developer key is not enabled in the requested account, Canvas will respond with `unauthorized_client`.

When a client makes any API request, Canvas will check the developer key associated with the access token used in the request. If the developer key is not enabled for the requested account, Canvas will respond with `401 Unauthorized`.

## Other Considerations
### Maximum number of scopes
When clients request an access token they may specify what scopes the token needs (see the [oauth endpoints documentation](file.oauth_endpoints.html#get-login-oauth2-auth)). Because the client sends the scopes they require in a GET request, the maximum number of scopes one access token can specify is limited by the maximum HTTP header size Canvas allows (8000 chars).

On average, an access token may use up to 110 scopes. This number will vary depending on the actual length of the scopes used and any other headers sent in the [login oauth2 request](file.oauth_endpoints.html#get-login-oauth2-auth) along with the scopes.

If the number of scopes required by the client exceeds this limitation, a second access token with the remaining scopes should be requested.

### Canvas API Includes
Several Canvas APIs allow specifying an `include` parameter. This parameter allows nesting resources in JSON responses. For example, a request to the [assignment index endpoint](assignments.html#method.assignments_api.index) could be made to include the submission objects for each assignment.

Responses to requests made with a scoped access token only support this functionality when the 'Allow Include Parameters' option is also enabled.  When this option is disabled, a request is made with a scoped token Canvas will ignore `include` and `includes` parameters.

### Developer Key Scope Changes
During the lifetime of a developer key, scopes may be added or removed by account administrators. Below is a description of possible changes and how each will affect access tokens:

#### New scopes are added to a developer key
Access tokens issued prior to the addition of the new scope will continue to function. These access tokens will not, however, be usable with the new scope. To access the newly added resources clients should request a new access token with scopes. The requested scopes must be a subset of the scopes on the developer key.

#### Scopes are removed from a developer key
Access tokens issued prior to the removal of the scope(s) will *not* continue to function. Clients should request a new access token with scopes. The requested scopes must be a subset of the scopes on the developer key.

#### An unscoped developer key becomes scoped
Access tokens issued prior to the change will *not* continue to function. Clients should request a new access token with scopes. The requested scopes must be a subset of the scopes on the developer key.

If the client attempts to request a new access token without specifying scopes Canvas will respond with an error.

For details on unscoped vs scoped developer key see `Developer Key Scopes` above.
#### A scoped developer key becomes unscoped
Access tokens issued prior to the change will continue to function *and* have access to all resources of the authorizing user. Clients may continue to request scoped access tokens, but these tokens will be functional for all resources available to the authorizing user.

For details on unscoped vs scoped developer key see `Developer Key Scopes` above.
