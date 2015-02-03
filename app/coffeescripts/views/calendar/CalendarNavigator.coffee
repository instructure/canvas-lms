define [
  'i18n!calendar',
  'jquery'
  'underscore'
  'Backbone',
  'jst/calendar/calendarNavigator'
], (I18n, $, _, Backbone, template) ->

  class CalendarNavigator extends Backbone.View
    template: template

    els:
      '.navigation_title'      : '$title'
      '.navigation_title_text' : '$titleText'
      '.navigation_buttons'    : '$buttons'
      '.date_field'            : '$dateField'
      '.date_field_wrapper'    : '$dateWrapper'

    events:
      'click .navigate_prev'        : '_triggerPrev'
      'click .navigate_today'       : '_triggerToday'
      'click .navigate_next'        : '_triggerNext'
      'click .navigation_title'     : '_onTitleClick'
      'keyclick .navigation_title'  : '_onTitleClick'

    messages:
      invalid_date: I18n.t('input_is_invalid_date', "Input is not a valid date.")
      screenreader_date_suggestion: (dateText) ->
        I18n.t 'screenreader_date_suggestion', '%{date}. Press enter to accept.',
          date: dateText

    # options:
    #   hide       - set to true if this navigator should start hidden
    initialize: ->
      super
      @render()

      # use debounce to make the aria-live updates nicer
      @_flashDateSuggestion = _.debounce(@_flashDateSuggestion, 1500)

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
      @$titleText.text(new_text)

    showPicker: (visible = true) ->
      @_pickerShowing = visible
      @$title.toggle(!visible)
      @$dateWrapper.toggle(visible)
      if visible
        @_resetPicker()
        @$dateField.focus()
      else
        @$dateField.realDatepicker("hide")
        @$title.focus()

    hidePicker: -> @showPicker(false)

    showPrevNext: ->
      @$buttons.show()

    hidePrevNext: ->
      @$buttons.hide()

    _resetPicker: ->
      @_enterKeyPressed = false
      @_enterKeyValue = ''
      @_previousDateFieldValue = ''
      @$dateField.removeAttr('aria-invalid')
      @$dateField.val('')

    _titleActivated: ->
      @showPicker()

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

    _onDateFieldKey: (event) =>
      if event.keyCode == 13 # enter
        # store some values for later so we can tell the difference between this and a mouse click
        @_enterKeyPressed = true
        @_enterKeyValue = @_getDateText()
      else
        @_flashDateSuggestion()

    _flashDateSuggestion: =>
      return unless @_pickerShowing
      return if @_previousDateFieldValue == @$dateField.val()
      @_previousDateFieldValue = @$dateField.val()

      dateText = @_getDateText()
      textInvalid = !dateText
      flashText =
        if textInvalid
          @messages.invalid_date
        else
          @messages.screenreader_date_suggestion(dateText)
      $.screenReaderFlashMessage(flashText)
      @$dateField.attr("aria-invalid", if textInvalid then "true" else "false")

    _onPickerSelect: (selectedDateText) =>
      @_dateFieldSelect(selectedDateText)

    _onPickerClose: (selectedDateText) =>
      @_dateFieldEscape()

    _getDateText: ->
      newDate = @$dateSuggestion.text()
      newDate = '' if @$dateSuggestion.is('.invalid_datetime')
      newDate
