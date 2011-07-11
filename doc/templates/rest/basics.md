Request/Response Basics
=======================

Schema
------

All API access is over HTTP and is of the form

    /api/v1/<path>.json

All responses are in <a href="http://www.json.org/">JSON format</a>.
Additional response formats may be added in the future.

Authentication
--------------

### Access Tokens

You can use access tokens to authenticate as any user in the system.
Currently access tokens must be created by the user and then given to
the third party for use.  Access tokens can be generated from the user's
profile page.

Note that all requests will need the
"access_token" query parameter set, not just the first request.
Most API calls will only return data that is visible to the
authenticated user.  For example, to list the courses that
your user is enrolled in as a teacher:

    $ curl https://canvas.instructure.com/api/v1/courses.json?access_token=USER_PROVIDED_ACCESS_TOKEN | jsonpretty
    [
      {
        "name": "First Course",
        "id": 123456,
        "course_code": "Course-1",
        "enrollments": [
          {
            "type": "teacher"
          },
          {
            "type": "ta"
          }
        ]
      },
      {
        "name": "Second Course",
        "id": 54321,
        "course_code": "Course-2",
        "enrollments": [
          {
            "type": "teacher"
          }
        ]
      }
    ]

### HTTP Basic Auth

*This authentication approach is deprecated*

You can use HTTP Basic Auth to authenticate with any username/password
combination. Note that all requests will need the Authentication header,
not just the first request. Most API calls will only return data that is
visible to the authenticated user. For example, to list the courses that
your user is enrolled in as a teacher:

    $ curl -u 'YOUR_USER:YOUR_PASS' \
      https://canvas.instructure.com/api/v1/courses.json | jsonpretty
    [
      {
        "name": "First Course",
        "id": 123456,
        "course_code": "Course-1",
        "enrollments": [
          {
            "type": "teacher"
          },
          {
            "type": "ta"
          }
        ]
      },
      {
        "name": "Second Course",
        "id": 54321,
        "course_code": "Course-2",
        "enrollments": [
          {
            "type": "teacher"
          }
        ]
      }
    ]

SSL
---

Canvas Cloud Edition requires all API access to be over SSL, using
HTTPS. By default, open source installs have this requirement as well.
Open source installs are strongly encouraged to require SSL for API
calls, since the username and password are sent in the clear for HTTP
Basic Auth if SSL is not used.

Note that if you make an API call using HTTP instead of HTTPS, you will
be redirected to HTTPS. However, at that point, the username and
password have already been sent in clear over the internet. Please make
sure that you are using HTTPS.

API Keys
--------

GET requests to the API can be made with any valid username/password
combination. However, any modifying request such as a PUT, POST or
DELETE will require a developer API key to be sent with the request
data. Contact your Canvas LMS administrator to request an API key.

The API is a work in progress, and the web UI for managing API keys is
still in development. If you are running your own Canvas LMS instance,
you will need to generate an API key from the Rails console:

    $ script/console
    > key = DeveloperKey.create!(
        :email => 'your_email',
        :user_name => 'your name',
        :account => Account.default)
    > puts key.api_key

The value of `api_key` is the token you'll need to send with every
request, for example:

    /api/v1/courses.json?api_key=YOUR_KEY

If you have trouble getting your Rails console to start, please see the
Rails console section on our <a href="https://github.com/instructure/canvas-lms/wiki/Troubleshooting">Troubleshooting wiki page</a>.

Object IDs
----------

Throughout the API, objects are referenced by internal ids. You can also
reference objects by sis id, by prepending the sis id with the name of
the sis field, like "sis\_course\_id:". For instance, to retrieve the
list of assignments for a course with sis id of 'A1234':

    /api/v1/courses/sis_course_id:A1234/assignments.json
