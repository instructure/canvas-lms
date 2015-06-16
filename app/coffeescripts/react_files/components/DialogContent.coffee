define [
  'react'
  'compiled/react/shared/utils/withReactElement'
], (React, withReactElement) ->

  DialogContent = React.createClass

    displayName: 'DialogContent'

    render: withReactElement ->
      div {}, @props.children
