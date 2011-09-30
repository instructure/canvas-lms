Handlebars.registerHelper "t", (key, defaultValue, options) ->
  wrappers = {}
  options = options?.hash ? {}
  for key, value of options when key.match(/^w\d+$/)
    wrappers[new Array(parseInt(key.replace('w', '')) + 2).join('*')] = value
    delete options[key]
  options.wrapper = wrappers if wrappers['*']
  options = $.extend(options, this) unless this instanceof String or typeof this is 'string'
  I18n.scoped(options.scope).t(key, defaultValue, options)

Handlebars.registerHelper "hiddenIf", (condition) -> 
  " display:none; " if condition

Handlebars.registerHelper "hiddenUnless", (condition) -> 
  " display:none; " unless condition