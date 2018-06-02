#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'Backbone',
  'jst/calendar/calendarNavigator',
  'jquery.instructure_date_and_time' # $.date_field
], ($, _, Backbone, template) ->

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
      @$titleText.attr('aria-label', new_text + " click to change")
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
      @_triggerDate data['unfudged-date'] unless data.invalid or data.blank
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

    _onPickerSelect: =>
      @_dateFieldSelect()

    _onPickerClose: =>
      @hidePicker()
