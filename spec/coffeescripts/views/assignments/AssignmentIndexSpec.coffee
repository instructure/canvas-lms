define [
  'Backbone'
  'compiled/models/AssignmentGroup'
  'compiled/models/Course'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/AssignmentGroupListView'
  'compiled/views/assignments/IndexView'
  'compiled/views/assignments/ToggleShowByView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroup, Course, AssignmentGroupCollection, AssignmentGroupListView, IndexView, ToggleShowByView, $, fakeENV) ->


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

    showByView = false
    if !ENV.PERMISSIONS.manage
      showByView = new ToggleShowByView
        course: course
        assignmentGroups: assignmentGroups

    app = new IndexView
      assignmentGroupsView: assignmentGroupsView
      collection: assignmentGroups
      createGroupView: false
      assignmentSettingsView: false
      showByView: showByView

    app.render()

  QUnit.module 'assignmentIndex',
    setup: ->
      fakeENV.setup(PERMISSIONS: {manage: true})
      @enable_spy = @spy(IndexView.prototype, 'enableSearch')

    teardown: ->
      fakeENV.teardown()
      assignmentGroups = null
      fixtures.empty()

  test 'should filter by search term', ->

    view = assignmentIndex()
    $('#search_term').val('foo')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 1

    $('#search_term').val('BooBerry')
    view.filterResults()
    equal view.$el.find('.assignment').not('.hidden').length, 0

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


  QUnit.module 'student index view',
    setup: ->
      fakeENV.setup(PERMISSIONS: {manage: false})

    teardown: ->
      fakeENV.teardown()
      assignmentGroups = null
      fixtures.empty()

  test 'should clear search on toggle', ->
    clear_spy = @spy(IndexView.prototype, 'clearSearch')
    view = assignmentIndex()
    view.$('#search_term').val('something')
    view.showByView.toggleShowBy({preventDefault: -> })
    equal view.$('#search_term').val(), ""
    ok clear_spy.called
