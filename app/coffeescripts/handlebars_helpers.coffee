define [
  'timezone'
  'compiled/util/enrollmentName'
  'handlebars'
  'i18nObj'
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/util/semanticDateRange'
  'compiled/util/dateSelect'
  'compiled/util/mimeClass'
  'compiled/str/convertApiUserContent'
  'compiled/str/TextHelper'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'translations/_core_en'
], (tz, enrollmentName, Handlebars, I18n, $, _, htmlEscape, semanticDateRange, dateSelect, mimeClass, convertApiUserContent, textHelper) ->

  Handlebars.registerHelper name, fn for name, fn of {
    t : (args..., options) ->
      wrappers = {}
      options = options?.hash ? {}
      for key, value of options when key.match(/^w\d+$/)
        wrappers[new Array(parseInt(key.replace('w', '')) + 2).join('*')] = value
        delete options[key]
      options.wrapper = wrappers if wrappers['*']
      unless this instanceof Window
        options[key] = this[key] for key in this
      new Handlebars.SafeString htmlEscape(I18n.t(args..., options))

    __i18nliner_escape: (val) ->
      htmlEscape val

    __i18nliner_safe: (val) ->
      new htmlEscape.SafeString(val)

    __i18nliner_concat: (args..., options) ->
      args.join("")

    hiddenIf : (condition) -> " display:none; " if condition

    hiddenUnless : (condition) -> " display:none; " unless condition

    semanticDateRange : ->
      new Handlebars.SafeString semanticDateRange arguments...

    # expects: a Date object or an ISO string
    contextSensitiveDatetimeTitle : (datetime, {hash: {justText}})->
      localDatetime = $.datetimeString(datetime)
      titleText = localDatetime
      if ENV and ENV.CONTEXT_TIMEZONE and (ENV.TIMEZONE != ENV.CONTEXT_TIMEZONE)
        localText = I18n.t('#helpers.local','Local')
        courseText = I18n.t('#helpers.course', 'Course')
        courseDatetime = $.datetimeString(datetime, timezone: ENV.CONTEXT_TIMEZONE)
        if localDatetime != courseDatetime
          titleText = "#{htmlEscape localText}: #{htmlEscape localDatetime}<br>#{htmlEscape courseText}: #{htmlEscape courseDatetime}"

      if justText
        new Handlebars.SafeString titleText
      else
        new Handlebars.SafeString "data-tooltip data-html-tooltip-title=\"#{htmlEscape titleText}\""

    # expects: a Date object or an ISO string
    friendlyDatetime : (datetime, {hash: {pubdate, contextSensitive}}) ->
      return unless datetime?
      datetime = tz.parse(datetime) unless _.isDate datetime
      fudged = $.fudgeDateForProfileTimezone(tz.parse(datetime))
      timeTitle = ""
      if contextSensitive and ENV and ENV.CONTEXT_TIMEZONE
        timeTitle = Handlebars.helpers.contextSensitiveDatetimeTitle(datetime, hash: {justText: true})
      else
        timeTitle = htmlEscape $.datetimeString(datetime)

      new Handlebars.SafeString "<time data-tooltip data-html-tooltip-title='#{htmlEscape timeTitle}' datetime='#{datetime.toISOString()}' #{$.raw('pubdate' if pubdate)}>#{$.friendlyDatetime(fudged)}</time>"


    fudge: (datetime) ->
      $.fudgeDateForProfileTimezone(datetime)

    unfudge: (datetime) ->
      $.unfudgeDateForProfileTimezone(datetime)

    # expects: a Date object or an ISO string
    formattedDate : (datetime, format, {hash: {pubdate}}) ->
      return unless datetime?
      datetime = tz.parse(datetime) unless _.isDate datetime
      new Handlebars.SafeString "<time data-tooltip title='#{$.datetimeString(datetime)}' datetime='#{datetime.toISOString()}' #{$.raw('pubdate' if pubdate)}>#{htmlEscape datetime.toString(format)}</time>"

    # IMPORTANT: these next two handlebars helpers emit profile-timezone
    # human-formatted strings. don't send them as is to the server (you can
    # parse them with tz.parse(), or preferably not use these values at all
    # when sending to the server, instead using a machine-formatted value
    # stored elsewhere).

    # expects: anything that $.datetimeString can handle
    datetimeFormatted : (datetime, localized=true) ->
      $.datetimeString(datetime, {localized: localized})

    # Strips the time information from the datetime and accounts for the user's
    # timezone preference. expects: anything tz() can handle
    dateString : (datetime) ->
      return '' unless datetime
      tz.format(datetime, '%m/%d/%Y')

    # Convert the total amount of minutes into a Hours:Minutes format.
    minutesToHM : (minutes) ->
      hours = Math.floor(minutes / 60)
      real_minutes = minutes % 60
      real_min_str = (if real_minutes < 10 then "0" + real_minutes else real_minutes)
      "#{hours}:#{real_min_str}"

    # helper for easily creating icon font markup
    addIcon : (icontype) ->
      new Handlebars.SafeString "<i class='icon-#{htmlEscape icontype}'></i>"

    # helper for using date.js's custom toString method on Date objects
    dateToString : (date = '', format) ->
      date.toString(format)

    # convert a date to a string, using the given i18n format in the date.formats namespace
    tDateToString : (date = '', i18n_format) ->
      return '' unless date
      I18n.l "date.formats.#{i18n_format}", date

    # convert a date to a time string, using the given i18n format in the time.formats namespace
    tTimeToString : (date = '', i18n_format) ->
      return '' unless date
      I18n.l "time.formats.#{i18n_format}", date

    tTimeHours : (date = '') ->
      if date.getMinutes() == 0 and date.getSeconds() == 0
        I18n.l "time.formats.tiny_on_the_hour", date
      else
        I18n.l "time.formats.tiny", date

    # convert an event date and time to a string using the given date and time format specifiers
    tEventToString : (date = '', i18n_date_format = 'short', i18n_time_format = 'tiny') ->
      I18n.t 'time.event',
        defaultValue: '%{date} at %{time}',
        date: I18n.l "date.formats.#{i18n_date_format}", date
        time: I18n.l "time.formats.#{i18n_time_format}", date

    # formats a date as a string, using the given i18n format string
    strftime : (date = '', fmtstr) ->
      I18n.strftime date, fmtstr

    ##
    # outputs the format preferred for date inputs to prompt KB and SR
    # users with for interacting with datepickers
    #
    # @public
    #
    # @param {string} format defaults to 'datetime', if 'date' only returns
    #   the date portion of the format, same for 'time'
    #
    # @returns {String} the format to include for all datepickers
    accessibleDateFormat: (format='datetime')->
      if format is 'date'
        I18n.t "#helpers.accessible_date_only_format", "YYYY-MM-DD"
      else if format is 'time'
        I18n.t "#helpers.accessible_time_only_format", "hh:mm"
      else
        I18n.t "#helpers.accessible_date_format", "YYYY-MM-DD hh:mm"

    ##
    # outputs the prompt to include in labels attached to date pickers for
    # screenreader consumption
    #
    # @public
    #
    # @param {string} format defaults to 'datetime', if 'date' only returns
    #   the date portion of the format, same for 'time'
    #
    # @returns {String} the prompt for telling SRs about how to
    #   input a date
    datepickerScreenreaderPrompt: (format='datetime')->
      promptText = I18n.t "#helpers.accessible_date_prompt", "Format Like"
      format = Handlebars.helpers.accessibleDateFormat(format)
      "#{promptText} #{format}"

    mimeClass: mimeClass

    # use this method to process any user content fields returned in api responses
    # this is important to handle object/embed tags safely, and to properly display audio/video tags
    convertApiUserContent: (html, {hash}) ->
      content = convertApiUserContent(html, hash)
      # if the content is going to get picked up by tinymce, do not mark as safe
      # because we WANT it to be escaped again.
      content = new Handlebars.SafeString content unless hash and hash.forEditing
      content

    newlinesToBreak : (string) ->
      # Convert a null to an empty string so it doesn't blow up.
      string ||= ''
      new Handlebars.SafeString htmlEscape(string).replace(/\n/g, "<br />")

    not: (arg) -> !arg

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

    # runs block if *ALL* arguments are truthy
    # usage:
    # {{#ifAll arg1 arg2 arg3 arg}}
    #   everything was truthy
    # {{else}}
    #   something was falsey
    # {{/ifAll}}
    ifAll: ->
      [args..., {fn, inverse}] = arguments
      for arg in args
        return inverse(this) unless arg
      fn(this)

    # runs block if *ANY* arguments are truthy
    # usage:
    # {{#ifAny arg1 arg2 arg3 arg}}
    #   something was truthy
    # {{else}}
    #   all were falsy
    # {{/ifAny}}
    ifAny: ->
      [args..., {fn, inverse}] = arguments
      for arg in args
        return fn(this) if arg
      inverse(this)

    # {{#eachWithIndex records}}
    #   <li class="legend_item{{_index}}"><span></span>{{Name}}</li>
    # {{/each_with_index}}
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

    # runs block if the setting is set to the value
    # usage:
    # {{#ifSettingIs some_setting some_value}}
    #   The setting is set to the thing!
    # {{else}}
    #   The setting is set to something else or doesn't exist
    # {{/ifSettingIs}}
    ifSettingIs: ->
      [setting, value, {fn, inverse}] = arguments
      settings = ENV.SETTINGS
      return fn(this) if settings[setting] == value
      inverse(this)

    # evaluates the block for each item in context and passes the result to $.toSentence
    toSentence: (context, options) ->
      results = _.map(context, (c) -> options.fn(c))
      $.toSentence(results)

    dateSelect: (name, options) ->
      new Handlebars.SafeString dateSelect(name, options.hash).html()

    ##
    # usage:
    #   if 'this' is {human: true}
    #   and you do: {{checkbox "human"}}
    #   you'll get: <input name="human" type="hidden" value="0" />
    #               <input type="checkbox"
    #                      value="1"
    #                      id="human"
    #                      checked="true"
    #                      name="human" >
    # you can pass custom attributes and use nested properties:
    #   if 'this' is {likes: {tacos: true}}
    #   and you do: {{checkbox "likes.tacos" class="foo bar"}}
    #   you'll get: <input name="likes[tacos]" type="hidden" value="0" />
    #               <input type="checkbox"
    #                      value="1"
    #                      id="likes_tacos"
    #                      checked="true"
    #                      name="likes[tacos]"
    #                      class="foo bar" >
    # you can append a unique string to the id with uniqid:
    #   if you pass id=someid" and uniqid=true as parameters
    #   the result is like doing id="someid-{{uniqid}}" inside a manually
    #   created input tag.
    checkbox: (propertyName, {hash}) ->
      splitPropertyName = propertyName.split(/\./)
      snakeCase = splitPropertyName.join('_')

      if hash.prefix
        splitPropertyName.unshift hash.prefix
        delete hash.prefix

      bracketNotation = splitPropertyName[0] + _.chain(splitPropertyName)
                                                .rest()
                                                .map((prop) -> "[#{prop}]")
                                                .value()
                                                .join('')
      inputProps = _.extend
        type: 'checkbox'
        value: 1
        id: snakeCase
        name: bracketNotation
      , hash

      unless inputProps.checked?
        value = _.reduce(splitPropertyName, ((memo, key) -> memo[key] if memo?), this)
        inputProps.checked = true if value

      for prop in ['checked', 'disabled']
        if inputProps[prop]
          inputProps[prop] = prop
        else
          delete inputProps[prop]

      if inputProps.uniqid and inputProps.id
        inputProps.id += "-#{Handlebars.helpers.uniqid.call this}"
      delete inputProps.uniqid

      attributes = for key, val of inputProps when val?
        "#{htmlEscape key}=\"#{htmlEscape val}\""

      hiddenDisabledHtml = if inputProps.disabled then "disabled" else ""

      new Handlebars.SafeString """
        <input name="#{htmlEscape inputProps.name}" type="hidden" value="0" #{hiddenDisabledHtml}>
        <input #{$.raw attributes.join ' '} />
      """

    toPercentage: (number) ->
      parseInt(100 * number) + "%"

    toPrecision: (number, precision) ->
      if number
        parseFloat(number).toPrecision(precision)
      else
        ''

    checkedIf: ( thing, thingToCompare, hash ) ->
      if arguments.length == 3
        if thing == thingToCompare
          'checked'
        else
          ''
      else
        if thing then 'checked' else ''

    selectedIf: ( thing, thingToCompare, hash ) ->
      if arguments.length == 3
        if thing == thingToCompare
          'selected'
        else
          ''
      else
        if thing then 'selected' else ''

    disabledIf: ( thing, hash ) ->
      if thing then 'disabled' else ''

    checkedUnless: ( thing ) ->
      if thing then '' else 'checked'

    join: ( array, separator = ',', hash ) ->
      return '' unless array
      array.join(separator)

    ifIncludes: ( array, thing, options ) ->
      return false unless array
      if thing in array
        options.fn( this )
      else
        options.inverse( this )

    disabledIfIncludes: ( array, thing ) ->
      return '' unless array
      if thing in array
        'disabled'
      else
        ''
    truncate_left: ( string, max ) ->
       return Handlebars.Utils.escapeExpression(textHelper.truncateText(string.split("").reverse().join(""), {max: max}).split("").reverse().join(""))

    truncate: ( string, max ) ->
      return Handlebars.Utils.escapeExpression(textHelper.truncateText(string, {max: max}))

    escape_html: (string) ->
      htmlEscape string

    enrollmentName: enrollmentName

    # Public: Print an array as a comma-separated list.
    #
    # separator - The string to separate values with (default: ', ')
    # propName - If array elements are objects, this is the object property
    #            that should be printed (default: null).
    # limit - Only display the first n results of the list, following by "end." (default: null)
    # end - If the list is truncated, display this string at the end of the list (default: '...').
    #
    # Examples
    #   values = [1,2,3]
    #   complexValues = [{ id: 1 }, { id: 2 }, { id: 3 }]
    #   {{list values}} #=> 1, 2, 3
    #   {{list values separator=";"}} #=> 1;2;3
    #   {{list complexValues propName="id"}} #=> 1, 2, 3
    #   {{list values limit=2}} #=> 1, 2...
    #   {{list values limit=2 end="!"}} #=> 1, 2!
    #
    # Returns a string.
    list: (value, options) ->
      _.defaults(options.hash, separator: ', ', propName: null, limit: null, end: '...')
      {propName, limit, end, separator} = options.hash
      result = _.map value, (item) ->
        if propName then item[propName] else item
      result = result.slice(0, limit) if limit
      string = result.join(separator)
      if limit and value.length > limit then "#{string}#{end}" else string

    titleize: (str) ->
      return '' unless str
      words = str.split(/[ _]+/)
      titleizedWords = _(words).map (w) -> w[0].toUpperCase() + w.slice(1)
      titleizedWords.join(' ')

    uniqid: (context) ->
      context = @ if arguments.length <= 1
      unless context._uniqid_
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        context._uniqid_ = (chars.charAt(Math.floor(Math.random() * chars.length)) for [1..8]).join ''
      return context._uniqid_

    # Public: Render a child Backbone view.
    #
    # backboneView - A class that extends from Backbone.View.
    #
    # Examples
    #   childView = Backbone.View.extend(...)
    #
    #   {{view childView}}
    #
    # Returns the child view's HTML.
    view: (backboneView) ->
      onNextFrame = (fn) -> (window.requestAnimationFrame or setTimeout)(fn, 0)
      id          = "placeholder-#{$.guid++}"
      replace     = ->
        $span = $("##{id}")
        if $span.length then $span.replaceWith(backboneView.$el) else onNextFrame(replace)

      backboneView.render()
      onNextFrame(replace)
      new Handlebars.SafeString("<span id=\"#{id}\">pk</span>")

    # Public: yields the first non-nil argument
    #
    # Examples
    #   Name: {{or display_name short_name 'Unknown'}}
    #
    # Returns the first non-null argument or null
    or: (args..., options) ->
      for arg in args when arg
        return arg

    # Public: returns icon for outcome mastery level
    #
    addMasteryIcon: (status, options={}) ->
      iconType = {
        'exceeds': 'check-plus'
        'mastery': 'check'
        'near': 'plus'
      }[status] or 'x'
      new Handlebars.SafeString "<i aria-hidden='true' class='icon-#{htmlEscape iconType}'></i>"

  }

  return Handlebars
