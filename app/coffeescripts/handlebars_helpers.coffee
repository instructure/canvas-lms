define [
  'vendor/handlebars.vm'
  'i18nObj'
  'jquery'
  'str/htmlEscape'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
], (Handlebars, I18n, $, htmlEscape) ->

  Handlebars.registerHelper name, fn for name, fn of {
    t : (key, defaultValue, options) ->
      wrappers = {}
      options = options?.hash ? {}
      for key, value of options when key.match(/^w\d+$/)
        wrappers[new Array(parseInt(key.replace('w', '')) + 2).join('*')] = value
        delete options[key]
      options.wrapper = wrappers if wrappers['*']
      options = $.extend(options, this) unless this instanceof String or typeof this is 'string'
      I18n.scoped(options.scope).t(key, defaultValue, options)

    hiddenIf : (condition) -> " display:none; " if condition

    hiddenUnless : (condition) -> " display:none; " unless condition

    friendlyDatetime : (datetime) ->
      datetime = new Date(datetime)
      new Handlebars.SafeString "<time title='#{datetime}' datetime='#{datetime.toISOString()}'>#{$.friendlyDatetime(datetime)}</time>"

    datetimeFormatted : (isoString) ->
      isoString = $.parseFromISO(isoString) unless isoString.datetime
      isoString.datetime_formatted

    mimeClass: (contentType) -> $.mimeClass(contentType)

    newlinesToBreak : (string) ->
      new Handlebars.SafeString htmlEscape(string).replace(/\n/g, "<br />")

    # runs block if all arugments are === to each other
    # usage:
    # {{#ifEqual argument1 argument2 'a string argument' argument4}}
    #   everything was equal
    # {{else}}
    #   everything was NOT equal
    # {{/ifEqual}}
    ifEqual: ->
      [previousArg, args..., {fn, inverse}] = arguments
      for arg in args
        return inverse(this) if arg != previousArg
        previousArg = arg
      fn(this)

    eachWithIndex: (context, options) ->
      fn = options.fn
      inverse = options.inverse
      ret = ''

      if context and context.length > 0
        for index, ctx of context
          ctx._index = index
          ret += fn ctx
      else
        ret = inverse this

      ret
  }
  return Handlebars
