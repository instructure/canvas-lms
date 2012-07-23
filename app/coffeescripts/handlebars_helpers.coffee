define [
  'vendor/handlebars.vm'
  'i18nObj'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/util/semanticDateRange'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
], (Handlebars, I18n, $, _, htmlEscape, semanticDateRange) ->

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

    semanticDateRange : ->
      new Handlebars.SafeString semanticDateRange arguments...

    friendlyDatetime : (datetime, {hash: {pubdate}}) ->
      return unless datetime?
      parsed = $.parseFromISO(datetime)
      new Handlebars.SafeString "<time title='#{parsed.datetime_formatted}' datetime='#{parsed.datetime.toISOString()}' #{'pubdate' if pubdate}>#{$.friendlyDatetime(parsed.datetime)}</time>"

    datetimeFormatted : (isoString) ->
      isoString = $.parseFromISO(isoString) unless isoString.datetime
      isoString.datetime_formatted

    # helper for using date.js's custom toString method on Date objects
    dateToString : (date = '', format) ->
      date.toString(format)

    mimeClass: (contentType) -> $.mimeClass(contentType)

    # finds any <video/audio class="instructure_inline_media_comment"> and turns them into media comment thumbnails
    convertNativeToMediaCommentThumnail: (html) ->
      $dummy = $('<div />').html(html)
      $dummy.find('video.instructure_inline_media_comment,audio.instructure_inline_media_comment').replaceWith ->
        $("<a id='media_comment_#{$(this).data('media_comment_id')}'
              data-media_comment_type='#{$(this).data('media_comment_type')}'
              class='instructure_inline_media_comment' />")
      new Handlebars.SafeString $dummy.html()

    newlinesToBreak : (string) ->
      new Handlebars.SafeString htmlEscape(string).replace(/\n/g, "<br />")

    # runs block if all arguments are === to each other
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

    # runs block if all arguments are true-ish
    # usage:
    # {{#ifAll arg1 arg2 arg3 arg}}
    #   everything was true-ish
    # {{else}}
    #   something was false-y
    # {{/ifEqual}}
    ifAll: ->
      [args..., {fn, inverse}] = arguments
      for arg in args
        return inverse(this) unless arg
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

    # loop through an object's properties, exposing "property" and
    # "value."
    #
    # ex.
    #
    # obj =
    #   group_one: [
    #     { label: 'one', val: 1 }
    #     { label: 'two', val: 2 }
    #   ],
    #   group_two: [
    #     { label: 'three', val: 3 }
    #     { label: 'four', val: 4 }
    #   ]
    #
    # {{#eachProp this}}
    #   <optgroup label="{{property}}">
    #     {{#each this.value}}
    #       <option value="{{val}}">{{label}}</option>
    #     {{/each}}
    #   </optgroup>
    # {{/each}}
    #
    # outputs:
    # <optgroup label="group_one">
    #   <option value="1">one</option>
    #   <option value="2">two</option>
    # </optgroup>
    # <optgroup label="group_two">
    #   <option value="3">three</option>
    #   <option value="4">four</option>
    # </optgroup>
    #
    eachProp: (context, options) ->
      (options.fn(property: prop, value: context[prop]) for prop of context).join ''

    # evaluates the block for each item in context and passes the result to $.toSentence
    toSentence: (context, options) ->
      results = _.map(context, (c) -> options.fn(c))
      $.toSentence(results)
  }
  return Handlebars
