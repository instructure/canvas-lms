define ['i18nObj'], (I18n) ->
  frames = []

  I18nStubber =
    pushFrame: ->
      frames.push
        locale: I18n.locale
        translations: I18n.translations
      I18n.translations = {'en': {}}

    popFrame: ->
      throw 'I18nStubber: pop without a stored frame' unless frames.length
      {locale, translations} = frames.pop()
      I18n.locale = locale
      I18n.translations = translations

    clear: ()->
      while(frames.length > 0)
        this.popFrame()


    stub: (locale, translations) ->
      throw 'I18nStubber: stub without a stored frame' unless frames.length
      scope = I18n.translations
      scope[locale] = {} unless scope[locale]
      locale = scope[locale]
      for key, value of translations
        scope = locale
        parts = key.split('.')
        last = parts.pop()
        for part in parts
          scope[part] = {} unless scope[part]
          scope = scope[part]
        scope[last] = value

    setLocale: (locale) ->
      throw 'I18nStubber: setLocale without a stored frame' unless frames.length
      I18n.locale = locale
