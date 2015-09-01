require [
  'jquery'
  'react'
  'jsx/assignments/ModerationApp'
], ($, React, ModerationApp) ->

  ModerationApp = React.createFactory ModerationApp
  React.render(React.createElement(ModerationApp), $('#assignment_moderation')[0])
