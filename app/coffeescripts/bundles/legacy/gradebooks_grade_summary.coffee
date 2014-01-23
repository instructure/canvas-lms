require [
  "jquery"
], ($) ->
  $(document).ready ->
    $("#course_url").change ->
      location.href = $(this).val() unless location.href is $(this).val()