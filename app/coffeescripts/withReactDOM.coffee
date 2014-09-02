define ['react'], (React) ->

  # This moves everything from React.DOM to the window, making non-jsx react
  # code far more convenient, and even a bit haml-like
  #
  # ```coffee
  # define ['react', 'compiled/withReactDOM'], (React, withDOM) ->
  #   React.createClass
  #     render: withDOM ->
  #       div {className: 'container'},
  #         ul {},
  #           li {className: 'foo'}, 'Foo'
  #           li {className: 'bar'}, 'Bar'
  # ```

  withReactDOM = (fn) ->

    ->
      old = {}

      # move it all to window
      for tagName, tag of React.DOM
        old[tagName] = window[tagName]
        window[tagName] = tag

      retVal = fn.apply(this, arguments)

      # move it all back, on the same tick so we're guaranteed not to have
      # screwed up some potential global `i` in other code
      for tagName, tag of React.DOM
        window[tagName] = old[tagName]

      retVal

