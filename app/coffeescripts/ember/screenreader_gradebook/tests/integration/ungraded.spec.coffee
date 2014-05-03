define [
  'compiled/userSettings'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (userSettings, startApp, Ember, fixtures) ->

  App = null

  fixtures.create()

  setup = (initialSetting) ->
    userSettings.contextSet 'include_ungraded_assignments', initialSetting
    App = startApp()
    visit('/')

  runTest = ->
    controller = App.__container__.lookup('controller:screenreader_gradebook')
    initial = controller.get('includeUngradedAssignments')
    click('#ungraded')
    andThen ->
      equal !controller.get('includeUngradedAssignments'), initial


  module 'include ungraded assignments setting:false',
    setup: ->
      setup.call this, false

    teardown: ->
      Ember.run App, 'destroy'

  test 'clicking the ungraded checkbox updates includeUngradedAssignments to true', ->
    runTest()


  module 'include ungraded assignments setting:true',
    setup: ->
      setup.call this, true

    teardown: ->
      Ember.run App, 'destroy'

  test 'clicking the ungraded checkbox updates includeUngradedAssignments to false', ->
    runTest()
