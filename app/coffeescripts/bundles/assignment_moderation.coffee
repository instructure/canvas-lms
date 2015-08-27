require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
], ($, React, ModerationApp) ->

  React.render(ModerationApp(student_submissions_url: ENV.URLS.student_submissions_url), $('#assignment_moderation')[0])
