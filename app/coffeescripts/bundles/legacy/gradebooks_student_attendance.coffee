require [
  "jquery",
  "jquery.instructure_misc_helpers",
  "jquery.instructure_misc_plugins",
  "vendor/jquery.scrollTo"
], ($) ->
  $(document).ready ->
    $(document).fragmentChange (event, hash) ->
      $("#student_attendance tr.highlighted").removeClass "highlighted"
      if hash.indexOf("#assignment_") is 0
        $tr = $("#" + hash.substring(1)).parents("tr")
        $tr.addClass "highlighted"
        $("html,body").scrollTo $tr