define [
  'i18n!calendar',
  'underscore'
  'Backbone',
  'jst/calendar/calendarNavigator'
], (I18n, _, Backbone, template) ->

  class CalendarNavigator extends Backbone.View
    template: template

    els:
      '.navigation_title'     : '$title'
      '.navigation_buttons'   : '$buttons'
      '.date_field'           : '$dateField'
      '.date_field_wrapper'   : '$dateWrapper'
      '.suggestion_reader'    : '$suggestionReader'

    events:
      'click .navigate_prev'        : '_triggerPrev'
      'click .navigate_today'       : '_triggerToday'
      'click .navigate_next'        : '_triggerNext'
      'click .navigation_title'     : '_onTitleClick'
      'keydown .navigation_title'   : '_onTitleKeyDown'

    messages:
      invalid_date: I18n.t('invalid_date', "Invalid date")

    initialize: ->
      @render()

      # use debounce to make the aria-live updates nicer
      @_updateSuggestionReader = _.debounce(@_updateSuggestionReader, 1000)

      @$buttons.buttonset()

      # make sure our jquery key handler is called first
      @$dateField.keydown(@_onDateFieldKey)

      @$dateField.date_field
        datepicker:
          onClose: @_onPickerClose
          onSelect: @_onPickerSelect
          showOn: "both"
      @$dateSuggestion = @$('.datetime_suggest')
      @hidePicker()
      @hide() if @options.hide

    show: (visible = true) =>
      @$el.toggle(visible)

    hide: => @show(false)

    setTitle: (new_text) =>
      # need to use .html instead of .text so &ndash; will render correctly
      @$title.html(new_text)

    showPicker: (visible = true) ->
      @$title.toggle(!visible)
      @$dateWrapper.toggle(visible)
      if visible
        @_resetPicker()
        @$dateField.focus()
      else
        @$dateField.realDatepicker("hide")
        @$title.focus()

    hidePicker: -> @showPicker(false)

    _resetPicker: ->
      @_enterKeyPressed = false
      @_enterKeyValue = ''
      @$suggestionReader.text('')
      @$dateField.removeAttr('aria-invalid')
      @$dateField.val('')

    _titleActivated: ->
      @showPicker() if @options.showPicker

    _dateFieldSelect: (selectedDateText) ->
      if @_enterKeyPressed
        selectedDateText = @_enterKeyValue
      return @_dateFieldEscape() unless selectedDateText
      selectedDate = Date.parse(selectedDateText)
      @_triggerDate(selectedDate)

      @hidePicker()

    _dateFieldEscape: ->
      @hidePicker()

    _triggerPrev: (event) ->
      @trigger('navigatePrev')

    _triggerToday: (event) ->
      @trigger('navigateToday')

    _triggerNext: (event) ->
      @trigger('navigateNext')

    _triggerDate: (selectedDate) ->
      @trigger('navigateDate', selectedDate)

    _onTitleClick: (event) ->
      event.preventDefault()
      @_titleActivated()

    _onTitleKeyDown: (event) ->
      if event.keyCode == 32 || event.keyCode == 13 # space or enter
        event.preventDefault()
        @_titleActivated()

    _onDateFieldKey: (event) =>
      if event.keyCode == 13 # enter
        # store some values for later so we can tell the difference between this and a mouse click
        @_enterKeyPressed = true
        @_enterKeyValue = @_getDateText()
      else
        @_updateSuggestionReader()

    _updateSuggestionReader: =>
      updateText = @_getDateText()
      textInvalid = !updateText
      updateText = @messages.invalid_date if textInvalid
      @$suggestionReader.text(updateText)
      @$dateField.attr("aria-invalid", if textInvalid then "true" else "false")

    _onPickerSelect: (selectedDateText) =>
      @_dateFieldSelect(selectedDateText)

    _onPickerClose: (selectedDateText) =>
      @_dateFieldEscape()

    _getDateText: ->
      newDate = @$dateSuggestion.text()
      newDate = '' if @$dateSuggestion.is('.invalid_datetime')
      newDate
