define [
  'underscore'
  'Backbone'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/models/Course'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/IndexView'
  'compiled/views/assignments/ToggleShowByView'
  'jquery'
], (_, Backbone, AssignmentGroup, Assignment, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, ToggleShowByView, $) ->


  COURSE_SUBMISSIONS_URL = "/courses/1/submissions"

  module 'ToggleShowByView',
    setup: ->
      window.ENV =
        PERMISSIONS:
          manage: false
      @course   = new Course {id: 1}
      @server   = sinon.fakeServer.create()
      @pastDate = new Date("2013-08-20 11:13:00")
      today     = new Date()
      @futureDate  = new Date()
      @futureDate.setDate(today.getDate() + 3)
      @assignments = [
        {id: 1, name: 'Past Assignments', due_at: @pastDate, submission_types: ['online']},
        {id: 2, name: 'Past Assignments', due_at: @pastDate, submission_types: ['on_paper']},
        {id: 3, name: 'Upcoming Assignments', due_at: @futureDate},
        {id: 4, name: 'Past Assignments', due_at: @pastDate, submission_types: ['online']},
        {id: 5, name: 'Overdue Assignments', due_at: @pastDate, submission_types: ['online']},
        {id: 6, name: 'Undated Assignments'}
      ]
      @group      = new AssignmentGroup assignments: @assignments
      @collection = new AssignmentGroupCollection [@group],
        courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
        course: @course
      @showByView = new ToggleShowByView
        course: @course
        assignmentGroups: @collection

    teardown: ->
      @server.restore()

  test 'should sort assignments correctly', ->

    submissions = [
      {id: 1, assignment_id: 1, grade: 305},
      {id: 2, assignment_id: 4}
    ]
    @server.respondWith "GET", "#{COURSE_SUBMISSIONS_URL}?per_page=50", [
      200,
      { "Content-Type": "application/json" },
      JSON.stringify(submissions),
    ]

    @collection.getGrades()
    @server.respond()

    equal @collection.length, 4
    @collection.each (group) ->
      assignments = group.get('assignments').models
      _.each assignments, (as) ->
        equal group.name(), as.name()

