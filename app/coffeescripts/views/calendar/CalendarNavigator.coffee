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
      @_enterKeyData = null
      @_previousDateFieldValue = ''
      @$dateField.removeAttr('aria-invalid')
      @$dateField.val('')

    _titleActivated: ->
      @showPicker()

    _currentSelectedDate: ->
      @$dateField.trigger('change')
      @$dateField.data()

    _dateFieldSelect: ->
      data = @_enterKeyData || @_currentSelectedDate()
      @_triggerDate data.date unless data.invalid or data.blank
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
        # store current field data for later so we can tell the difference
        # between this and a mouse click
        @_enterKeyData = @_currentSelectedDate()
      else
        @_flashDateSuggestion()

    _flashDateSuggestion: =>
      return unless @_pickerShowing
      return if @_previousDateFieldValue == @$dateField.val()
      @_previousDateFieldValue = @$dateField.val()

      if @$dateField.data('invalid')
        @$dateField.attr("aria-invalid", "true")
        $.screenReaderFlashMessage(@messages.invalid_date)
      else
        @$dateField.attr("aria-invalid", "false")
        message = @$dateField.data('screenreader-suggest')
        message = @messages.screenreader_date_suggestion(message)
        $.screenReaderFlashMessage(message)

    _onPickerSelect: =>
      @_dateFieldSelect()

    _onPickerClose: =>
      @hidePicker()
