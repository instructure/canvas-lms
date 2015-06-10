define [
  'jquery'
  'compiled/views/TourView'
  'jst/tours/AgendaTour'
  'vendor/usher/usher'
], ($, TourView, template, Usher) ->

  class AgendaTour extends TourView

    template: template

    calendarMenu: ->
      $("#calendar_menu_item")

    calendarLink: ->
      @calendarMenu().find('a')

    agendaStep2Button: ->
      @$el.find('.agenda-step-2-button')

    agendaStep3Button: ->
      @$el.find('.agenda-step-3-on-agenda-already-button')

    locationProvider: ->
      return @_locProvider if @_locProvider?
      return window.location

    onCalendar: ->
      # TODO Ask if we are always going to have this url be /calendar2
      @locationProvider().pathname is '/calendar2'

    agendaHasAssignments: =>
      $(".agenda-event").length > 0

    attachTour: ->
      pageHasHeader = @calendarMenu().length > 0
      return false unless pageHasHeader
      if @onCalendar()
        @attachTourOnCalendarPage()
      else
        @attachTourForNonCalendarPage()

    onItemGroupRender: (callback)=>
      @onElementRendered "div.item-group-container", =>
        callback.call()

    setupStep4Path: ->
      targetStep = 'agenda-step-4-no-assignments'
      if @agendaHasAssignments()
        targetStep = 'agenda-step-4'
      @agendaStep3Button().attr('data-usher-show', targetStep)

    agendaIsActive: ->
      agendaButton = $('#agenda')
      return agendaButton.hasClass 'active'

    attachTourOnCalendarPage: ->
      continuingFromOtherPage = localStorage.AgendaTourContinue
      @onElementRendered '#agenda', =>
        if not continuingFromOtherPage
          @agendaStep2Button().attr('data-usher-show', 'agenda-step-2-on-calendar')
          if @agendaIsActive()
            @$el.find('.agenda-step-3.btn').attr('data-usher-show', 'agenda-step-3-on-agenda-already')
            @onItemGroupRender(=> @setupStep4Path())
            @start()
          else
            @attachAgendaButton()
            @start()
        else
          delete localStorage.AgendaTourContinue
          if @agendaIsActive()
            @onItemGroupRender =>
              @setupStep4Path()
              @tour.start('agenda-step-3-on-agenda-already')
          else
            @attachAgendaButton()
            @tour.start('agenda-step-3')

    onAgendaButtonClick: =>
      if @agendaHasAssignments()
        @tour.show('agenda-step-4')
      else
        @tour.show('agenda-step-4-no-assignments')

    attachAgendaButton: ->
      $('#agenda').on 'click', =>
        @onItemGroupRender =>
          @onAgendaButtonClick()

    attachTourForNonCalendarPage: ->
      @tour.on 'agenda-step-2', =>
        @calendarLink().on 'click', ->
          localStorage.AgendaTourContinue = '1'
      @tour.start()
