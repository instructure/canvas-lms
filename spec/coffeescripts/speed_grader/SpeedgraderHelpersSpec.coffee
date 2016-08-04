define [
  'speed_grader_helpers'
  'underscore'
], (SpeedgraderHelpers, _)->

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
