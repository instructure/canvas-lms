Welcome to the Canvas LMS API Documentation
===========================================

Canvas LMS includes a REST API for accessing and modifying data
externally from the main application, in your own programs and scripts.

The API is currently under rapid development and many areas of the
application are still unavailable via the external API, but you can get
started on what's there today by learning the Basics and then viewing
information on the exposed Resource types.

Schema
------

All API responses are in <a href="http://www.json.org/">JSON format</a>.

SSL
---

Canvas Cloud Edition requires all API access to be over SSL, using
HTTPS. By default, open source installs have this requirement as well.
Open source installs are strongly encouraged to require SSL for API
calls, since the username and password are sent in the clear for HTTP
Basic Auth, or the access token for oauth, if SSL is not used.

Note that if you make an API call using HTTP instead of HTTPS, you will
be redirected to HTTPS. However, at that point, the credentials
have already been sent in clear over the internet. Please make
sure that you are using HTTPS.

About this Documentation
------------------------

This documentation is generated directly from the Canvas LMS code
itself, using YARD. You can generate this documentation yourself if
you've set up a local canvas environment following the instructions on
<a href="https://www.github.com/instructure/canvas-lms/wiki">Github</a>, run
the following command from your canvas directory:

    $ rake doc:api

