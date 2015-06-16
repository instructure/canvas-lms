define ['react', 'jquery'], (React, $) ->
  stubRouterContext = (Component, props, stubs) ->
    React.createClass
      childContextTypes:
        makePath: ->
        makeHref: ->
        transitionTo: ->
        replaceWith: ->
        goBack: ->
        getCurrentPath: ->
        getCurrentRoutes: ->
        getCurrentPathname: ->
        getCurrentParams: ->
        getCurrentQuery: ->
        isActive: ->
      getChildContext: ->
        $.extend {
          makePath: ->
          makeHref: ->
          transitionTo: ->
          replaceWith: ->
          goBack: ->
          getCurrentPath: ->
          getCurrentRoutes: ->
          getCurrentPathname: ->
          getCurrentParams: ->
          getCurrentQuery: ->
          isActive: ->

        }, stubs
      render: ->
        Component props