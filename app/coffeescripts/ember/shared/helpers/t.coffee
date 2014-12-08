define ['ember', 'i18nObj', 'str/htmlEscape'], (Ember, I18n, htmlEscape) ->
  Ember.Handlebars.registerHelper 't', (args..., hbsOptions) ->
    {hash, hashTypes, hashContexts} = hbsOptions
    options = {}
    for own key, value of hash
      type = hashTypes[key]
      if type is 'ID'
        options[key] = Ember.get(hashContexts[key], value)
      else
        options[key] = value

    wrappers = []
    while (key = "w#{wrappers.length}") and options[key]
      wrappers.push(options[key])
      delete options[key]
    options.wrapper = wrappers if wrappers.length
    new Ember.Handlebars.SafeString htmlEscape I18n.t(args..., options)

  Ember.Handlebars.registerHelper '__i18nliner_escape', htmlEscape

  Ember.Handlebars.registerHelper '__i18nliner_safe', (val) ->
    new htmlEscape.SafeString(val)

  Ember.Handlebars.registerHelper '__i18nliner_concat', (args..., options) ->
    args.join("")
