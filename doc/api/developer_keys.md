Developer Keys
==============
Developer keys are OAuth2 client ID and secret pairs stored in Canvas that allow third-party applications to request access to Canvas API endpoints via the [OAuth2 flow](https://canvas.instructure.com/doc/api/file.oauth.html). Access is granted after a user authorizes an app and Canvas creates an API access token that’s returned in the final request of the OAuth2 flow.

Developer keys created in a root account, by root account administrators or Instructure employees, are only functional for the account they are created in and its sub-accounts. Developer keys created globally, by an Instructure employee, are functional in any Canvas account where they are enabled.

By scoping the tokens, Canvas allows root account administrators to manage the specific API endpoints that tokens issued from a developer key have access to.

## Developer Key Scopes
Developer key scopes allow root account administrators to restrict the tokens issued from developer keys to a subset of Canvas API endpoints in their account.

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
When a client makes any API request, Canvas will verify the requested endpoint's scope has been granted by the account administrator to the developer key of the request's access token.

If the requested endpoint's scope has not been granted Canvas will respond with `401 Unauthorized`.

### Who can grant or revoke scopes for a developer key?
For developer keys created in a specific root account, administrators for that account may grant or revoke scopes. When requesting a developer key, application owners should communicate with administrators which scopes their integrations require.

For global developer keys, an Instructure employee may grant or revoke scopes.

### Where can I see what scopes are available?
A complete list of available scopes can be found [here](/doc/api/file.api_token_scopes.html).
Scopes may also be found beneath their corresponding endpoints in the "resources" documentation pages.



## Developer Key Management
Developer key management features allow root account administrators to turn global developer keys "on" and "off" for only their account.

### What management features are available?
Root account administrators may enable or disable global developer keys for their specific account. This means that vendors who wish to have integrations that work in any Canvas account may request a global developer key from Instructure allowing account administrators enable the key for their account.

To request a global developer key please contact: partnersupport@instructure.com
Please include:
- A list of Redirect URI’s that your app uses
- An Icon URL. This will be shown on the authorization screen.
- The scopes the key requires access to and how the data will be used (ex: We need access to `url:GET|/api/v1/courses/:course_id/rubrics` since we return this data in a custom analytics dashboard). Ideally, this information would be already contained within your integration documentation and a link to the documentation should suffice.
- Describe the security policy surrounding how developer keys and tokens will be stored.
- A point of contact (email address) at the company. Ideally, this will be an account that is accessible even if the requester leaves the company.
- Links to any relevant documentation for your integration.


### How do management features function?
When a client uses the [OAuth2 Auth endpoint](https://canvas.instructure.com/doc/api/file.oauth_endpoints.html#get-login-oauth2-auth) as part of the flow to retrieve an access token canvas will check the developer key associated with the `client_id`. If the developer key is not enabled in the requested account, Canvas will respond with `unauthorized_client`.

When a client makes any API request, Canvas will check the developer key associated with the access token used in the request. If the developer key is not enabled for the requested account, Canvas will respond with `401 Unauthorized`.