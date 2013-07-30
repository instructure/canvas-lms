Welcome to the Canvas LMS API Documentation
===========================================

Canvas LMS includes a REST API for accessing and modifying data
externally from the main application, in your own programs and scripts.
This documentation describes the resources that make up the API.

To get started, you'll want to review the general basics, including the
information below and the page on <a href="oauth.html">Authentication using OAuth2</a>.

Schema
------

All API access is over HTTPS, against your normal Canvas domain.

All API responses are in <a href="http://www.json.org/">JSON format</a>.

All integer ids in Canvas are 64 bit integers.

For POST and PUT requests, parameters are sent using standard
<a href="http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4">HTML form
encoding</a> (the application/x-www-form-urlencoded content type).

POST and PUT requests may also optionally be sent in <a href="http://www.json.org/">JSON format</a> format. The content-type of the request must be set to application/json in this case. There is currently no way to upload a file as part of a JSON POST, the multipart form type must be used.

As an example, this HTML form request:

    name=test+name&file_ids[]=1&file_ids[]=2&sub[name]=foo&sub[message]=bar

would translate into this JSON request:

    { "name": "test name", "file_ids": [1,2], "sub": { "name": "foo", "message": "bar" } }

With either encoding, all timestamps are sent and returned in ISO 8601 format (UTC time zone):

    YYYY-MM-DDTHH:MM:SSZ

Authentication
--------------

API authentication is done with OAuth2. If possible, using the HTTP
Authorization header is recommended. Sending the access token in the
query string or POST parameters is also supported.

OAuth2 Token sent in header:

    curl -H "Authorization: Bearer <ACCESS-TOKEN>" https://canvas.instructure.com/api/v1/courses

OAuth2 Token sent in query string:

    curl https://canvas.instructure.com/api/v1/courses?access_token=<ACCESS-TOKEN>

Read more about <a href="oauth.html">OAuth2 and how to get access tokens.</a>

API Terms of Service
--------------------

Please carefully review <a href="http://www.instructure.com/policies/api-policy">The Canvas Cloud API Terms of Service</a> before using the API.

SSL
---

Note that if you make an API call using HTTP instead of HTTPS, you will
be redirected to HTTPS. However, at that point, the credentials
have already been sent in clear over the internet. Please make
sure that you are using HTTPS.

About this Documentation
------------------------

This documentation is generated directly from the Canvas LMS code
itself. You can generate this documentation yourself if you've set up a
local Canvas environment following the instructions on <a href="https://www.github.com/instructure/canvas-lms/wiki">Github</a>,
run the following command from your Canvas directory:

    bundle exec rake doc:api

