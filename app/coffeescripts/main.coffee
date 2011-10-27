require [
  'compiled/widget/courseList'
], (courseList) ->
  # eventually we'll be requiring packages, like "common" etc.
  # but this is a simple start
  courseList.init()

