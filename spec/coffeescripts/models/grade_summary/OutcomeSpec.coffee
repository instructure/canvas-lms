define [
  'compiled/models/grade_summary/Outcome'
], (Outcome) ->

  QUnit.module "Outcome"

  test "#status should be mastery if the score equals the mastery points", ->
    outcome = new Outcome({score: 3, mastery_points: 3})
    equal outcome.status(), 'mastery'

  test "#status should be mastery if the score is greater than the mastery points", ->
    outcome = new Outcome({score: 4, mastery_points: 3})
    equal outcome.status(), 'mastery'

  test "#status should be exceeds if the score is 150% or more of mastery points", ->
    outcome = new Outcome({score: 4.5, mastery_points: 3})
    equal outcome.status(), 'exceeds'

  test "#status should be near if the score is greater than half the mastery points", ->
    outcome = new Outcome({score: 2, mastery_points: 3})
    equal outcome.status(), 'near'

  test "#status should be remedial if the score is less than half the mastery points", ->
    outcome = new Outcome({score: 1, mastery_points: 3})
    equal outcome.status(), 'remedial'

  test "#status should accurately reflect the scaled aggregate score on question bank results", ->
    # score must be defined, but is not used to get a scaled aggregate score
    outcome = new Outcome({percent: 0.60, score: 0, mastery_points: 3, points_possible: 5, question_bank_result: true})
    equal outcome.status(), 'mastery'

  test "#status should be undefined if there is no score", ->
    outcome = new Outcome({mastery_points: 3})
    equal outcome.status(), 'undefined'


  test "#percentProgress should be zero if score isn't defined", ->
    outcome = new Outcome({points_possible: 3})
    equal outcome.percentProgress(), 0

  test "#percentProgress should be score over points possible if 'percent' is not defined", ->
    outcome = new Outcome({score: 5, points_possible: 10})
    equal outcome.percentProgress(), 50

  test "#percentProgress should be percentage of points possible if 'percent' is defined", ->
    outcome = new Outcome({score: 5, points_possible: 10, percent: 0.6})
    equal outcome.percentProgress(), 60

  test "#masteryPercent should be master_points over points possible", ->
    outcome = new Outcome({mastery_points: 5, points_possible: 10})
    equal outcome.masteryPercent(), 50

  test '#parse', ->
    outcome = new Outcome()
    parsed = outcome.parse({
      submitted_or_assessed_at: '2015-04-24T19:27:54Z'
    })

    equal 'object', typeof(parsed['submitted_or_assessed_at']),
      'is an object, not a string'
