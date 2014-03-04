define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
], (startApp, Ember, fixtures) ->

  App = null

  fixtures.create()

  module 'grading_cell_component integration test for isPoints',
    setup: ->
      App = startApp()
      visit('/')
      @controller = App.__container__.lookup('controller:screenreader_gradebook')
      @assignment = @controller.get('assignments').findBy('id', '6')
      @student = @controller.get('students').findBy('id', '1')
      Ember.run =>
        @controller.set('selectedAssignment', @assignment)
        @controller.set('selectedStudent', @student)
        console.log @controller.get('submissions.length')

    teardown: ->
      Ember.run App, 'destroy'

  test 'fast-select instance is used for grade input', ->
    ok find('#student_and_assignment_grade').is('select')
    equal find('#student_and_assignment_grade').val(), 'incomplete'


