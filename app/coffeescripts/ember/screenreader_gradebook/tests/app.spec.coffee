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
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')

    teardown: ->
      Ember.run App, 'destroy'

  test 'fetches enrollments', ->
    equal @controller.get('enrollments').objectAt(0).user.name, 'Bob'
    equal @controller.get('enrollments').objectAt(1).user.name, 'Fred'

  test 'fetches assignment_groups', ->
    equal @controller.get('assignment_groups').objectAt(0).name, 'AG1'

  test 'fetches sections', ->
    equal @controller.get('sections').objectAt(0).name, 'Vampires and Demons'
    equal @controller.get('sections').objectAt(1).name, 'Slayers and Scoobies'

  test 'fetches custom_columns', ->
    equal @controller.get('custom_columns.length'), 1
    equal @controller.get('custom_columns.firstObject').title, fixtures.custom_columns[0].title
