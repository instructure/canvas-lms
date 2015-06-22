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
      @group = id: 1
      # submission grades (100/100, 3/38, etc).  null means ungraded.
      # if these grades are changed or added to, be careful to respect the
      # weird drop behavior (see the test for drop_lowest below).
      @setup_grades @group, [[100,100], [42,91], [14,55], [3,38], [null,1000]]

    setup_grades: (group, grades) ->
      @assignment_id ||= 0
      assignments = grades.map ([z,possible], i) =>
        assignment =
          points_possible: possible,
          id: @assignment_id + i
      @submissions ||= []
      submissions = grades.map ([score,z], i) =>
        submission =
          assignment_id: @assignment_id + i
          score: score
      @assignment_id += grades.length
      @submissions = @submissions.concat submissions
      group.assignments = assignments

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

  test "should work with submissions that have 0 points possible", ->
    @submissions = []
    @group.rules = {}
    @setup_grades @group, [[10,0], [10,10], [10, 10], [null,10]]
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 30, 20
    assertGrade result, 'final', 30, 30

    @group.rules = drop_lowest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 20, 10
    assertGrade result, 'final', 30, 20

  test "no submissions have points possible", ->
    @submissions = []
    @setup_grades @group, [[10,0], [5,0], [20,0], [0,0]]
    @group.rules = drop_lowest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 35, 0
    assertDropped result.group_sums[0]['current'].submissions, [0,0]

    @group.rules = drop_lowest: 2, drop_highest: 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 10, 0
    assertDropped result.group_sums[0]['current'].submissions, [0,0], [5,0], [20,0]

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

  test "drop lowest (again)", ->
    @submissions = []
    @setup_grades @group,
                  [[30, null], [30, null], [30, null], [31, 31], [21, 21],
                  [30, 30], [30, 30], [30, 30], [30, 30], [30, 30], [30, 30],
                  [30, 30], [30, 30], [30, 30], [30, 30], [29.3, 30], [30, 30],
                  [30, 30], [30, 30], [12, 0], [30, null]]
    @group.rules = drop_lowest: 2
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'final',  543, 411
    assertDropped result.group_sums[0]['final'].submissions, [31, 31], [29.3, 30]

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
    @submissions = []
    @setup_grades @group, [[0,10], [10,20], [28,50], [91,100]]

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

  test "unreasonable drop rules", ->
    @submissions = []
    @setup_grades @group, [[10,10],[9,10],[8,10]]
    @group.rules =
      drop_lowest: 1000
      drop_highest: 1000
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 10, 10
    assertDropped result.group_sums[0].current.submissions, [9,10], [8,10]

  test "never drop", ->
    @group.rules =
      drop_lowest: 1
      never_drop: [3] # 3/38
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 145, 229
    assertDropped result.group_sums[0].current.submissions, [14, 55]
    assertGrade result, 'final', 159, 284
    assertDropped result.group_sums[0]['final'].submissions, [0, 1000]

    @assignment_id = 0
    @submissions = []
    @setup_grades @group, [[10,20], [5,10], [20,40], [0,100]]
    @group.rules = drop_lowest: 1, never_drop: [3]
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 30, 160
    assertDropped result.group_sums[0].current.submissions, [5,10]

    @assignment_id = 0
    @submissions = []
    @setup_grades @group, [[10,20], [5,10], [20,40], [100,100]]
    @group.rules = drop_lowest: 1, never_drop: [3]
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 115, 130
    assertDropped result.group_sums[0].current.submissions, [20,40]

    @assignment_id = 0
    @submissions = []
    @setup_grades @group, [[101.9,100], [105.65,100], [103.8,100], [0,0]]
    @group.rules = drop_lowest: 1, never_drop: [2]
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 209.45, 200
    assertDropped result.group_sums[0].current.submissions, [101.9,100]

    # works with string ids
    @assignment_id = 0
    @submissions = []
    @setup_grades @group, [[100,100], [42,91], [14,55], [3,38], [null,1000]]
    @group.rules = drop_lowest: 1, never_drop: ["3"] # 3/38
    @group.assignments.map (a) -> a.id = a.id.toString()
    @submissions.map (s) -> s.assignment_id = s.assignment_id.toString()
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 145, 229
    assertDropped result.group_sums[0].current.submissions, [14, 55]
    assertGrade result, 'final', 159, 284
    assertDropped result.group_sums[0]['final'].submissions, [0, 1000]

  test "grade dropping in ridiculous circumstances", ->
    @setup_grades @group, [[null, 20], [3, 10], [null, 10],
      [null, 100000000000000007629769841091887003294964970946560],
      [null, null]]

    @group.rules = drop_lowest: 2
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'current', 3, 10
    assertGrade result, 'final', 3, 20

  test "assignment groups with 0 points possible", ->
    @submissions = []
    @group1 = @group
    @group1.group_weight = 50
    @group2 = id: 2, group_weight: 25
    @group3 = id: 3, group_weight: 25
    @group4 = id: 4, group_weight: 10
    groups = [@group1, @group2, @group3, @group4]

    @setup_grades @group1, [[9, 10]]
    @setup_grades @group2, [[5, 10]]
    # @group3 is empty
    @setup_grades @group4, [[10, 0], [5, 0]]

    result = GradeCalculator.calculate @submissions, groups, 'percent'
    assertGrade result, 'current', 76.67, 100
    assertGrade result, 'final', 76.67, 100

    result = GradeCalculator.calculate @submissions, groups, 'equal'
    assertGrade result, 'current', 29, 20
    assertGrade result, 'final', 29, 20

  test "grade should always drop assignments consistently", ->
    # NOTE: this test doesn't get reproduced in ruby because the drop set is
    # discarded after calculation
    @submissions = []
    @setup_grades @group, [[9,10],[9,10],[9,10],[9,10]]
    @group.rules = drop_lowest: 1

    result = GradeCalculator.calculate @submissions, [@group]
    dropped = _(result.group_sums[0].current.submissions).find (s) -> s.drop
    firstDroppedAssignment = dropped.submission.assignment_id

    @submissions.reverse()
    result = GradeCalculator.calculate @submissions, [@group]
    dropped2 = _(result.group_sums[0].current.submissions).find (s) -> s.drop
    equal firstDroppedAssignment, dropped2.submission.assignment_id

  test "with Differentiated Assignments filtering", ->
    @submissions.slice(1).forEach (s) ->
      s["hidden"] = true

    result = GradeCalculator.create_group_sum @group, @submissions, true
    equal result.submissions.length, 1

  test "excused assignments", ->
    @submissions = []
    @group.rules = {}
    @setup_grades @group, [[10, 10], [0, 90]]
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'final', 10, 100

    @submissions[1].excused = 1
    result = GradeCalculator.calculate @submissions, [@group]
    assertGrade result, 'final', 10, 10
