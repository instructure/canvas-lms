define [
  '../start_app'
  'underscore'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
  'vendor/jquery.ba-tinypubsub'
], (startApp, _, Ember, fixtures, $) ->

  App = null

  fixtures.create()

  module 'global settings',
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
      $(selection).text().search("Student") != -1
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

  test 'view concluded enrollments', ->
    enrollments = @controller.get('enrollments')
    ok enrollments.content.length > 1
    _.each enrollments.content, (enrollment) ->
      ok enrollment.workflow_state == undefined

    click("#concluded_enrollments").then =>
      enrollments = @controller.get('enrollments')
      equal enrollments.content.length, 1
      en = enrollments.objectAt(0)
      ok en.workflow_state == "completed"
      completed_at = new Date(en.completed_at)
      ok completed_at.getTime() < new Date().getTime()

      click("#concluded_enrollments").then =>
        enrollments = @controller.get('enrollments')
        ok enrollments.content.length > 1

