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
