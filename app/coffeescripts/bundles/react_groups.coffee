require [
  'react',
  'jsx/groups/StudentView',
], (React, StudentView) ->

  React.renderComponent(StudentView, document.getElementById('content'))
