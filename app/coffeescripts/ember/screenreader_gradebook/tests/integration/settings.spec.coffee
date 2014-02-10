define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
  'vendor/jquery.ba-tinypubsub'
], (startApp, Ember, fixtures, $) ->

  App = null

  fixtures.create()

  module 'hide student names',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
    teardown: ->
      Ember.run App, 'destroy'

  test 'student names are hidden', ->
    selection = '#student_select option[value=1]'
    equal $(selection).text(), "Bob"
    click("#hide_names_checkbox").then =>
      equal $(selection).text(), "Student 1"
      click("#hide_names_checkbox").then =>
        equal $(selection).text(), "Bob"

  test 'secondary id says hidden', ->
    Ember.run =>
      @controller.set('selectedStudent', @controller.get('students').objectAt(0))

    reg = /^\s*$/ #all whitespace
    ok reg.test $("#secondary_id").text()
    click("#hide_names_checkbox").then =>
      reg = /hidden/
      ok reg.test $("#secondary_id").text()

