define [
    'backbone',
    'jsx/accounts/AssignObservers',
    'react',
    'react-dom'
    ], (Backbone, AssignObservers, React, ReactDOM) ->

    class AssignObserversView extends Backbone.View
      el:
        document.getElementById('assign-observers-container')

      initialize: (options) ->
        @render()

      render: ->
        AssignObserversElement = React.createElement(
          AssignObservers,
          users: @collection
        )
        ReactDOM.render(AssignObserversElement, @el)