define [
  'i18n!calendar',
  'Backbone',
  'jst/calendar/calendarHeader'
  'compiled/views/calendar/CalendarNavigator'
], (I18n, Backbone, template, CalendarNavigator) ->

  class CalendarHeader extends Backbone.View
    template: template

    els:
      '.calendar_view_buttons'   : '$calendarViewButtons'
      '.calendar_navigator'      : '$navigator'
      '.appointment_group_title' : '$appointmentGroupTitle'
      '.scheduler_done_button'   : '$schedulerDoneButton'
      '#create_new_event_link'   : '$createNewEventLink'
      '#refresh_calendar_link'   : '$refreshCalendarLink'

    events:
      'click #week'      : '_triggerWeek'
      'click #month'     : '_triggerMonth'
      'click #agenda'    : '_triggerAgenda'
      'click #scheduler' : '_triggerScheduler'
      'click .scheduler_done_button': '_triggerDone'
      'click #create_new_event_link': '_triggerCreateNewEvent'
      'click #refresh_calendar_link': '_triggerRefreshCalendar'

    initialize: ->
      @render()
      @navigator = new CalendarNavigator(
        el: @$navigator
        showAgenda: @options.showAgenda
      )
      @$calendarViewButtons.buttonset()
      @showNavigator()
      # The badge is part of the buttonset, so we can't find it beforehand with els
      @$badge = @$el.find('.counter-badge')
      @setSchedulerBadgeCount(0)
      @connectEvents()

    connectEvents: ->
      @navigator.on('navigatePrev', => @trigger('navigatePrev'))
      @navigator.on('navigateToday', => @trigger('navigateToday'))
      @navigator.on('navigateNext', => @trigger('navigateNext'))
      @navigator.on('navigateDate', (selectedDate) => @trigger('navigateDate', selectedDate))
      $.subscribe('Calendar/loadStatus', @animateLoading)
      @$schedulerDoneButton

    showNavigator: ->
      @$navigator.show()
      @$createNewEventLink.show()
      @$appointmentGroupTitle.hide()
      @$schedulerDoneButton.hide()

    showSchedulerTitle: ->
      @$navigator.hide()
      @$createNewEventLink.hide()
      @$appointmentGroupTitle.show()
      @$schedulerDoneButton.hide()

    showDoneButton: ->
      @$navigator.hide()
      @$createNewEventLink.hide()
      @$appointmentGroupTitle.hide()
      @$schedulerDoneButton.show()

    setHeaderText: (newText) =>
      @navigator.setTitle(newText)

    selectView: (viewName) ->
      $("##{viewName}").click()

    animateLoading: (shouldAnimate) =>
      @$refreshCalendarLink.toggleClass('loading', shouldAnimate)

    setSchedulerBadgeCount: (badgeCount) ->
      @$badge.toggle(badgeCount > 0).text(badgeCount)

    showPrevNext: ->
      @navigator.showPrevNext()

    hidePrevNext: ->
      @navigator.hidePrevNext()

    _triggerDone: (event) ->
      @trigger('done')

    _triggerWeek: (event) ->
      @trigger('week')

    _triggerMonth: (event) ->
      @trigger('month')

    _triggerAgenda: (event) ->
      @trigger('agenda')

    _triggerScheduler: (event) ->
      @trigger('scheduler')

    _triggerCreateNewEvent: (event) ->
      event.preventDefault()
      @trigger('createNewEvent')

    _triggerRefreshCalendar: (event) ->
      event.preventDefault()
      @trigger('refreshCalendar')
