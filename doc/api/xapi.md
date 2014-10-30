xAPI with LTI tools
===================

Canvas has implemented a small piece of xAPI (Tin Can API).
<a href="http://www.adlnet.gov/tla/experience-api/">Go here to learn more about xAPI</a>.

An external tool can ask for an xAPI callback URL, and then POST back an interaction
activity to Canvas. This will update the activity time for the user in Canvas, and add a
page view for that tool. Page views will show up in the course analytics section as activity.


Instructions
=============

 * The external tool should use the substitution parameter of `$Canvas.xapi.url` in its LTI launch parameters.
 * The tool can then save the url value that is given when launched.
 * The tool POSTs to that url and signs the request with the LTI OAuth parameters.
 * The content-type should be `application/json`, with an xAPI body.
   * Here are some good examples: <a href="https://github.com/adlnet/xAPI-Spec/blob/master/xAPI.md#AppendixA">Example Statements</a>
 * The `object.id` will be logged as the page view URL.
 * `result.duration` must be an <a href="http://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 8601 duration</a> if supplied.
   * Canvas page views cap at 5 minutes for now. So any value greater than that is just logged as 5 minutes.

Here is an example of the minimum JSON that would log 3 minutes of activity for `http://example.com`:

<pre>
{
  id: "12345678-1234-5678-1234-567812345678",
  actor: {
    account: {
      homePage: "http://www.instructure.com/",
      name: "unique_name_for_user_of_some_kind_maybe_lti_user_id"
    }
  },
  verb: {
    id: "http://adlnet.gov/expapi/verbs/interacted",
    display: {
      "en-US" => "interacted"
    }
  },
  object: {
    id: "http://example.com/"
  },
  result: {
    duration: "PT3M0S"
  }
}
</pre>
