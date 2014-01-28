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
  'helpers/fakeENV'
], (_, Backbone, AssignmentGroup, Assignment, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, ToggleShowByView, $) ->


  COURSE_SUBMISSIONS_URL = "/courses/1/submissions"

  createView = (varyDates=false) ->
    ENV.PERMISSIONS = { manage: false }
    course = new Course {id: 1}
    #the dates are in opposite order of what they will be sorted into
    assignments = [
      {id: 1, name: 'Past Assignments', due_at: new Date(2013, 8, 20), position: 1, submission_types: ['online']},
      {id: 2, name: 'Past Assignments', due_at: new Date(2013, 8, 21), position: 2, submission_types: ['on_paper']},
      {id: 3, name: 'Upcoming Assignments', due_at: new Date(3013, 8, 21), position: 1},
      {id: 4, name: 'Overdue Assignments', due_at: new Date(2013, 8, 21), position: 1, submission_types: ['online']},
      {id: 5, name: 'Past Assignments', due_at: new Date(2013, 8, 22), position: 3, submission_types: ['online']},
      {id: 6, name: 'Overdue Assignments', due_at: new Date(2013, 8, 20), position: 2, submission_types: ['online']},
      {id: 7, name: 'Undated Assignments'},
      {id: 8, name: 'Upcoming Assignments', due_at: new Date(3013, 8, 20), position: 2}
    ]
    group      = new AssignmentGroup assignments: assignments
    collection = new AssignmentGroupCollection [group],
      courseSubmissionsURL: COURSE_SUBMISSIONS_URL,
      course: course
    showByView = new ToggleShowByView
      course: course
      assignmentGroups: collection

  getGrades = (collection, server) ->
    submissions = [
      {id: 1, assignment_id: 1, grade: 305},
      {id: 2, assignment_id: 4},
      {id: 3, assignment_id: 5, submission_type: 'online'}
    ]
    server.respondWith "GET", "#{COURSE_SUBMISSIONS_URL}?per_page=50", [
      200,
      { "Content-Type": "application/json" },
      JSON.stringify(submissions),
    ]

    collection.getGrades()
    server.respond()

  module 'ToggleShowByView',
    setup: ->
      @server = sinon.fakeServer.create()

    teardown: ->
      ENV.PERMISSIONS = {}
      @server.restore()

  test 'should sort assignments into groups correctly', ->

    view = createView(false)
    getGrades(view.assignmentGroups, @server)

    equal view.assignmentGroups.length, 4
    view.assignmentGroups.each (group) ->
      assignments = group.get('assignments').models
      _.each assignments, (as) ->
        equal group.name(), as.name()

  test 'should sort assignments by date correctly', ->

    view = createView(true)
    getGrades(view.assignmentGroups, @server)

    #check past assignment sorting (descending)
    past = view.assignmentGroups.findWhere id: "past"
    assignments = past.get("assignments").models
    equal assignments[0].get("due_at"), new Date(2013, 8, 22).toString()
    equal assignments[1].get("due_at"), new Date(2013, 8, 21).toString()
    equal assignments[2].get("due_at"), new Date(2013, 8, 20).toString()

    #check overdue assignment sorting (ascending)
    overdue = view.assignmentGroups.findWhere id: "overdue"
    assignments = overdue.get("assignments").models
    equal assignments[0].get("due_at"), new Date(2013, 8, 20).toString()
    equal assignments[1].get("due_at"), new Date(2013, 8, 21).toString()

    #check upcoming assignment sorting (ascending)
    upcoming = view.assignmentGroups.findWhere id: "upcoming"
    assignments = upcoming.get("assignments").models
    equal assignments[0].get("due_at"), new Date(3013, 8, 20).toString()
    equal assignments[1].get("due_at"), new Date(3013, 8, 21).toString()
