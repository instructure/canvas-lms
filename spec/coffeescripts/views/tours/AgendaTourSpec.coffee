define [
  'jquery'
  'Backbone'
  'compiled/views/tours/AgendaTour'
  'helpers/assertions'
  'helpers/util'
  'helpers/jquery.simulate'
], ($, Backbone, AgendaTour, assert, util) ->

  view = null
  $fixtures = null
  fakeUsher = null
  fakeLocation = {
    pathname: '/'
  }

  class FakeUsher
    constructor: ->
      @_started = false
      @_showing = null
      @_stepbacks = {}

    start: (target)->
      @_startTarget = target
      @_started = true

    show: (target)->
      @_showing = target

    on: (step, callback)->
      @_stepbacks[step] = callback

    takeStep: (step)->
      @_stepbacks[step].call()

  addActiveAgendaButton = ->
    agendaButton = $('<button id="agenda" class="active"></button>')
    agendaButton.appendTo $fixtures

  addAgendaButton = ->
    agendaButton = $('<button id="agenda"></button>')
    agendaButton.appendTo $fixtures
    return agendaButton

  addItemGroupContainer = ->
    itemGroupContainer = $('<div class="item-group-container"></div>')
    itemGroupContainer.appendTo $fixtures

  addCalendarMenu = ->
    calendarMenu = $('<div id="calendar_menu_item"><a href="#">Calendar Link</a></div>')
    calendarMenu.appendTo $fixtures

  addAgendaAssignment = ->
    assignment = $('<div class="agenda-event">')
    assignment.appendTo $fixtures

  module 'AgendaTour',
    setup: ->
      view = new AgendaTour()
      $fixtures = $('#fixtures')
      view.render().$el.appendTo($fixtures)
      fakeUsher = new FakeUsher()
      view.tour = fakeUsher
      delete localStorage.AgendaTourContinue

    teardown: ->
      view.remove()
      $fixtures.empty()

  test 'location dependency injection', ->
    equal window.location, view.locationProvider()

  test 'checking if onCalendar', ->
    equal false, view.onCalendar()
    view._locProvider = fakeLocation
    fakeLocation.pathname = '/calendar2'
    equal true, view.onCalendar()

  test "agendaHasAssignments is false if none in the dom", ->
    equal false, view.agendaHasAssignments()

  test "agendaHasAssignments is true if one in the dom", ->
    addAgendaAssignment()
    equal true, view.agendaHasAssignments()

  test 'attachTour short circuits if theres no header', ->
    equal false, view.attachTour()

  test 'attachTourForNonCalendarPage starts the tour', ->
    equal false, fakeUsher._started
    view.attachTourForNonCalendarPage()
    equal true, fakeUsher._started

  test 'attachTourForNonCalendarPage tracks when weve been to the calendar', ->
    addCalendarMenu()
    equal localStorage.AgendaTourContinue, undefined
    view.attachTourForNonCalendarPage()
    fakeUsher.takeStep('agenda-step-2')
    calendarLink = $('#calendar_menu_item a')
    calendarLink.triggerHandler('click')
    equal localStorage.AgendaTourContinue, '1'

  test "agendaButton goes to step 4 when there are assignments", ->
    agendaButton = addAgendaButton()
    addItemGroupContainer()
    view.attachAgendaButton()
    agendaButton.triggerHandler('click')
    equal fakeUsher._showing, 'agenda-step-4-no-assignments'

  test "agendaButton goes to step 4-no-assignments when there are no assignments", ->
    addAgendaAssignment()
    agendaButton = addAgendaButton()
    addItemGroupContainer()
    view.attachAgendaButton()
    agendaButton.triggerHandler('click')
    equal fakeUsher._showing, 'agenda-step-4'

  test 'attaching the tour on the calendar page with inactive agenda', ->
    addAgendaButton()
    addItemGroupContainer()
    view.attachTourOnCalendarPage()
    equal view.agendaStep2Button().attr('data-usher-show'), 'agenda-step-2-on-calendar'
    equal true, fakeUsher._started

  test 'attaching tour on calendar with active agenda sets up step 4 path', ->
    addActiveAgendaButton()
    addItemGroupContainer()
    view.attachTourOnCalendarPage()
    equal view.agendaStep3Button().attr('data-usher-show'), 'agenda-step-4-no-assignments'
    equal true, fakeUsher._started

  test 'attaching tour on calendar from another page with inactive agenda', ->
    localStorage.AgendaTourContinue = '1'
    addAgendaButton()
    addItemGroupContainer()
    view.attachTourOnCalendarPage()
    equal 'agenda-step-3', fakeUsher._startTarget
    equal true, fakeUsher._started

  test 'attaching calendar tour with active agenda from other page and an assignment', ->
    localStorage.AgendaTourContinue = '1'
    addAgendaAssignment()
    addActiveAgendaButton()
    addItemGroupContainer()
    view.attachTourOnCalendarPage()
    equal view.agendaStep3Button().attr('data-usher-show'), 'agenda-step-4'
    equal 'agenda-step-3-on-agenda-already', fakeUsher._startTarget
    equal true, fakeUsher._started

