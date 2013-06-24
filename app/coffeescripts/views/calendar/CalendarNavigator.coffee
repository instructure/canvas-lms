define [
  'i18n!calendar',
  'Backbone',
  'jst/calendar/calendarNavigator'
], (I18n, Backbone, template) ->

  class CalendarNavigator extends Backbone.View
    template: template

    els:
      '.navigation_title': '$title'
      '.navigation_buttons': '$buttons'

    events:
      'click .navigate_prev': '_triggerPrev'
      'click .navigate_today': '_triggerToday'
      'click .navigate_next': '_triggerNext'

    initialize: ->
      @render()
      @$buttons.buttonset()
      @hide() if @options.hide

    show: (visible = true) =>
      @$el.toggle(visible)

    hide: => @show(false)

    setTitle: (new_text) =>
      # need to use .html instead of .text so &ndash; will render correctly
      @$title.html(new_text)

    _triggerPrev: (event) ->
      @trigger('navigatePrev')

    _triggerToday: (event) ->
      @trigger('navigateToday')

    _triggerNext: (event) ->
      @trigger('navigateNext')
