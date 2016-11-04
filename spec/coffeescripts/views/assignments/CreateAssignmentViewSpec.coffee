define [
  'Backbone'
  'underscore'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/DialogFormView'
  'jquery'
  'timezone'
  'vendor/timezone/America/Juneau'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
  'compiled/behaviors/tooltip'
], (Backbone, _, AssignmentGroupCollection, AssignmentGroup, Assignment, CreateAssignmentView, DialogFormView, $, tz, juneau, french, I18nStubber, fakeENV) ->

  fixtures = $('#fixtures')

  buildAssignment1 = ->
    date1 =
      "due_at": new Date("2103-08-28T00:00:00").toISOString()
      "title":"Summer Session"
    date2 =
      "due_at": new Date("2103-08-28T00:00:00").toISOString()
      "title":"Winter Session"

    buildAssignment(
      "id":1
      "name":"History Quiz"
      "description":"test"
      "due_at": new Date("August 21, 2013").toISOString()
      "points_possible":2
      "position":1
      "all_dates":[date1, date2]
    )

  buildAssignment2 = ->
    buildAssignment(
      "id":3
      "name":"Math Quiz"
      "due_at": new Date("August 23, 2013").toISOString()
      "points_possible":10
      "position":2
    )

  buildAssignment3 = ->
    buildAssignment(
      "id":4
      "name":""
      "due_at": ""
      "points_possible":10
      "position":3
    )

  buildAssignment4 = ->
    buildAssignment(
      "id":5
      "name":""
      "due_at": ""
      "unlock_at": new Date("August 1, 2013").toISOString()
      "lock_at": new Date("August 30, 2013").toISOString()
      "points_possible":10
      "position":4
    )

  buildAssignment5 = ->
    buildAssignment(
      "id": 6
      "name": "Page assignment"
      "submission_types":['wiki_page']
      "grading_type": "not_graded"
      "points_possible": null
      "position": 5
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
      @assignment1 = new Assignment(buildAssignment1())
      @assignment2 = new Assignment(buildAssignment2())
      @assignment3 = new Assignment(buildAssignment3())
      @assignment4 = new Assignment(buildAssignment4())
      @assignment5 = new Assignment(buildAssignment5())
      @group       = assignmentGroup()

      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      fakeENV.setup()

    teardown: ->
      fakeENV.teardown()
      tz.restore(@snapshot)
      I18nStubber.popFrame()

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

  test "render hides date picker and points_possible for pages", ->
    view = createView(@assignment5)
    equal view.$('.date_field_container').length, 0
    equal view.$('input[name=points_possible]').length, 0

  test "onSaveSuccess adds model to assignment group for creation", ->
    @stub(DialogFormView.prototype, "close", ->)

    equal @group.get("assignments").length, 2

    view = createView(@group)
    view.onSaveSuccess()

    equal @group.get("assignments").length, 3

  test "the form is cleared after adding an assignment", ->
    @stub(DialogFormView.prototype, "close", ->)

    view = createView(@group)
    view.onSaveSuccess()

    equal view.$("#ag_#{@group.id}_assignment_name").val(), ""
    equal view.$("#ag_#{@group.id}_assignment_points").val(), "0"

  test "moreOptions redirects to new page for creation", ->
    @stub(CreateAssignmentView.prototype, "newAssignmentUrl", ->)
    @stub(CreateAssignmentView.prototype, "redirectTo", ->)

    view = createView(@group)
    view.moreOptions()

    ok view.redirectTo.called

  test "moreOptions redirects to edit page for editing", ->
    @stub(CreateAssignmentView.prototype, "redirectTo", ->)

    view = createView(@assignment1)
    view.moreOptions()

    ok view.redirectTo.called

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

  test "toJSON includes key for disableDueAt", ->
    view = createView(@assignment1)
    keys = _.keys(view.toJSON())
    ok _.contains(keys, "disableDueAt")

  test "toJSON includes key for isInClosedPeriod", ->
    view = createView(@assignment1)
    keys = _.keys(view.toJSON())
    ok _.contains(keys, "isInClosedPeriod")

  test "disableDueAt returns true if due_at is a frozen attribute", ->
    view = createView(@assignment1)
    @stub(view.model, 'frozenAttributes', -> ["due_at"])
    equal view.disableDueAt(), true

  test "disableDueAt returns false if the user is an admin", ->
    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin', -> true)
    equal view.disableDueAt(), false

  test "disableDueAt returns true if the user is not an admin and the assignment has " +
  "a due date in a closed grading period", ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin', -> false)
    @stub(view.model, 'hasDueDateInClosedGradingPeriod', -> true)
    equal view.disableDueAt(), true

  test "openAgain doesn't add datetime for multiple dates", ->
    @stub(DialogFormView.prototype, "openAgain", ->)
    @spy $.fn, "datetime_field"

    view = createView(@assignment1)
    view.openAgain()

    ok $.fn.datetime_field.notCalled

  test "openAgain adds datetime picker", ->
    @stub(DialogFormView.prototype, "openAgain", ->)
    @spy $.fn, "datetime_field"

    view = createView(@assignment2)
    view.openAgain()

    ok $.fn.datetime_field.called

  test "openAgain doesn't add datetime picker if disableDueAt is true", ->
    @stub(DialogFormView.prototype, "openAgain", ->)
    @spy $.fn, "datetime_field"

    view = createView(@assignment2)
    @stub(view, 'disableDueAt', -> true)

    view.openAgain()

    ok $.fn.datetime_field.notCalled

  test "requires name to save assignment", ->
    view = createView(@assignment3)
    data =
      name: ""
    errors = view.validateBeforeSave(data, [])

    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is required!"

  test "requires due_at to be in an open grading period if it is being changed and the user is a teacher", ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    ENV.active_grading_periods = [{
      id: "1"
      start_date: "2103-07-01T06:00:00Z"
      end_date: "2103-08-31T06:00:00Z"
      title: "Closed Period"
      close_date: "2103-08-31T06:00:00Z"
      is_last: false
      is_closed: true
    }]

    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin', -> false)
    data =
      name: "Foo"
      due_at: "2103-08-15T06:00:00Z"
    errors = view.validateBeforeSave(data, [])

    equal errors["due_at"][0]["message"], "Due date cannot fall in a closed grading period"

  test "does not require due_at to be in an open grading period if it is being changed and the user is an admin", ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    ENV.active_grading_periods = [{
      id: "1"
      start_date: "2103-07-01T06:00:00Z"
      end_date: "2103-08-31T06:00:00Z"
      title: "Closed Period"
      close_date: "2103-08-31T06:00:00Z"
      is_last: false
      is_closed: true
    }]

    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin', -> true)
    data =
      name: "Foo"
      due_at: "2103-08-15T06:00:00Z"
    errors = view.validateBeforeSave(data, [])

    notOk errors["due_at"]

  test "requires a name < 255 chars to save assignment", ->
    view = createView(@assignment3)
    l1 = 'aaaaaaaaaa'
    l2 = l1 + l1 + l1 + l1 + l1 + l1
    l3 = l2 + l2 + l2 + l2 + l2 + l2
    ok l3.length > 255

    errors = view.validateBeforeSave(name: l3, [])
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long"

  test "don't validate name if it is frozen", ->
    view = createView(@assignment3)
    @assignment3.set('frozen_attributes', ['title'])

    errors = view.validateBeforeSave({}, [])
    ok !errors["name"]

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

  test 'validates due date against date range', ->
    start_at = {date: new Date("August 20, 2013").toISOString(), date_context: "term"}
    end_at = {date: new Date("August 30, 2013").toISOString(), date_context: "course"}

    ENV.VALID_DATE_RANGE = {
      start_at: start_at
      end_at: end_at
    }
    view = createView(@assignment3)
    data =
      name: "Example"
      due_at: new Date("September 1, 2013").toISOString()
    errors = view.validateBeforeSave(data, [])
    equal errors['due_at'][0]['message'], 'Due date cannot be after course end'

    data =
      name: "Example"
      due_at: new Date("July 1, 2013").toISOString()
    errors = view.validateBeforeSave(data, [])
    ok errors["due_at"]
    equal errors['due_at'][0]['message'], 'Due date cannot be before term start'

    equal start_at, ENV.VALID_DATE_RANGE.start_at
    equal end_at,   ENV.VALID_DATE_RANGE.end_at

  test 'validates due date for lock and unlock', ->
    view = createView(@assignment4)

    data =
      name: "Example"
      due_at: new Date("September 1, 2013").toISOString()
    errors = view.validateBeforeSave(data, [])
    ok errors["due_at"]
    equal errors['due_at'][0]['message'], 'Due date cannot be after lock date'

    data =
      name: "Example"
      due_at: new Date("July 1, 2013").toISOString()
    errors = view.validateBeforeSave(data, [])
    ok errors["due_at"]
    equal errors['due_at'][0]['message'], 'Due date cannot be before unlock date'

  test "renders due dates with locale-appropriate format string", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.short': '%-d %b'
      'date.abbr_month_names.8': 'août'
    view = createView(@assignment1)
    equal view.$("#vdd_tooltip_assign_1 div dd").first().text().trim(), '28 août'

  test "renders due dates in appropriate time zone", ->
    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'date.formats.short': '%b %-d'
      'date.abbr_month_names.8': 'Aug'
    view = createView(@assignment1)
    equal view.$("#vdd_tooltip_assign_1 div dd").first().text().trim(), 'Aug 27'
