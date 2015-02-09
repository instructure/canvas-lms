define [ 'support/jquery.mockjax'], ($) ->
  $.mockjax
    url:  '/help_links*'
    responseText: [{
      text: "<a href=\"haxored\">asdf</a>asdf"
      subtext: "testing subtext"
      url: "javascript:alert('hi');"
      available_to: [ "user", "student", "teacher", "admin" ]
    },
    {
      subtext: "Have an idea to improve Canvas?"
      url: "http://help.instructure.com/forums/337215-feature-requests"
      text: "Request a Feature"
      available_to: [ "user", "student", "teacher", "admin" ]
    }]
