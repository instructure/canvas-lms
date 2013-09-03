define [
  'Backbone'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/models/Course'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/IndexView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroup, Assignment, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, $) ->


  fixtures = $('#fixtures')

  assignmentIndex = () ->
    $('<div id="content"></div>').appendTo fixtures

    course = new Course {id: 1}

    group1 = new AssignmentGroup
      name: "Group 1"
      assignments: [{id: 1, name: 'Foo Name'}, {id: 2, name: 'Bar Title'}]
    group2 = new AssignmentGroup
      name: "Group 2"
      assignments: [{id: 1, name: 'Baz Title'}, {id: 2, name: 'Qux Name'}]
    assignmentGroups = new AssignmentGroupCollection [group1, group2],
      course: course

    assignmentGroupsView = new AssignmentGroupListView
      collection: assignmentGroups
      course: course

    app = new IndexView
      assignmentGroupsView: assignmentGroupsView
      collection: assignmentGroups
      createGroupView: false
      assignmentSettingsView: false
      showByView: false

    app.render()

  oldENV = null

  module 'assignmentIndex',
    setup: ->
      oldENV = window.ENV
      window.ENV =
        MODULES: {}
        PERMISSIONS:
          manage: true

    teardown: ->
      window.ENV = oldENV

  test 'should filter by search term', ->

    view = assignmentIndex()
    $('#search_term').val('foo')
    view.filterResults()
    equal view.$el.find('.assignment:visible').length, 1

    view = assignmentIndex()
    $('#search_term').val('BooBerry')
    view.filterResults()
    equal view.$el.find('.assignment:visible').length, 0

    view = assignmentIndex()
    $('#search_term').val('name')
    view.filterResults()
    equal view.$el.find('.assignment:visible').length, 2