# This can go away once react-router can make inline redirectors for us

define ['react'], (React) ->

  redirectToRootFolder = React.createClass
    render: ->
    statics:
      willTransitionTo: (transition, params, query) ->
        transition.redirect('rootFolder', params, query)
