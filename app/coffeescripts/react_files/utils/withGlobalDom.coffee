define ['react'], (React) ->

  window = this

  globalDomInjected = false

  withGlobalDom = (fn) ->
    return ->
      # to be faster, if a component above us used withGlobalDom,
      # and is currently rendering, don't re-inject
      return fn.apply(this, arguments) if globalDomInjected

      # inject everything on React.DOM into global scope,
      # and preserve things that were already there.
      originals = {}
      for key of React.DOM
        if key of window
          originals[key] = window[key]
        window[key] = React.DOM[key]
      globalDomInjected = true

      # run provided callback
      res = fn.apply(this, arguments)

      # clean up, putting the things we preserved back.
      for key of React.DOM
        if key of originals
          window[key] = originals[key]
        else
          delete window[key]
      globalDomInjected = false

      # return the result of the callback
      res
