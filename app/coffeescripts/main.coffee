require [
  'compiled/widget/courseList'
  'compiled/helpDialog'
], (courseList, helpDialog) ->
  # eventually we'll be requiring packages, like "common" etc.
  # but this is a simple start
  courseList.init()
  helpDialog.initTriggers()
