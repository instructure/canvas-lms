define [
  'react'
  '../utils/withGlobalDom'
], (React, withGlobalDom) ->

  PushStateLink = React.createClass

    handleClick: (event) ->
      event.preventDefault()
      window.history.replaceState(null, null, this.props.href)

    render: ->
      @transferPropsTo(React.DOM.a(onClick: @handleClick, this.props.children))