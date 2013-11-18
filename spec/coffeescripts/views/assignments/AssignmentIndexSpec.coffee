define [
  'Backbone'
  'compiled/models/AssignmentGroup'
  'compiled/models/Course'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/IndexView'
  'jquery'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (Backbone, AssignmentGroup, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, $) ->


  fixtures = $('#fixtures')

  assignmentGroups = null

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

  module 'assignmentIndex',
    setup: ->
      ENV.PERMISSIONS = {manage: true}
      @enable_spy = sinon.spy(IndexView.prototype, 'enableSearch')

    teardown: ->
      ENV.PERMISSIONS = {}
      assignmentGroups = null
      $('#fixtures').empty()
      @enable_spy.restore()

  test 'should filter by search term', ->

    view = assignmentIndex()
    $('#search_term').val('foo')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 1

    view = assignmentIndex()
    $('#search_term').val('BooBerry')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 0

    view = assignmentIndex()
    $('#search_term').val('name')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 2


  test 'should have search disabled on render', ->
    view = assignmentIndex()
    ok view.$('#search_term').is(':disabled')


  test 'should enable search on assignmentGroup reset', ->
    view = assignmentIndex()
    assignmentGroups.reset()
    ok !view.$('#search_term').is(':disabled')

  test 'enable search handler should only fire on the first reset', ->
    view = assignmentIndex()
    assignmentGroups.reset()
    ok @enable_spy.calledOnce
    #reset a second time and make sure it was still only called once
    assignmentGroups.reset()
    ok @enable_spy.calledOnce

  test 'should show modules column', ->
    view = assignmentIndex()

    [a1, a2] = assignmentGroups.assignments()
    a1.set 'modules', ['One', 'Two']
    a2.set 'modules', ['Three']

    ok view.$("#assignment_1 .modules .tooltip_link").text().match(/Multiple Modules/)
    ok view.$("#assignment_1 .modules").text().match(/One\s+Two/)
    ok view.$("#assignment_2 .modules").text().match(/Three Module/)
