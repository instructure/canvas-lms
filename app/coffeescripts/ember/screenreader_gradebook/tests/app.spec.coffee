define [
  './start_app'
  'ember'
  './shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  fixtures.create()

  module 'screenreader_gradebook',
    setup: ->
      App = startApp()
    teardown: ->
      Ember.run App, 'destroy'

  test 'fetches enrollments', ->
    visit('/').then ->
      controller = App.__container__.lookup('controller:screenreader_gradebook')
      equal controller.get('enrollments').objectAt(0).user.name, 'Bob'
      equal controller.get('enrollments').objectAt(1).user.name, 'Fred'

  test 'fetches assignment_groups', ->
    visit('/').then ->
      controller = App.__container__.lookup('controller:screenreader_gradebook')
      equal controller.get('assignment_groups').objectAt(0).name, 'AG1'

  #test 'fetches submissions', ->
    #controller = App.__container__.lookup('controller:screenreader_gradebook')
    #equal controller.get('submissions').objectAt(0).submissions[0].grade, '3'
    #equal controller.get('submissions').objectAt(1).submissions[0].grade, '9'

  test 'fetches sections', ->
    visit('/').then ->
      controller = App.__container__.lookup('controller:screenreader_gradebook')
      equal controller.get('sections').objectAt(0).name, 'Vampires and Demons'
      equal controller.get('sections').objectAt(1).name, 'Slayers and Scoobies'
