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
], (_, Backbone, AssignmentGroup, Assignment, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, ToggleShowByView, $, fakeENV) ->


  COURSE_SUBMISSIONS_URL = "/courses/1/submissions"

  createView = (varyDates=false) ->
    ENV.PERMISSIONS = { manage: false, read_grades: true }
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
    url = "#{COURSE_SUBMISSIONS_URL}?"
    if ENV.observed_student_ids.length == 1
      url = "#{url}student_ids[]=#{ENV.observed_student_ids[0]}&"
    url = "#{url}per_page=50"

    server.respondWith "GET", url, [
      200,
      { "Content-Type": "application/json" },
      JSON.stringify(submissions),
    ]

    collection.getGrades()
    server.respond()

  QUnit.module 'ToggleShowByView',
    setup: ->
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      ENV.observed_student_ids = []

    teardown: ->
      fakeENV.teardown()
      @server.restore()
      $(".ui-dialog").remove()
      $("ul[id^=ui-id-]").remove()

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


  test 'observer view who are not observing a student', ->

    #Regular observer view
    ENV.current_user_has_been_observer_in_this_course = true
    view = createView(false)
    getGrades(view.assignmentGroups, @server)

    past = view.assignmentGroups.findWhere id: "past"
    assignments = past.get("assignments").models
    equal assignments.length, 5

    overdue = view.assignmentGroups.findWhere id: "overdue"
    equal overdue, undefined

    upcoming = view.assignmentGroups.findWhere id: "upcoming"
    assignments = upcoming.get("assignments").models
    equal assignments.length, 2


  test 'observer view who are observing a student', ->

    ENV.current_user_has_been_observer_in_this_course = true
    ENV.observed_student_ids = ["1"]
    view = createView(false)
    getGrades(view.assignmentGroups, @server)

    past = view.assignmentGroups.findWhere id: "past"
    assignments = past.get("assignments").models
    equal assignments.length, 3

    overdue = view.assignmentGroups.findWhere id: "overdue"
    assignments = overdue.get("assignments").models
    equal assignments.length, 2

    upcoming = view.assignmentGroups.findWhere id: "upcoming"
    assignments = upcoming.get("assignments").models
    equal assignments.length, 2

  #This will change in the future from a basic observer with no observing students to
  #way of selecting which student to observer for now though it defaults to a standard observer
  test 'observer view who are observing multiple students', ->

    ENV.observed_student_ids = ["1", "2"]
    ENV.current_user_has_been_observer_in_this_course = true
    view = createView(false)
    getGrades(view.assignmentGroups, @server)
    past = view.assignmentGroups.findWhere id: "past"
    assignments = past.get("assignments").models
    equal assignments.length, 5

    overdue = view.assignmentGroups.findWhere id: "overdue"
    equal overdue, undefined

    upcoming = view.assignmentGroups.findWhere id: "upcoming"
    assignments = upcoming.get("assignments").models
    equal assignments.length, 2
