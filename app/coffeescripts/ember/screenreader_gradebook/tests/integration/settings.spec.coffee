define [
  '../start_app'
  'underscore'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
  'vendor/jquery.ba-tinypubsub'
], (startApp, _, Ember, fixtures, $) ->

  App = null

  QUnit.module 'global settings',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @controller.set 'hideStudentNames', false
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
      student = @controller.get('students.firstObject')
      Ember.setProperties student,
        isLoaded: true
        isLoading: false
      @controller.set('selectedStudent', student)

    equal Ember.$.trim(find(".secondary_id").text()), ''
    click("#hide_names_checkbox")
    andThen =>
      equal $.trim(find(".secondary_id:first").text()), 'hidden'

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
