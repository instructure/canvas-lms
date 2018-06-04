Welcome to the Canvas LMS API Documentation
===========================================

Canvas LMS includes a REST API for accessing and modifying data
externally from the main application, in your own programs and scripts.
This documentation describes the resources that make up the API.

To get started, you'll want to review the general basics, including the
information below and the page on <a href="oauth.html">Authentication using OAuth2</a>.

API Changes
------

To follow notable API changes, view the <a href="file.changelog.html">API Change Log</a>.

For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.

API Terms of Service
------

Please carefully review <a href="http://www.instructure.com/policies/api-policy">The Canvas Cloud API Terms of Service</a> before using the API.

Schema
------

All API access is over HTTPS, against your normal Canvas domain.

All API responses are in <a href="http://www.json.org/">JSON format</a>.

All integer ids in Canvas are 64 bit integers. String ids are also used in Canvas.

To force all ids to strings add the request header `Accept: application/json+canvas-string-ids`
This will cause Canvas to return even integer IDs as strings, preventing problems with languages (particularly JavaScript) that can't properly process large integers.

All boolean parameters can be passed as true/false, t/f, yes/no, y/n, on/off, or 1/0. When using JSON format, a literal true/false is preferred, rather than as a string.

For POST and PUT requests, parameters are sent using standard
<a href="http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4">HTML form
encoding</a> (the application/x-www-form-urlencoded content type).

POST and PUT requests may also optionally be sent in <a href="http://www.json.org/">JSON format</a> format. The content-type of the request must be set to application/json in this case. There is currently no way to upload a file as part of a JSON POST, the multipart form type must be used.

As an example, this HTML form request:

```bash
name=test+name&file_ids[]=1&file_ids[]=2&sub[name]=foo&sub[message]=bar&flag=y
```

would translate into this JSON request:

```json
{ "name": "test name", "file_ids": [1,2], "sub": { "name": "foo", "message": "bar" }, "flag": true }
```

With either encoding, all timestamps are sent and returned in ISO 8601 format (UTC time zone):

    YYYY-MM-DDTHH:MM:SSZ

Authentication
--------------

API authentication is done with OAuth2. If possible, using the HTTP
Authorization header is recommended. Sending the access token in the
query string or POST parameters is also supported.

OAuth2 Token sent in header:

```bash
curl -H "Authorization: Bearer <ACCESS-TOKEN>" "https://canvas.instructure.com/api/v1/courses"
```

OAuth2 Token sent in query string:

```bash
curl "https://canvas.instructure.com/api/v1/courses?access_token=<ACCESS-TOKEN>"
```

Read more about <a href="oauth.html">OAuth2 and how to get access tokens.</a>

SSL
---

Note that if you make an API call using HTTP instead of HTTPS, you will
be redirected to HTTPS. However, at that point, the credentials
have already been sent in clear over the internet. Please make
sure that you are using HTTPS.

About this Documentation
------------------------

This documentation is generated directly from the Canvas LMS code. You can generate this documentation yourself if you've set up a
local Canvas environment following the instructions on <a href="https://www.github.com/instructure/canvas-lms/wiki">Github</a>.
Run the following command from your Canvas directory:

```bash
bundle exec rake doc:api
```
