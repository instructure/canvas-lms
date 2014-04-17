define ['ember', 'i18nObj'], (Ember, I18n) ->
  Ember.Handlebars.registerHelper 't', (translationKey, defaultValue, options) ->
    wrappers = {}
    options = options?.hash ? {}
    scope = options.scope
    delete options.scope
    for key, value of options when key.match(/^w\d+$/)
      wrappers[new Array(parseInt(key.replace('w', '')) + 2).join('*')] = value
      delete options[key]
    options.wrapper = wrappers if wrappers['*']
    options.needsEscaping = true
    options = Ember.$.extend(options, this) unless this instanceof String or typeof this is 'string'
    I18n.scoped(scope).t(translationKey, defaultValue, options)
