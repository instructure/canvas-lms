##
# Exports all the form templates for the quick start bar
# as an object.

define [
  'jst/quickStartBar/assignment'
  'jst/quickStartBar/announcement'
  'jst/quickStartBar/message'
  'jst/quickStartBar/pin'
], (assignment, announcement, message, pin) ->

  {assignment, announcement, message, pin}

