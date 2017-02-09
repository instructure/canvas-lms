define [
  './start_app'
  'ember'
  './shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  QUnit.module 'screenreader_gradebook',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')

    teardown: ->
      Ember.run App, 'destroy'

  test 'fetches enrollments', ->
    equal @controller.get('enrollments').objectAt(0).user.name, 'Bob'
    equal @controller.get('enrollments').objectAt(1).user.name, 'Fred'

  test 'fetches sections', ->
    equal @controller.get('sections').objectAt(0).name, 'Vampires and Demons'
    equal @controller.get('sections').objectAt(1).name, 'Slayers and Scoobies'

  test 'fetches custom_columns', ->
    equal @controller.get('custom_columns.length'), 1
    equal @controller.get('custom_columns.firstObject').title, fixtures.custom_columns[0].title

  test 'fetches outcomes', ->
    equal @controller.get('outcomes').objectAt(0).title, 'Eating'
    equal @controller.get('outcomes').objectAt(1).title, 'Drinking'
