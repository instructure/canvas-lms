define [
  'speed_grader_helpers'
  'underscore'
], (SpeedgraderHelpers, _)->

  module "SpeedgraderHelpers#buildIframe",
    setup: ->
      @buildIframe = SpeedgraderHelpers.buildIframe

  test "sets src to given src", ->
    expected = '<iframe id="speedgrader_iframe" src="some/url?with=query"></iframe>'
    equal @buildIframe("some/url?with=query"), expected

  test "applies options as tag attrs", ->
    expected = '<iframe id="speedgrader_iframe" src="path" frameborder="0"></iframe>'
    options = {
      frameborder: 0
    }
    equal @buildIframe("path", options), expected

  test "applies className options as class", ->
    expected = '<iframe id="speedgrader_iframe" src="path" class="test"></iframe>'
    options = {
      className: "test"
    }
    equal @buildIframe("path", options), expected

  module "SpeedgraderHelpers#determineGradeToSubmit",
    setup: ->
      @determineGrade = SpeedgraderHelpers.determineGradeToSubmit
      @student =
        submission:
          score: 89
      @grade =
        val: ->
          "25"

  test "returns grade.val when use_existing_score is false", ->
    equal @determineGrade(false, @student, @grade), "25"

  test "returns existing submission when use_existing_score is true", ->
    equal @determineGrade(true, @student, @grade), "89"

  module "SpeedgraderHelpers#iframePreviewVersion",
    setup: ->
      @previewVersion = SpeedgraderHelpers.iframePreviewVersion

  test "returns empty string if submission is null", ->
    equal @previewVersion(null), ""

  test "returns empty string if submission contains no currentSelectedIndex", ->
    equal @previewVersion({}), ""

  test "returns currentSelectedIndex if version is null", ->
    submission =
      currentSelectedIndex: 0,
      submission_history: [
        { submission: { version: null } },
        { submission: { version: 2 } }
      ]
    equal @previewVersion(submission), "&version=0"

  test "returns currentSelectedIndex if version is the same", ->
    submission =
      currentSelectedIndex: 0,
      submission_history: [
        { submission: { version: 0 } },
        { submission: { version: 1 } }
      ]
    equal @previewVersion(submission), "&version=0"

  test "returns version if its different", ->
    submission =
      currentSelectedIndex: 0,
      submission_history: [
        { submission: { version: 1 } },
        { submission: { version: 2 } }
      ]
    equal @previewVersion(submission), "&version=1"

  test "returns correct version for a given index", ->
    submission =
      currentSelectedIndex: 1,
      submission_history: [
        { submission: { version: 1 } },
        { submission: { version: 2 } }
      ]
    equal @previewVersion(submission), "&version=2"

  test "returns '' if a currentSelectedIndex is not a number", ->
    submission =
      currentSelectedIndex: "one",
      submission_history: [
        { submission: { version: 1 } },
        { submission: { version: 2 } }
      ]
    equal @previewVersion(submission), ""

  test "returns currentSelectedIndex if version is not a number", ->
    submission =
      currentSelectedIndex: 1,
      submission_history: [
        { submission: { version: "one" } },
        { submission: { version: "two" } }
      ]
    equal @previewVersion(submission), "&version=1"

  module "SpeedgraderHelpers#setRightBarDisabled",
    setup: ->
      @fixtureNode = document.getElementById("fixtures")
      @testArea = document.createElement('div')
      @testArea.id = "test_area"
      @fixtureNode.appendChild(@testArea)
      @startingHTML = '<input type="text" id="grading-box-extended"><textarea id="speedgrader_comment_textarea"></textarea><button id="add_attachment"></button><button id="media_comment_button"></button><button id="comment_submit_button"></button>'

    teardown: ->
      @fixtureNode.innerHTML = ""

  test "it properly disables the elements we care about in the right bar", ->
    @testArea.innerHTML = @startingHTML
    SpeedgraderHelpers.setRightBarDisabled(true)
    equal(@testArea.innerHTML, '<input type="text" id="grading-box-extended" class="ui-state-disabled" aria-disabled="true" readonly="readonly"><textarea id="speedgrader_comment_textarea" class="ui-state-disabled" aria-disabled="true" readonly="readonly"></textarea><button id="add_attachment" class="ui-state-disabled" aria-disabled="true" readonly="readonly"></button><button id="media_comment_button" class="ui-state-disabled" aria-disabled="true" readonly="readonly"></button><button id="comment_submit_button" class="ui-state-disabled" aria-disabled="true" readonly="readonly"></button>')

  test "it properly enables the elements we care about in the right bar", ->
    @testArea.innerHTML = @startingHTML
    SpeedgraderHelpers.setRightBarDisabled(false)
    equal(@testArea.innerHTML, @startingHTML)

  module "SpeedgraderHelpers#classNameBasedOnStudent",
    setup: ->
      @student =
        submission_state: null,
        submission: submitted_at: "2016-10-13 12:22:39"

  test "returns graded for graded", ->
    @student.submission_state = 'graded'
    state = SpeedgraderHelpers.classNameBasedOnStudent(@student)
    deepEqual(state, raw: 'graded', formatted: 'graded')

  test "returns 'not graded' for not_graded", ->
    @student.submission_state = 'not_graded'
    state = SpeedgraderHelpers.classNameBasedOnStudent(@student)
    deepEqual(state, raw: 'not_graded', formatted: 'not graded')

  test "returns graded for not_gradeable", ->
    @student.submission_state = 'not_gradeable'
    state = SpeedgraderHelpers.classNameBasedOnStudent(@student)
    deepEqual(state, raw: 'not_gradeable', formatted: 'graded')

  test "returns 'not submitted' for not_submitted", ->
    @student.submission_state = 'not_submitted'
    state = SpeedgraderHelpers.classNameBasedOnStudent(@student)
    deepEqual(state, raw: 'not_submitted', formatted: 'not submitted')

  test "returns resubmitted data for graded_then_resubmitted", ->
    @student.submission_state = 'resubmitted'
    state = SpeedgraderHelpers.classNameBasedOnStudent(@student)
    deepEqual(state, raw: 'resubmitted', formatted: 'graded, then resubmitted (Oct 13 at 12:22pm)')

  module "SpeedgraderHelpers#submissionState",
    setup: ->
      @student =
        submission:
          grade_matches_current_submission: true
      @grading_role = 'teacher'

  test "returns graded if grade matches current submission", ->
    @student.submission.grade_matches_current_submission = true
    @student.submission.grade = 10
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'graded')

  test "returns resubmitted if grade doesn't match current submission", ->
    @student.submission.grade = 10
    @student.submission.grade_matches_current_submission = false
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'resubmitted')

  test "returns not submitted if submission.workflow_state is unsubmitted", ->
    @student.submission.workflow_state = 'unsubmitted'
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'not_submitted')

  test "returns not_gradeable if provisional_grader and student doesn't need provision grade", ->
    @student.submission.workflow_state = 'submitted'
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    @student.submission.provisional_grade_id = null
    @student.needs_provisional_grade = false
    result = SpeedgraderHelpers.submissionState(@student, 'provisional_grader')
    equal(result, 'not_gradeable')

  test "returns not_gradeable if moderator and student doesn't need provision grade", ->
    @student.submission.workflow_state = 'submitted'
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    @student.submission.provisional_grade_id = null
    @student.needs_provisional_grade = false
    result = SpeedgraderHelpers.submissionState(@student, 'moderator')
    equal(result, 'not_gradeable')

  test "returns not_graded if submitted but no grade", ->
    @student.submission.workflow_state = 'submitted'
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'not_graded')

  test "returns not_graded if pending_review", ->
    @student.submission.workflow_state = 'pending_review'
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    @student.submission.grade = 123
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'not_graded')

  test "returns graded if final_provisional_grade.grade exists", ->
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    @student.submission.final_provisional_grade = grade: 123
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'graded')

  test "returns graded if submission excused", ->
    @student.submission.submitted_at =  "2016-10-13 12:22:39"
    @student.submission.excused = true
    result = SpeedgraderHelpers.submissionState(@student, @grading_role)
    equal(result, 'graded')
