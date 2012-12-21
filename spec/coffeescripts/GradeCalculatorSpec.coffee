define ['compiled/grade_calculator', 'underscore'], (GradeCalculator, _) ->
  # convenient way to test GradeCalculator.calculate results
  # if currentOrFinal is 'current', ungraded assignments will be ignored
  assertGrade = (result, currentOrFinal, score, possible) ->
    equal result[currentOrFinal].score, score
    equal result[currentOrFinal].possible, possible

  # asserts sure that all the given submissions were dropped
  assertDropped = (submissions, grades...) ->
    _(grades).each ([score, possible]) ->
      submission = _(submissions).find (s) ->
        s.score == score && s.possible == possible
      equal submission.drop, true

  module "GradeCalculator",
    setup: ->
      # submission grades (100/100, 3/38, etc).  null means ungraded.
      # if these grades are changed or added to, be careful to respect the
      # weird drop behavior (see the test for drop_lowest below).
      @setup_grades [[100,100], [42,91], [14,55], [3,38], [null,1000]]

    setup_grades: (grades) ->
      @assignments = grades.map ([z,possible], i) ->
        assignment =
          points_possible: possible,
          id: i
      @submissions = grades.map ([score,z], i) ->
        submission =
          assignment_id: i
          score: score
      @group =
        id: 1
        assignments: @assignments


  test "without submissions or assignments", ->
    group =
      id: 1
      rules: {}
      assignments: []

    result = GradeCalculator.calculate [], [group]
    assertGrade result, 'current', 0, 0
    assertGrade result, 'final', 0, 0

  test "without submissions", ->
    @group.rules = {}
    result = GradeCalculator.calculate [], [@group]
    assertGrade result, 'current', 0, 0
    assertGrade result, 'final', 0, 1284

  test "no drop rules", ->
    @group.rules = {}

    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 159, 284
    assertGrade result, 'final', 159, 1284

  test "drop lowest", ->
    @group.rules = drop_lowest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 156, 246
    assertDropped result.group_sums[0].current.submissions, [3, 38]
    assertGrade result, 'final', 159, 284
    assertDropped result.group_sums[0]['final'].submissions, [0, 1000]

    # NOTE: this example illustrates that even though 3/38 was the optimal
    # grade to drop when just one assignment was dropped, it is no longer
    # optimal to drop that assignment when 2 grades are dropped
    @group.rules = drop_lowest: 2
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 103, 138
    assertDropped result.group_sums[0].current.submissions, [42, 91], [14, 55]
    assertGrade result, 'final', 156, 246
    assertDropped result.group_sums[0]['final'].submissions, [0, 1000], [3, 38]

  test "drop highest", ->
    @group.rules = drop_highest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 59, 184
    assertDropped result.group_sums[0].current.submissions, [100, 100]
    assertGrade result, 'final', 59, 1184
    assertDropped result.group_sums[0]['final'].submissions, [100, 100]

    @group.rules = drop_highest: 2
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 17, 93
    assertDropped result.group_sums[0].current.submissions, [100, 100], [42, 91]
    assertGrade result, 'final', 17, 1093
    assertDropped result.group_sums[0]['final'].submissions, [100, 100], [42, 91]

    @group.rules = drop_highest: 3
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 3, 38
    assertDropped result.group_sums[0].current.submissions, [100, 100], [42, 91], [14, 55]
    assertGrade result, 'final', 3, 1038
    assertDropped result.group_sums[0]['final'].submissions, [100, 100], [42, 91], [14, 55]

  test "drop highest (again)", ->
    @setup_grades [[0,10], [10,20], [28,50], [91,100]]

    @group.rules = drop_highest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 38, 80
    assertDropped result.group_sums[0].current.submissions, [91, 100]

    @group.rules = drop_highest: 2
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 10, 30
    assertDropped result.group_sums[0].current.submissions, [28, 50], [91, 100]

    @group.rules = drop_highest: 3
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 0, 10
    assertDropped result.group_sums[0].current.submissions, [10, 20], [28, 50], [91, 100]

  test "never drop", ->
    @group.rules =
      drop_lowest: 1
      never_drop: [3] # 3/38
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 145, 229
    assertDropped result.group_sums[0].current.submissions, [14, 55]
    assertGrade result, 'final', 159, 284
    assertDropped result.group_sums[0]['final'].submissions, [0, 1000]
