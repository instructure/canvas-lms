define [], ->
  strings: (x, y) ->
    locale = window.I18n.locale || 'en-US'
    locale_map = {'zh_Hant': 'zh-Hant'}
    locale = locale_map[locale] || locale
    x.localeCompare(y, locale, { sensitivity: 'accent', ignorePunctuation: true, numeric: true})

  by: (f) ->
    return (x, y) =>
      @strings(f(x), f(y))

  byKey: (key) -> @by((x) -> x[key])

  byGet: (key) -> @by((x) -> x.get(key))
