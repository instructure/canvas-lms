require [
  'old_unsupported_dont_use_react'
  'compiled/react_files/routes'
], (React, routes) ->

  React.renderComponent(routes, document.getElementById('content'))
