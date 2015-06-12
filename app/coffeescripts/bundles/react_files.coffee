require [
  'react'
  'react-router'
  'compiled/react_files/routes'
], (React, ReactRouter, routes) ->

  ReactRouter.run routes, ReactRouter.HistoryLocation, (HandlerComponent) ->
    Handler = React.createFactory HandlerComponent
    React.render(Handler(), document.getElementById('content'))
