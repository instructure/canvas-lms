require [
  'old_unsupported_dont_use_react',
  'jsx/groups/StudentView',
], (React, StudentView) ->

  React.renderComponent(StudentView, document.getElementById('content'))
