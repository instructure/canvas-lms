define [
  'compiled/gradebook2/GradebookHelpers'
  'jsx/gradebook/grid/constants'
  'timezone'
  'compiled/models/Assignment'
], (GradebookHelpers, GradebookConstants, tz, Assignment) ->

  module "GradebookHelpers#noErrorsOnPage",
    setup: ->
      @mockFind = @mock($, "find")

  test "noErrorsOnPage returns true when the dom has no errors", ->
    @mockFind.expects("find").once().returns([])

    ok GradebookHelpers.noErrorsOnPage()

  test "noErrorsOnPage returns false when the dom contains errors", ->
    @mockFind.expects("find").once().returns(["dom element with error message"])

    notOk GradebookHelpers.noErrorsOnPage()

  module "GradebookHelpers#textareaIsGreaterThanMaxLength"

  test "textareaIsGreaterThanMaxLength is false at exactly the max allowed length", ->
    notOk GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH)

  test "textareaIsGreaterThanMaxLength is true at greater than the max allowed length", ->
    ok GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH + 1)

  module "GradebookHelpers#maxLengthErrorShouldBeShown",
    setup: ->
      @mockFind = @mock($, "find")

  test "maxLengthErrorShouldBeShown is false when text length is exactly the max allowed length", ->
    notOk GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH)

  test "maxLengthErrorShouldBeShown is false when there are DOM errors", ->
    @mockFind.expects("find").once().returns(["dom element with error message"])
    notOk GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1)

  test "maxLengthErrorShouldBeShown is true when text length is greater than" +
      "the max allowed length AND there are no DOM errors", ->
    @mockFind.expects("find").once().returns([])
    ok GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1)

  module "GradebookHelpers#gradeIsLocked",
    setup: ->
      @env =
        current_user_roles: []
        GRADEBOOK_OPTIONS:
          multiple_grading_periods_enabled: true
          latest_end_date_of_admin_created_grading_periods_in_the_past: "2013-10-01T10:00:00Z"
      @assignment = new Assignment(id: 1)
      @assignment.due_at = tz.parse("2013-10-01T10:00:00Z")
      @assignment.grading_type = 'points'

  test "gradeIsLocked is false when multiple grading periods are not enabled", ->
    @env.GRADEBOOK_OPTIONS.multiple_grading_periods_enabled = false
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false

  test "gradeIsLocked is false when no grading periods are in the past", ->
    @env.GRADEBOOK_OPTIONS.latest_end_date_of_admin_created_grading_periods_in_the_past = null
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false

  test "gradeIsLocked is false when current user roles are undefined", ->
    @env.current_user_roles = null
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false
    @env.current_user_roles = undefined
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false

  test "gradeIsLocked is false when the current user is an admin", ->
    @env.current_user_roles = ['admin']
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false

  test "gradeIsLocked is true for assignments in the previous grading period", ->
    @assignment.due_at = tz.parse("2013-10-01T09:59:00Z")
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), true

  test "gradeIsLocked is true for assignments due exactly at the end of the previous grading period", ->
    @assignment.due_at = tz.parse("2013-10-01T10:00:00Z")
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), true

  test "gradeIsLocked is false for assignments after the previous grading period", ->
    @assignment.due_at = tz.parse("2013-10-01T10:01:00Z")
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false

  test "gradeIsLocked is false for assignments without a due date", ->
    @assignment.due_at = null
    equal GradebookHelpers.gradeIsLocked(@assignment, @env), false
