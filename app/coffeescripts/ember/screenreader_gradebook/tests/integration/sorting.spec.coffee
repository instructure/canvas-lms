define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  fixtures.create()

  setSelection = (selection) ->
    find('#arrange_assignments').val(selection)
  checkSelection = (selection) ->
    equal(selection, find('#arrange_assignments').val())

  module 'screenreader_gradebook assignment sorting: no saved setting',
    setup: ->
      App = startApp()
      visit('/')
    teardown: ->
      Ember.run App, 'destroy'

  test 'defaults to assignment group', ->
    checkSelection('assignment_group')


  module 'screenreader_gradebook assignment sorting: toggle settings',
    setup: ->
      App = startApp()
      visit('/')
    teardown: ->
      setSelection('assignment_group')
      Ember.run App, 'destroy'

  test 'loads alphabetical sorting', ->
    setSelection('alpha')
    visit('/')
    checkSelection('alpha')
    setSelection('due_date')
    visit('/')
    checkSelection('due_date')


