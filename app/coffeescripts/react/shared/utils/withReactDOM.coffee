define ['old_unsupported_dont_use_react'], (React) ->

  reactDomIsInjected = false

  # This moves everything from React.DOM to the window, making non-jsx react
  # code far more convenient, and even a bit haml-like
  #
  # ```coffee
  # define ['react', 'compiled/react/shared/utils/withReactDOM'], (React, withReactDOM) ->
  #   React.createClass
  #     render: withDOM ->
  #       div {className: 'container'},
  #         ul {},
  #           li {className: 'foo'}, 'Foo'
  #           li {className: 'bar'}, 'Bar'
  # ```

  withReactDOM = (fn) ->
    return ->
      # to be faster, if a component above us used withReactDOM,
      # and is currently rendering, don't re-inject
      return fn.apply(this, arguments) if reactDomIsInjected

      # inject everything from React.DOM into global scope,
      # and preserve things that were already there.
      originals = {}
      for key of React.DOM
        if key of window
          originals[key] = window[key]
        window[key] = React.DOM[key]
      reactDomIsInjected = true

      # run provided callback
      retVal = fn.apply(this, arguments)

      # clean up, putting the things that were on window back.
      # Because JS is single threaded, by cleaning up here,
      # we're guaranteed not to screw up some potential
      # global `i` in other code. By the time our function has returned,
      # everything will be back to how it was before.
      for key of React.DOM
        if key of originals
          window[key] = originals[key]
        else
          delete window[key]
      reactDomIsInjected = false

      # return the result of the callback
      retVal
