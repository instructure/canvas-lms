require [
  'react'
  'compiled/react_files/routes'
], (React, routes) ->

  React.renderComponent(routes, document.getElementById('content'))
