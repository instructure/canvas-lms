#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
  'timezone/America/Juneau'
  'timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
  'compiled/behaviors/tooltip'
], (
  Backbone,
  _,
  AssignmentGroupCollection,
  AssignmentGroup,
  Assignment,
  CreateAssignmentView,
  DialogFormView,
  $,
  tz,
  juneau,
  french,
  I18nStubber,
  fakeENV) ->

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

  nameLengthHelper = (view, length, maxNameLengthRequiredForAccount, maxNameLength, postToSis) ->
    name = 'a'.repeat(length)
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
    ENV.MAX_NAME_LENGTH = maxNameLength
    return view.validateBeforeSave({name: name, post_to_sis: postToSis}, [])

  QUnit.module 'CreateAssignmentView',
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
    @stub(DialogFormView.prototype, "close")

    equal @group.get("assignments").length, 2

    view = createView(@group)
    view.onSaveSuccess()

    equal @group.get("assignments").length, 3

  test "the form is cleared after adding an assignment", ->
    @stub(DialogFormView.prototype, "close")

    view = createView(@group)
    view.onSaveSuccess()

    equal view.$("#ag_#{@group.id}_assignment_name").val(), ""
    equal view.$("#ag_#{@group.id}_assignment_points").val(), "0"

  test "moreOptions redirects to new page for creation", ->
    @stub(CreateAssignmentView.prototype, "newAssignmentUrl")
    @stub(CreateAssignmentView.prototype, "redirectTo")

    view = createView(@group)
    view.moreOptions()

    ok view.redirectTo.called

  test "moreOptions redirects to edit page for editing", ->
    @stub(CreateAssignmentView.prototype, "redirectTo")

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
    @stub(view.model, 'frozenAttributes').returns(["due_at"])
    equal view.disableDueAt(), true

  test "disableDueAt returns false if the user is an admin", ->
    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin').returns(true)
    equal view.disableDueAt(), false

  test "disableDueAt returns true if the user is not an admin and the assignment has a due date in a closed grading period", ->
    view = createView(@assignment1)
    @stub(view, 'currentUserIsAdmin').returns(false)
    @stub(view.model, 'inClosedGradingPeriod').returns(true)
    equal view.disableDueAt(), true

  test "openAgain doesn't add datetime for multiple dates", ->
    @stub(DialogFormView.prototype, "openAgain")
    @spy $.fn, "datetime_field"

    view = createView(@assignment1)
    view.openAgain()

    ok $.fn.datetime_field.notCalled

  test "openAgain adds datetime picker", ->
    @stub(DialogFormView.prototype, "openAgain")
    @spy $.fn, "datetime_field"

    view = createView(@assignment2)
    view.openAgain()

    ok $.fn.datetime_field.called

  test "openAgain doesn't add datetime picker if disableDueAt is true", ->
    @stub(DialogFormView.prototype, "openAgain")
    @spy $.fn, "datetime_field"

    view = createView(@assignment2)
    @stub(view, 'disableDueAt').returns(true)

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
    ENV.HAS_GRADING_PERIODS = true
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
    @stub(view, 'currentUserIsAdmin').returns(false)
    data =
      name: "Foo"
      due_at: "2103-08-15T06:00:00Z"
    errors = view.validateBeforeSave(data, [])

    equal errors["due_at"][0]["message"], "Due date cannot fall in a closed grading period"

  test "does not require due_at to be in an open grading period if it is being changed and the user is an admin", ->
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
    @stub(view, 'currentUserIsAdmin').returns(true)
    data =
      name: "Foo"
      due_at: "2103-08-15T06:00:00Z"
    errors = view.validateBeforeSave(data, [])

    notOk errors["due_at"]

  test "requires name to save assignment", ->
    view = createView(@assignment3)
    data =
      name: ""
    errors = view.validateBeforeSave(data, [])

    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is required!"

  test "has an error when a name has 257 chars", ->
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 257, false, 30, '1')
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long, must be under 257 characters"

  test "allows assignment to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true", ->
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 256, false, 30, '1')
    equal errors.length, 0

  test "allows assignment to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded", ->
    @assignment3.grading_type = 'not_graded'
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 15, true, 10, '1')
    equal errors.length, 0

  test "has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and is required, and post_to_sis is true", ->
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 11, true, 10, '1')
    ok errors["name"]
    equal errors["name"].length, 1
    equal errors["name"][0]["message"], "Name is too long, must be under #{ENV.MAX_NAME_LENGTH + 1} characters"

  test "allows assignment to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false", ->
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 11, true, 10, '0')
    equal errors.length, 0

  test "allows assignment to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true", ->
    view = createView(@assignment3)
    errors = nameLengthHelper(view, 10, true, 10, '1')
    equal errors.length, 0

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
