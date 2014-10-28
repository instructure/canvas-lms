define [], ->
  strings: (x, y) ->
    x.localeCompare(y, window.I18n.locale || 'en-US', { sensitivity: 'accent', ignorePunctuation: true, numeric: true})

  by: (f) ->
    return (x, y) =>
      @strings(f(x), f(y))

  byKey: (key) -> @by((x) -> x[key])

  byGet: (key) -> @by((x) -> x.get(key))
