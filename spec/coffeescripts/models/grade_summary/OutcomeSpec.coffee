define [
  'compiled/models/grade_summary/Outcome'
], (Outcome) ->

  module "Outcome"

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

  test "#status should be undefined if there is no score", ->
    outcome = new Outcome({mastery_points: 3})
    equal outcome.status(), 'undefined'


  test "#percentProgress should be zero if score isn't defined", ->
    outcome = new Outcome({points_possible: 3})
    equal outcome.percentProgress(), 0

  test "#percentProgress should be score over points possible", ->
    outcome = new Outcome({score: 5, points_possible: 10})
    equal outcome.percentProgress(), 50

  test "#masteryPercent should be master_points over points possible", ->
    outcome = new Outcome({mastery_points: 5, points_possible: 10})
    equal outcome.masteryPercent(), 50
