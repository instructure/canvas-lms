define ['react'], (React) ->

  reactDomIsInjected = false

  # This is an updated version of withReactDOM which has been made
  # to work with React 0.12.x and above by using React.createFactory
  # This moves everything from React.DOM to the window, making non-jsx react
  # code far more convenient, and even a bit haml-like
  #
  # ```coffee
  # define ['react', 'compiled/react/shared/utils/withReactElement'], (React, withReactElement) ->
  #   React.createClass
  #     render: withReactElement ->
  #       div {className: 'container'},
  #         ul {},
  #           li {className: 'foo'}, 'Foo'
  #           li {className: 'bar'}, 'Bar'
  # ```

  withReactElement = (fn) ->
    availableDomElements = ["a", "abbr", "address", "area", "article", "aside", "audio", "b", "base", "bdi", "bdo", "big", "blockquote", "body", "br", "button", "canvas", "caption", "cite", "code", "col", "colgroup", "data", "datalist", "dd", "del", "details", "dfn", "dialog", "div", "dl", "dt", "em", "embed", "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hr", "html", "i", "iframe", "img", "input", "ins", "kbd", "keygen", "label", "legend", "li", "link", "main", "map", "mark", "menu", "menuitem", "meta", "meter", "nav", "noscript", "object", "ol", "optgroup", "option", "output", "p", "param", "picture", "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script", "section", "select", "small", "source", "span", "strong", "style", "sub", "summary", "sup", "table", "tbody", "td", "textarea", "tfoot", "th", "thead", "time", "title", "tr", "track", "u", "ul", "var", "video", "wbr", "circle", "defs", "ellipse", "g", "line", "linearGradient", "mask", "path", "pattern", "polygon", "polyline", "radialGradient", "rect", "stop", "svg", "text", "tspan"]

    return ->
      # to be faster, if a component above us used withReactDOM,
      # and is currently rendering, don't re-inject
      return fn.apply(this, arguments) if reactDomIsInjected

      # inject everything from React.DOM into global scope,
      # and preserve things that were already there.
      originals = {}
      for key in availableDomElements
        if key of window
          originals[key] = window[key]
        window[key] = React.createFactory(key)
      reactDomIsInjected = true

      # run provided callback
      retVal = fn.apply(this, arguments)

      # clean up, putting the things that were on window back.
      # Because JS is single threaded, by cleaning up here,
      # we're guaranteed not to screw up some potential
      # global `i` in other code. By the time our function has returned,
      # everything will be back to how it was before.
      for key in availableDomElements
        if key of originals
          window[key] = originals[key]
        else
          delete window[key]
      reactDomIsInjected = false

      # return the result of the callback
      retVal
