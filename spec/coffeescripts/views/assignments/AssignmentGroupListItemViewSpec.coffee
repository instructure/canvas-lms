define [
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'compiled/views/assignments/AssignmentListItemView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, AssignmentGroupListItemView, AssignmentListItemView, $) ->

  fixtures = $('#fixtures')

  assignment1 = ->
    date1 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Summer Session"
    date2 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Winter Session"

    buildAssignment(
      "id":1
      "name":"History Quiz"
      "description":"test"
      "due_at":"2013-08-21T23:59:00-06:00"
      "points_possible":2
      "position":1
      "all_dates":[date1, date2]
    )

  assignment2 = ->
    buildAssignment(
      "id":3
      "name":"Math Quiz"
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
      "position":2
    )

  assignment3 = ->
    buildAssignment(
      "id":2
      "name":"Science Quiz"
      "points_possible":5
      "position":3
    )

  buildAssignment = (options) ->
    options ?= {}

    base =
      "assignment_group_id":1
      "due_at":null
      "grading_type":"points"
      "points_possible":5
      "position":2
      "course_id":1
      "name":"Science Quiz"
      "submission_types":[]
      "html_url":"http://localhost:3000/courses/1/assignments/#{options.id}"
      "needs_grading_count":0
      "all_dates":[]
      "published":true
    $.extend base, options

  createAssignmentGroup = ->
    assignments = [assignment1(), assignment2(), assignment3()]
    group = "id":1, "name":"Assignments", "position":1, "rules":{}, "group_weight":1, "assignments": assignments
    groups = new AssignmentGroupCollection([group])
    groups.models[0]

  createView = (model, options) ->
    options = $.extend {canManage: true}, options

    sinon.stub( AssignmentGroupListItemView.prototype, "canManage", -> options.canManage )
    sinon.stub( AssignmentListItemView.prototype, "canManage", -> options.canManage )
    sinon.stub( AssignmentListItemView.prototype, "modules", -> )

    view = new AssignmentGroupListItemView(model: model)
    view.$el.appendTo $('#fixtures')
    view.render()

    AssignmentGroupListItemView.prototype.canManage.restore()
    AssignmentListItemView.prototype.canManage.restore()
    AssignmentListItemView.prototype.modules.restore()

    view

  module 'AssignmentGroupListItemView',
    setup: ->
      @model = createAssignmentGroup()

  test "initializes collection", ->
    view = createView(@model)
    ok view.collection

  test "does not parse response with multiple due dates", ->
    models = @model.get("assignments").models
    a1 = models[0]
    a2 = models[1]

    sinon.spy(a1, 'doNotParse')
    sinon.spy(a2, 'doNotParse')

    createView(@model)

    # first assignment has multiple due dates
    ok a1.multipleDueDates()
    ok a1.doNotParse.called
    a1.doNotParse.restore()

    # second assignment has single due dates
    ok !a2.multipleDueDates()
    ok !a2.doNotParse.called
    a2.doNotParse.restore()

  test "initializes child views if can manage", ->
    view = createView(@model)
    ok view.editGroupView
    ok view.createAssignmentView
    ok view.deleteGroupView

  test "initializes no child views if can't manage", ->
    view = createView(@model, canManage: false)
    ok !view.editGroupView
    ok !view.createAssignmentView
    ok !view.deleteGroupView

  test "initializes cache", ->
    view = createView(@model)
    ok view.cache

  test "toJSON includes group weight", ->
    view = createView(@model)
    json = view.toJSON()
    equal json.groupWeight, 1

  test "isExpanded returnes expanded state", ->
    view = createView(@model)
    view.expand()
    ok view.isExpanded()

  test "toggle toggles expansion", ->
    view = createView(@model)
    view.expand()

    view.toggle(false)
    ok !view.isExpanded()

    view.toggle(true)
    ok view.isExpanded()

  test "cacheKey builds unique key", ->
    view = createView(@model)
    equal view.cacheKey(), "ag_1_expanded"
