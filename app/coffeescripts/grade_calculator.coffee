define [
  'underscore'
  'compiled/util/round'
], (_, round) ->

  partition = (list, f) ->
    trueList  = []
    falseList = []
    _(list).each (x) ->
      (if f(x) then trueList else falseList).push(x)
    [trueList, falseList]

  class GradeCalculator
    # each submission needs fields: score, points_possible, assignment_id, assignment_group_id, excused
    #   to represent assignments that the student hasn't submitted, pass a
    #   submission with score == null
    #
    # each group needs fields: id, rules, group_weight, assignments
    #   rules is { drop_lowest: n, drop_highest: n, never_drop: [id...] }
    #   assignments is [
    #    { id, points_possible, submission_types},
    #    ...
    #   ]
    #
    # if weighting_scheme is "percent", group weights are used, otherwise no
    # weighting is applied
    @calculate: (submissions, groups, weighting_scheme) ->
      result = {}
      result.group_sums = _(groups).map (group) =>
        group: group
        current: @create_group_sum(group, submissions, true)
        'final': @create_group_sum(group, submissions, false)
      result.current  = @calculate_total(result.group_sums, true, weighting_scheme)
      result['final'] = @calculate_total(result.group_sums, false, weighting_scheme)
      result

    @create_group_sum: (group, submissions, ignoreUngraded) ->
      # remove assignments without visibility from gradeableAssignments
      hiddenAssignments = _.chain(submissions).
                            filter('hidden').
                            indexBy('assignment_id').value()

      gradeableAssignments = _(group.assignments).reject (a) ->
        a.omit_from_final_grade || hiddenAssignments[a.id] || _.isEqual(a.submission_types, ['not_graded'])
      assignments = _.indexBy gradeableAssignments, "id"

      # filter out submissions from other assignment groups
      submissions = _(submissions).filter (s) -> assignments[s.assignment_id]?

      # fill in any missing submissions
      unless ignoreUngraded
        submissionAssignmentIds = _(submissions).map (s) ->
          s.assignment_id.toString()
        missingSubmissions = _.difference(_.keys(assignments),
                                          submissionAssignmentIds)
        dummySubmissions = _(missingSubmissions).map (assignmentId) ->
          s = assignment_id: assignmentId, score: null
        submissions.push dummySubmissions...

      # filter out excused assignments
      submissions = _(submissions).filter (s) -> not s.excused

      submissionsByAssignment = _.indexBy submissions, "assignment_id"

      submissionData = _(submissions).map (s) =>
        sub =
          total: @parse assignments[s.assignment_id].points_possible
          score: @parse s.score
          submitted: s.score? and s.score != ''
          pending_review: s.workflow_state == "pending_review"
          submission: s
      relevantSubmissionData = if ignoreUngraded
        _(submissionData).filter (s) -> s.submitted && not s.pending_review
      else
        submissionData

      kept = @dropAssignments relevantSubmissionData, group.rules

      [score, possible] = _.reduce kept
      , ([scoreSum, totalSum], {score,total}) =>
        [scoreSum + @parse(score), totalSum + total]
      , [0, 0]

      ret =
        possible: possible
        score: score
        # TODO: figure out what submission_count is actually counting
        submission_count: (_(submissionData).filter (s) -> s.submitted).length
        submissions: _(submissionData).map (s) =>
          submissionRet =
            drop: s.drop
            percent: @parse(s.score / s.total)
            possible: s.total
            score: @parse(s.score)
            submission: s.submission
            submitted: s.submitted

    # I'm not going to pretend that this code is understandable.
    #
    # The naive approach to dropping the lowest grades (calculate the
    # grades for each combination of assignments and choose the set which
    # results in the best overall score) is obviously too slow.
    #
    # This approach is based on the algorithm described in "Dropping Lowest
    # Grades" by Daniel Kane and Jonathan Kane.  Please see that paper for
    # a full explanation of the math.
    # (http://cseweb.ucsd.edu/~dakane/droplowest.pdf)
    @dropAssignments: (submissions, rules) ->
      rules or= {}
      dropLowest   = rules.drop_lowest  || 0
      dropHighest  = rules.drop_highest || 0
      neverDropIds = rules.never_drop || []
      return submissions unless dropLowest or dropHighest

      if neverDropIds.length > 0
        [cantDrop, submissions] = partition(submissions, (s) ->
          _.indexOf(neverDropIds, s.submission.assignment_id) >= 0)
      else
        cantDrop = []

      return cantDrop if submissions.length == 0
      dropLowest = submissions.length - 1 if dropLowest >= submissions.length
      dropHighest = 0 if dropLowest + dropHighest >= submissions.length

      keepHighest = submissions.length - dropLowest
      keepLowest  = keepHighest - dropHighest

      hasPointed = (s.total for s in submissions when s.total > 0).length > 0
      kept = if hasPointed
        @dropPointed submissions, cantDrop, keepHighest, keepLowest
      else
        @dropUnpointed submissions, keepHighest, keepLowest

      kept.push cantDrop...

      dropped = _.difference(submissions, kept)
      s.drop = true for s in dropped

      kept

    @dropUnpointed: (submissions, keepHighest, keepLowest) ->
      sortedSubmissions = submissions.sort @stableSubmissionSort(
        (a,b) -> a.score - b.score,
        (s) -> s.submission.assignment_id
      )

      _.chain(sortedSubmissions).last(keepHighest).first(keepLowest).value()

    @dropPointed: (submissions, cantDrop, keepHighest, keepLowest) ->
      totals = (s.total for s in submissions)
      maxTotal = Math.max(totals...)

      keepHelper = (submissions, keep, bigFSort) =>
        keep = 1 if keep <= 0
        return submissions if submissions.length <= keep

        allSubmissions = submissions.concat(cantDrop)
        [unpointed, pointed] = partition allSubmissions, (s) -> s.total == 0

        grades = (s.score / s.total for s in pointed).sort (a,b) -> a - b
        qHigh = @estimateQHigh(pointed, unpointed, grades)
        qLow  = grades[0]
        qMid  = (qLow + qHigh) / 2

        bigF = (q, submissions) ->
          ratedScores  = _(submissions).map (s) ->
            ratedScore = s.score - q * s.total
            [ratedScore, s]
          rankedScores = ratedScores.sort bigFSort #(a, b) -> b[0] - a[0]
          keptScores = rankedScores[0...keep]
          qKept = _.reduce keptScores
          , (sum, [ratedScore, s]) ->
            sum + ratedScore
          , 0
          keptSubmissions = (s for [ratedScore, s] in keptScores)
          qCantDrop = _.reduce(cantDrop, ((sum, s) -> sum + s.score - q * s.total), 0)
          [qKept + qCantDrop, keptSubmissions]

        [x, kept] = bigF(qMid, submissions)
        threshold = 1 /(2 * keep * Math.pow(maxTotal, 2))
        until qHigh - qLow < threshold
          if x < 0
            qHigh = qMid
          else
            qLow = qMid
          qMid = (qLow + qHigh) / 2

          break if qMid == qHigh || qMid == qLow

          [x, kept] = bigF(qMid, submissions)

        kept

      kept = keepHelper(submissions, keepHighest, @stableSubmissionSort(
        ([a,xx], [b,yy]) -> b - a,
        ([_score,s]) -> s.submission.assignment_id
      ))
      kept = keepHelper(kept, keepLowest, @stableSubmissionSort(
        ([a,xx], [b,yy]) -> a - b,
        ([_score,s]) -> s.submission.assignment_id
      ))

    @estimateQHigh: (pointed, unpointed, grades) ->
      if unpointed.length > 0
        pointsPossible = _(pointed).reduce(((sum, s) -> sum + s.total), 0)
        bestPointedScore = Math.max(
          pointsPossible,
          _(pointed).reduce(((sum, s) -> sum + s.score), 0)
        )
        unpointedScore = _(unpointed).reduce(((sum, s) -> sum + s.score), 0)
        maxScore = bestPointedScore + unpointedScore
        maxScore / pointsPossible
      else
        qHigh = grades[grades.length - 1]

    # v8's sort is not stable, this function ensures that the same submission
    # will be dropped regardless of browser
    @stableSubmissionSort: (sortFn, getAssignmentIdFn) ->
      (a, b) ->
        ret = sortFn(a, b)
        if ret == 0
          getAssignmentIdFn(a) - getAssignmentIdFn(b)
        else
          ret

    @calculate_total: (groupSums, ignoreUngraded, weightingScheme) ->

      currentOrFinal = if ignoreUngraded then 'current' else 'final'
      groupSums = _(groupSums).map (gs) ->
        gs[currentOrFinal].weight = gs.group.group_weight
        gs[currentOrFinal]

      if weightingScheme == 'percent'
        relevantGroupSums = _(groupSums).filter (gs) -> gs.possible
        finalGrade = _.reduce relevantGroupSums
        , (grade,gs) ->
          grade + (gs.score / gs.possible) * gs.weight
        , 0
        fullWeight = _.reduce relevantGroupSums, ((w,{weight}) -> w + weight), 0
        if fullWeight == 0
          finalGrade = null
        else if fullWeight < 100
          finalGrade *= 100 / fullWeight

        submissionCount = _.reduce relevantGroupSums, (count, gs) ->
          count + gs.submission_count
        , 0
        possible = if submissionCount > 0 || !ignoreUngraded then 100 else 0
        score = finalGrade && round(finalGrade, round.DEFAULT)
        score = null if isNaN(score)
        ret = { score: score, possible: possible }
      else
        [score, possible] = _.reduce groupSums
        , ([m,n],{score,possible}) ->
          [m + score, n + possible]
        , [0,0]
        ret = {score, possible}

    @parse: (score) ->
      result = parseFloat score
      if result && isFinite(result) then result else 0

    @letter_grade: (grading_scheme, score) ->
      score = 0 if score < 0
      letters = _(grading_scheme).filter (row, i) ->
        # Ensure we're limiting the precision of the lower bound * 100 so we don't get float issues
        # e.g. 0.545 * 100 gives 54.50000000000001
        score >= (row[1] * 100).toPrecision(4) || i == (grading_scheme.length - 1)
      letter = letters[0]
      letter[0]
