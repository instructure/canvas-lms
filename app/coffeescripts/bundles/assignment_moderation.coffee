require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
], ($, React, ModerationApp) ->

  React.render(ModerationApp({
    student_submissions_url: ENV.URLS.student_submissions_url
    publish_grades_url: ENV.URLS.publish_grades_url
  })
  , $('#assignment_moderation')[0])
