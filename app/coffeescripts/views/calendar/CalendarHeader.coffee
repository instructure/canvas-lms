define [
  'i18n!calendar',
  'jquery'
  'Backbone',
  'jst/calendar/calendarHeader'
  'compiled/views/calendar/CalendarNavigator'
], (I18n, $, Backbone, template, CalendarNavigator) ->

  class CalendarHeader extends Backbone.View
    template: template

    els:
      '.calendar_view_buttons'   : '$calendarViewButtons'
      '.recommend_agenda'        : '$recommendAgenda'
      '.calendar_navigator'      : '$navigator'
      '.appointment_group_title' : '$appointmentGroupTitle'
      '.scheduler_done_button'   : '$schedulerDoneButton'
      '#create_new_event_link'   : '$createNewEventLink'
      '#refresh_calendar_link'   : '$refreshCalendarLink'

    events:
      'click #week'      : '_triggerWeek'
      'click #month'     : '_triggerMonth'
      'click #agenda'    : '_triggerAgenda'
      'click #use_agenda': '_selectAgenda'
      'click #scheduler' : '_triggerScheduler'
      'click .scheduler_done_button': '_triggerDone'
      'click #create_new_event_link': '_triggerCreateNewEvent'
      'click #refresh_calendar_link': '_triggerRefreshCalendar'
      'keydown .calendar_view_buttons': '_handleKeyDownEvent'
      'focus .recommend_agenda': '_showVisualAgendaRecommendation'
      'blur .recommend_agenda': '_hideVisualAgendaRecommendation'

    initialize: ->
      super
      @render()
      @navigator = new CalendarNavigator(el: @$navigator)
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
      @$calendarViewButtons.on('click', 'button', @toggleView)
      $.subscribe('Calendar/loadStatus', @animateLoading)

    toggleView: (e) ->
      e.preventDefault()
      $target = $(e.currentTarget)
      $target.attr('aria-selected', true)
             .addClass('active')
             .attr('tabindex', 0)
      $target.siblings()
             .attr('aria-selected', false)
             .removeClass('active')
             .attr('tabindex', -1)

    moveToCalendarViewButton: (direction) ->
      buttons = @$calendarViewButtons.children('button')
      active = @$calendarViewButtons.find('.active')
      activeIndex = buttons.index(active)
      lastIndex = buttons.length - 1

      if direction == 'prev'
        activeIndex = (activeIndex + lastIndex) % buttons.length
      else if direction == 'next'
        activeIndex = (activeIndex + 1) % buttons.length

      buttons.eq(activeIndex).focus().click()

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

    _showVisualAgendaRecommendation: ->
      @$recommendAgenda.removeClass('screenreader-only')

    _hideVisualAgendaRecommendation: ->
      @$recommendAgenda.addClass('screenreader-only')

    showAgendaRecommendation: ->
      @$recommendAgenda.show()

    hideAgendaRecommendation: ->
      @$recommendAgenda.hide()

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

    _selectAgenda: (event) ->
      @selectView('agenda')

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
      $.publish("CalendarHeader/createNewEvent")

    _triggerRefreshCalendar: (event) ->
      event.preventDefault()
      @trigger('refreshCalendar')

    _handleKeyDownEvent: (event) ->
      switch event.which
        when 37, 38 # left, up
          event.preventDefault()
          @moveToCalendarViewButton('prev')
        when 39, 40 # right, down
          event.preventDefault()
          @moveToCalendarViewButton('next')
