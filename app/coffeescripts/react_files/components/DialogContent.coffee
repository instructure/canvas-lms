define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
], (React, withReactDOM) ->

  DialogContent = React.createClass

    render: withReactDOM ->
      div {}, @props.children
