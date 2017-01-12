define ['react', 'jquery'], (React, $) ->
  stubRouterContext = (Component, props, stubs) ->

    RouterStub = ->
    $.extend(RouterStub, {
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
    }, stubs)

    React.createClass
      childContextTypes:
        router: React.PropTypes.func,
        routeDepth: React.PropTypes.number

      getChildContext: ->
        router: RouterStub,
        routeDepth: 0

      render: ->
        React.createElement(Component, props)