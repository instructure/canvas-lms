define [
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
], (React, withReactDOM) ->

  DialogButtons = React.createClass

    render: withReactDOM ->
      div {}, @props.children
