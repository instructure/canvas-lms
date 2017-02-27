define [
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/AssignmentGroupListView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
  'compiled/behaviors/elementToggler'
], (Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, AssignmentGroupListItemView, AssignmentListItemView, AssignmentGroupListView, $, fakeENV, simulate, elementToggler) ->
  assignment1 = ->
    date1 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Summer Session"
    date2 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Winter Session"

    buildAssignment
      "id":1
      "name":"History Quiz"
      "description":"test"
      "due_at":"2013-08-21T23:59:00-06:00"
      "points_possible":2
      "position":1
      "all_dates":[date1, date2]

  assignment2 = ->
    buildAssignment
      "id":3
      "name":"Math Quiz"
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
      "position":2

  assignment3 = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "points_possible":5
      "position":3

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

  group1 = ->
    buildGroup()

  group2 = ->
    buildGroup
      "id":2
      "name":"Other Assignments"
      "position":2
      "rules": {"drop_lowest":1, "drop_highest":2, "never_drop":[3,4]} # intentionally include an invalid assignment id

  group3 = ->
      buildGroup
        "id":3
        "name":"Even more Assignments"
        "position":3
        "rules": {"drop_lowest":1, "drop_highest":1}

  buildGroup = (options) ->
    options ?= {}

    assignments = [assignment1(), assignment2(), assignment3()]
    base =
      "id":1,
      "name":"Assignments",
      "position":1,
      "rules":{},
      "group_weight":1,
      "assignments": assignments
    $.extend base, options

  createAssignmentGroup = (group) ->
    group ?= buildGroup()
    groups = new AssignmentGroupCollection([group])
    groups.models[0]

  createView = (model, options) ->
    options = $.extend {canManage: true}, options
    ENV.PERMISSIONS = { manage: options.canManage }

    view = new AssignmentGroupListItemView
      model: model
      course: new Backbone.Model(id: 1)
      userIsAdmin: options.userIsAdmin
    view.$el.appendTo $('#fixtures')
    view.render()

    view

  createCollectionView = () ->
    model = group3()
    options = $.extend {canManage: true}, options
    ENV.PERMISSIONS = { manage: options.canManage }
    groupCollection = new AssignmentGroupCollection([model])
    assignmentGroupsView = new AssignmentGroupListView
      collection: groupCollection
      sortURL: "http://localhost:3000/courses/1/assignments/"
      assignment_sort_base_url:"http://localhost:3000/courses/1/assignments/"
      course: new Backbone.Model(id: 1)
    assignmentGroupsView.$el.appendTo $('#fixtures')
    assignmentGroupsView.render()
    assignmentGroupsView
    
  test "shows imported icon when integration_data is not empty", ->
    model = createAssignmentGroup()
    model.set('integration_data', { property: 'value' })
    view = createView(model)
    ok view.$("#assignment_group_#{model.id} .ig-header-title .icon-sis-imported").length

  test "does not show imported icon when integration_data is not set", ->
    model = createAssignmentGroup()
    view = createView(model)
    ok !view.$("#assignment_group_#{model.id} .ig-header-title .icon-sis-imported").length

  test "does not show imported icon when integration_data is empty", ->
    model = createAssignmentGroup()
    model.set('integration_data', { })
    view = createView(model)
    ok !view.$("#assignment_group_#{model.id} .ig-header-title .icon-sis-imported").length

  QUnit.module 'AssignmentGroupListItemView as a teacher',
    setup: ->
      fakeENV.setup({
        current_user_roles: ['teacher']
      })
      @model = createAssignmentGroup()
      $(document).off()
      elementToggler.bind()

    teardown: ->
      fakeENV.teardown()
      $('#fixtures').empty()
      $("form.dialogFormView").remove()

  test "initializes collection", ->
    view = createView(@model)
    ok view.collection

  test "drags icon not being overridden on drag", ->
    view = createCollectionView()
    assignmentGroups = {
      item: view.$el.find('.search_show'),
    }
    view.$el.find('#assignment_1').trigger('sortstart', assignmentGroups)
    dragHandle = view.$("#assignment_1").find("i").attr('class')
    equal dragHandle, "icon-drag-handle"


  test "does not parse response with multiple due dates", ->
    models = @model.get("assignments").models
    a1 = models[0]
    a2 = models[1]

    @spy(a1, 'doNotParse')
    @spy(a2, 'doNotParse')

    createView(@model)

    # first assignment has multiple due dates
    ok a1.multipleDueDates()
    ok a1.doNotParse.called

    # second assignment has single due dates
    ok !a2.multipleDueDates()
    ok !a2.doNotParse.called

  test "initializes child views if can manage", ->
    view = createView(@model)
    ok view.editGroupView
    ok view.createAssignmentView
    ok view.deleteGroupView

  test "initializes editGroupView with userIsAdmin property", ->
    view = createView(@model, userIsAdmin: true)
    ok view.editGroupView.userIsAdmin
    view = createView(@model, userIsAdmin: false)
    notOk view.editGroupView.userIsAdmin

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

  test "shouldBeExpanded returns cache state", ->
    view = createView(@model)
    #make sure the cache starts at true
    view.toggleCache() unless view.shouldBeExpanded()
    key = view.cache.toKey view.cacheKey()

    ok view.shouldBeExpanded()
    equal localStorage[key], 'true'

    view.toggleCache()
    ok !view.shouldBeExpanded()
    equal localStorage[key], 'false'

  test "toggleCache correctly toggles cache state", ->
    view = createView(@model)
    #make sure the cache starts at true
    view.toggleCache() unless view.shouldBeExpanded()

    view.toggleCache()

    ok !view.shouldBeExpanded()
    view.toggleCache()
    ok view.shouldBeExpanded()

  test "currentlyExpanded returns expanded state", ->
    view = createView(@model)
    #make sure the cache starts at true
    view.toggleCache() unless view.shouldBeExpanded()
    ok view.currentlyExpanded()

  test "toggleCollapse toggles expansion", ->
    view = createView(@model)
    $toggle_el = view.$el.find(".element_toggler")
    #make sure the cache starts at true
    view.toggleCache() unless view.shouldBeExpanded()

    ok(view.currentlyExpanded())

    view.toggleCollapse()
    ok !view.currentlyExpanded()

    view.toggleCollapse()
    ok view.currentlyExpanded()

  test "displayableRules", ->
    model = createAssignmentGroup(group2())
    view = createView(model)
    equal view.displayableRules().length, 3

  test "cacheKey builds unique key", ->
    view = createView(@model)
    deepEqual view.cacheKey(), ["course", 1, "user", 1, "ag", 1, "expanded"]

  test "disallows deleting groups with frozen assignments", ->
    assignments = @model.get('assignments')
    assignments.first().set('frozen', true)
    view = createView(@model)
    ok view.$("#assignment_group_#{@model.id} a.delete_group.disabled").length

  test "disallows deleting groups with assignments due in closed grading periods", ->
    @model.set('any_assignment_in_closed_grading_period', true)
    assignments = @model.get('assignments')
    assignments.first().set('frozen', false)
    view = createView(@model)
    ok view.$("#assignment_group_#{@model.id} a.delete_group.disabled").length

  test "allows deleting non-frozen groups without assignments due in closed grading periods", ->
    @model.set('any_assignment_in_closed_grading_period', false)
    view = createView(@model)
    ok view.$("#assignment_group_#{@model.id} a.delete_group:not(.disabled)").length

  test "allows deleting frozen groups for admins", ->
    assignments = @model.get('assignments')
    assignments.first().set('frozen', true)
    view = createView(@model, userIsAdmin: true)
    ok view.$("#assignment_group_#{@model.id} a.delete_group:not(.disabled)").length

  test "allows deleting groups with assignments due in closed grading periods for admins", ->
    @model.set('any_assignment_in_closed_grading_period', true)
    view = createView(@model, userIsAdmin: true)
    ok view.$("#assignment_group_#{@model.id} a.delete_group:not(.disabled)").length

  test 'does not provide a view to delete a group with assignments due in a closed grading period', ->
    @model.set('any_assignment_in_closed_grading_period', true)
    view = createView(@model)
    ok !view.deleteGroupView

  test "correctly displays rules tooltip", ->
    model = createAssignmentGroup(group3())
    view = createView(model)
    anchor = view.$("#assignment_group_3 .ag-header-controls .tooltip_link")
    equal anchor.text(), "2 Rules"
    equal anchor.attr("title"), "Drop the lowest score and Drop the highest score"

  QUnit.module 'AssignmentGroupListItemView as an admin',
    setup: ->
      @model = createAssignmentGroup()
      $(document).off()
      elementToggler.bind()

    teardown: ->
      $("form.dialogFormView").remove()
      $('#fixtures').empty()
      fakeENV.teardown()

  test 'provides a view to delete a group when canDelete is true', ->
    @stub @model, 'canDelete', -> true
    @model.set('any_assignment_in_closed_grading_period', true)
    view = createView(@model, userIsAdmin: true)
    ok view.deleteGroupView
    notOk view.$("#assignment_group_#{@model.id} a.delete_group.disabled").length

  test 'provides a view to delete a group when canDelete is false', ->
    @stub @model, 'canDelete', -> false
    @model.set('any_assignment_in_closed_grading_period', true)
    view = createView(@model, userIsAdmin: true)
    ok view.deleteGroupView
    notOk view.$("#assignment_group_#{@model.id} a.delete_group.disabled").length
