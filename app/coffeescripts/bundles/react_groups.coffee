require [
  'react',
  'jsx/groups/StudentView',
], (React, StudentView) ->

  # SView = React.createElement(StudentView);
  React.render(StudentView, document.getElementById('content'))
