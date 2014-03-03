require [
  "jquery",
  "jqueryui/progressbar"
], ($, _progressBar) ->
  $("#gradebook_full_content").addClass "hidden-readable"
  $("#loading_gradebook_message").show()
  $("#loading_gradebook_progressbar").progressbar value: 5
