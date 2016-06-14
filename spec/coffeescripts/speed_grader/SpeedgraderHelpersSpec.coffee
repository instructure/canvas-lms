define [
  'speed_grader_helpers'
], (SpeedgraderHelpers)->

  module "SpeedGraderHelpers",
    setup: ->
      @student =
        submission:
          score: 89
      @grade =
        val: ->
          "25"

  test "determine grade returns grade.val when use_existing_score is false", ->
    equal(SpeedgraderHelpers.determineGradeToSubmit(false, @student, @grade), "25")

  test "determine grade returns existing submission when use_existing_score is true", ->
    equal(SpeedgraderHelpers.determineGradeToSubmit(true, @student, @grade), "89")
