define [
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/DialogFormView'
  'jquery'
  'helpers/jquery.simulate'
  'compiled/behaviors/tooltip'
], (Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, CreateAssignmentView, DialogFormView, $) ->

  fixtures = $('#fixtures')

  assignment1 = ->
    new Assignment(buildAssignment1())

  assignment2 = ->
    new Assignment(buildAssignment2())

  assignment3 = ->
    new Assignment(buildAssignment3())

  buildAssignment1 = ->
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

  buildAssignment2 = ->
    buildAssignment(
      "id":3
      "name":"Math Quiz"
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
      "position":2
    )

  buildAssignment3 = ->
    buildAssignment(
      "id":4
      "name":""
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
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

  assignmentGroup = ->
    assignments = [buildAssignment1(), buildAssignment2()]
    group = "id":1, "name":"Assignments", "position":1, "rules":{}, "group_weight":1, "assignments": assignments
    groups = new AssignmentGroupCollection([group])
    groups.models[0]

  createView = (model) ->
    opts = if model.constructor is AssignmentGroup
      assignmentGroup: model
    else
      model: model

    view = new CreateAssignmentView(opts)
    view.$el.appendTo $('#fixtures')
    view.render()

  module 'CreateAssignmentView',
    setup: ->
      @assignment1 = assignment1()
      @assignment2 = assignment2()
      @assignment3 = assignment3()
      @group       = assignmentGroup()

  test "initialize generates a new assignment for creation", ->
    view = createView(@group)
    equal view.model.get("assignment_group_id"), @group.get("id")

  test "initialize uses existing assignment for editing", ->
    view = createView(@assignment1)
    equal view.model.get("name"), @assignment1.get("name")

  test "render shows multipleDueDates if we have all dates", ->
    view = createView(@assignment1)
    equal view.$('.multiple_due_dates').length, 1

  test "render shows date picker when there are not multipleDueDates", ->
    view = createView(@assignment2)
    equal view.$('.multiple_due_dates').length, 0

  test "render shows canChooseType for creation", ->
    view = createView(@group)
    equal view.$("#ag_1_assignment_type").length, 1
    equal view.$("#assign_1_assignment_type").length, 0

  test "render hides canChooseType for editing", ->
    view = createView(@assignment1)
    equal view.$("#ag_1_assignment_type").length, 0
    equal view.$("#assign_1_assignment_type").length, 0

  test "onSaveSuccess adds model to assignment group for creation", ->
    sinon.stub( DialogFormView.prototype, "close", -> )

    equal @group.get("assignments").length, 2

    view = createView(@group)
    view.onSaveSuccess()

    equal @group.get("assignments").length, 3

    DialogFormView.prototype.close.restore()

  test "the form is cleared after adding an assignment", ->
    sinon.stub( DialogFormView.prototype, "close", -> )

    view = createView(@group)
    view.onSaveSuccess()

    equal view.$("#ag_#{@group.id}_assignment_name").val(), ""
    equal view.$("#ag_#{@group.id}_assignment_points").val(), "0"

    DialogFormView.prototype.close.restore()

  test "moreOptions redirects to new page for creation", ->
    sinon.stub( CreateAssignmentView.prototype, "newAssignmentUrl", -> )
    sinon.stub( CreateAssignmentView.prototype, "redirectTo",       -> )

    view = createView(@group)
    view.moreOptions()

    ok view.redirectTo.called
    CreateAssignmentView.prototype.newAssignmentUrl.restore()
    CreateAssignmentView.prototype.redirectTo.restore()

  test "moreOptions redirects to edit page for editing", ->
    sinon.stub( CreateAssignmentView.prototype, "redirectTo", -> )

    view = createView(@assignment1)
    view.moreOptions()

    ok view.redirectTo.called
    CreateAssignmentView.prototype.redirectTo.restore()

  test "generateNewAssignment builds new assignment model", ->
    view = createView(@group)
    assign = view.generateNewAssignment()
    ok assign.constructor == Assignment

  test "toJSON creates unique label for creation", ->
    view = createView(@group)
    json = view.toJSON()
    equal json.uniqLabel, "ag_1"

  test "toJSON creates unique label for editing", ->
    view = createView(@assignment1)
    json = view.toJSON()
    equal json.uniqLabel, "assign_1"

  test "toJSON includes can choose type when creating", ->
    view = createView(@group)
    json = view.toJSON()
    ok json.canChooseType

  test "toJSON includes cannot choose type when creating", ->
    view = createView(@assignment1)
    json = view.toJSON()
    ok !json.canChooseType

  test "openAgain doesn't add datetime for multiple dates", ->
    sinon.stub( DialogFormView.prototype, "openAgain", -> )
    sinon.spy $.fn, "datetime_field"

    view = createView(@assignment1)
    view.openAgain()

    ok $.fn.datetime_field.notCalled

    $.fn.datetime_field.restore()
    DialogFormView.prototype.openAgain.restore()

  test "openAgain adds datetime picker", ->
    sinon.stub( DialogFormView.prototype, "openAgain", -> )
    sinon.spy $.fn, "datetime_field"

    view = createView(@assignment2)
    view.openAgain()

    ok $.fn.datetime_field.called

    $.fn.datetime_field.restore()
    DialogFormView.prototype.openAgain.restore()

  test "requires name to save assignment", ->
    view = createView(@assignment3)
    data =
      name: ""
    errors = view.validateBeforeSave(data, [])

    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is required!"

  test 'rejects a letter for points_possible', ->
    view = createView(@assignment3)
    data =
      name: "foo"
      points_possible: 'a'
    errors = view.validateBeforeSave(data, [])
    ok errors["points_possible"]
    equal errors['points_possible'][0]['message'], 'Points possible must be a number'

  test 'passes explicit submission_type for Assignment option', ->
    view = createView(@group)
    data = view.getFormData()
    equal data.submission_types, 'none'
