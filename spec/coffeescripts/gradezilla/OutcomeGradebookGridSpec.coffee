define [
  'underscore'
  'compiled/gradezilla/OutcomeGradebookGrid'
  'helpers/fakeENV'
  'i18n!gradezilla'
], (_, Grid,fakeENV) ->

  QUnit.module 'OutcomeGradebookGrid',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test 'Grid.Math.mean', ->
    subject = [1,1,2,4,5]
    ok Grid.Math.mean(subject) == 2.6, 'returns a proper average'
    ok Grid.Math.mean(subject, true) == 3, 'optionally rounds result value'
    ok Grid.Math.mean([5,12,2]) == 6.33, 'rounds to two places'

  test 'Grid.Math.median', ->
    odd  = [1,3,2,5,4]
    even = [1,3,2,6,5,4]
    ok Grid.Math.median(odd) == 3, 'properly finds median on odd datasets'
    ok Grid.Math.median(even) == 3.5, 'properly finds median on even datasets'

  test 'Grid.Math.mode', ->
    single   = [1,1,1,3,5]
    multiple = [1,1,2,2,3,5]
    ok Grid.Math.mode(single) == 1, 'returns mode when it is a single node'
    ok Grid.Math.mode(multiple) == 2, 'averages multiple modes to return a single result'

  test 'Grid.View.masteryClassName', ->
    outcome = { mastery_points: 5 }
    ok Grid.View.masteryClassName(8, outcome) == 'exceeds', 'returns "exceeds" if 150% or more of mastery score'
    ok Grid.View.masteryClassName(5, outcome) == 'mastery', 'returns "mastery" if equal to mastery score'
    ok Grid.View.masteryClassName(7, outcome) == 'mastery', 'returns "mastery" if above mastery score'
    ok Grid.View.masteryClassName(3, outcome) == 'near-mastery', 'returns "near-mastery" if half of mastery score or greater'
    ok Grid.View.masteryClassName(1, outcome) == 'remedial', 'returns "remedial" if less than half of mastery score'

  test 'Grid.Events.sort', ->
    rows = [
      { student: { sortable_name: 'Draper, Don'    }, outcome_1: 3 }
      { student: { sortable_name: 'Olson, Peggy'   }, outcome_1: 4 }
      { student: { sortable_name: 'Campbell, Pete' }, outcome_1: 3 }
    ]
    outcomeSort = rows.sort((a, b) -> Grid.Events._sortResults(a, b, true, 'outcome_1'))
    userSort    = rows.sort((a, b) -> Grid.Events._sortStudents(a, b, true))
    ok _.isEqual([3, 3, 4], _.pluck(outcomeSort, 'outcome_1')), 'sorts by result value'
    ok _.map(outcomeSort, (r) -> r.student.sortable_name)[0] == 'Campbell, Pete', 'result sort falls back to sortable name'
    ok _.isEqual(_.map(userSort, (r) -> r.student.sortable_name), ['Campbell, Pete', 'Draper, Don', 'Olson, Peggy']), 'sorts by student name'

  test 'Grid.Util.toColumns for xss', ->
    outcome = { id: 1, title: '<script>' }
    columns = Grid.Util.toColumns([outcome])
    ok _.isEqual(columns[1].name, '&lt;script&gt;')
