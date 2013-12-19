define [
  'underscore'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  '../../controllers/screenreader_gradebook_controller'
], (_, startApp, Ember, fixtures, SRGController) ->

  App = null

  fixtures.create()
  clone = (obj) ->
    Em.copy obj, true

  setup = ->
    App = startApp()
    Ember.run.join =>
      @srgb = SRGController.create()
      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: clone fixtures.assignment_groups)
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
      })


  module 'screenreader_gradebook_controller',
    setup: ->
      setup.call this
    teardown: ->
      Ember.run App, 'destroy'

  test 'calculates students properly', ->
    andThen =>
      equal @srgb.get('students.length'), 2
      equal @srgb.get('students.firstObject').name, fixtures.students[0].user.name

  test 'calculates assignments properly', ->
    andThen =>
      equal @srgb.get('assignments.length'), 2
      equal @srgb.get('assignments.firstObject').name, fixtures.assignment_groups[0].assignments[0].name

  test 'studentsHash returns the expected hash', ->
    andThen =>
      _.each @srgb.studentsHash(), (obj) =>
        strictEqual @srgb.get('students').findBy('id', obj.id), obj

  test 'assignmentGroupsHash retuns the expected hash', ->
    andThen =>
      _.each @srgb.assignmentGroupsHash(), (obj) =>
        strictEqual @srgb.get('assignment_groups').findBy('id', obj.id), obj

  test 'student objects have isLoaded flag set to true once submissions are loaded', ->
    andThen =>
      @srgb.get('students').forEach (s) ->
        equal Ember.get(s, 'isLoaded'), true

  test 'updateSubmission attaches the submission to the student', ->
    student = clone fixtures.students[0].user
    submission = clone fixtures.submissions[student.id].submissions[0]

    @srgb.updateSubmission submission, student
    strictEqual student["assignment_#{submission.assignment_id}"], submission

  test 'selectedSubmissionGrade is - if there is no selectedSubmission', ->
    andThen =>
      equal @srgb.get('selectedSubmissionGrade'), '-'


  module 'screenreader_gradebook_controller: with selected student',
    setup: ->
      setup.call this
      Ember.run =>
        student = @srgb.get('students.firstObject')
        @srgb.set('selectedStudent', student)
    teardown: ->
      Ember.run App, 'destroy'

  test 'selectedSubmission should be null when just selectedStudent is set', ->
    strictEqual @srgb.get('selectedSubmission'), null

  module 'screenreader_gradebook_controller: with selected student and selected assignment',
    setup: ->
      setup.call this
      Ember.run =>
        @student = @srgb.get('students.firstObject')
        @assignment = @srgb.get('assignments.firstObject')
        @srgb.set('selectedStudent', @student)
        @srgb.set('selectedAssignment', @assignment)

    teardown: ->
      Ember.run App, 'destroy'

  test 'selectedSubmissionGrade is computed properly', ->
    andThen =>
      equal @srgb.get('selectedSubmissionGrade'), fixtures.submissions[0].submissions[0].grade

  test 'assignmentDetails is computed properly', ->
    andThen =>
      ad = @srgb.get('assignmentDetails')
      selectedAssignment = @srgb.get('selectedAssignment')
      strictEqual ad.assignment, selectedAssignment
      strictEqual ad.cnt, 0

  test 'selectedSubmission is computed properly', ->
    andThen =>
      selectedSubmission = @srgb.get('selectedSubmission')
      sub = _.find(fixtures.submissions, (s) => s.user_id == @student.id)
      submission = _.find(sub.submissions, (s) => s.assignment_id == @assignment.id)
      _.each submission, (val, key) =>
        equal selectedSubmission[key], val, "#{key} is the expected value on selectedSubmission"

