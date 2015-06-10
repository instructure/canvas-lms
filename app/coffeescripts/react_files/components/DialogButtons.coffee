define [
  'react'
  'compiled/react/shared/utils/withReactElement'
], (React, withReactElement) ->

  DialogButtons = React.createClass

    displayName: 'DialogButtons'

    render: withReactElement ->
      div {}, @props.children
