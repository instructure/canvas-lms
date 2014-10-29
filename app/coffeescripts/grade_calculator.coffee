define [
  'underscore'
], (_) ->

  partition = (list, f) ->
    trueList  = []
    falseList = []
    _(list).each (x) ->
      (if f(x) then trueList else falseList).push(x)
    [trueList, falseList]

  class GradeCalculator
    # each submission needs fields: score, points_possible, assignment_id, assignment_group_id
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
      arrayToObj = (arr, property) ->
        obj = {}
        for e in arr
          obj[e[property]] = e
        obj

      # remove assignments without visibility from gradeableAssignments
      hidden_assignment_ids = _.chain(submissions).
                                filter( (s)-> s.hidden).
                                map( (s)-> s.assignment_id).value()

      gradeableAssignments = _(group.assignments).filter (a) ->
        not _.isEqual(a.submission_types, ['not_graded']) and not _(hidden_assignment_ids).contains(a.id)
      assignments = arrayToObj gradeableAssignments, "id"

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

      submissionsByAssignment = arrayToObj submissions, "assignment_id"

      submissionData = _(submissions).map (s) =>
        sub =
          total: @parse assignments[s.assignment_id].points_possible
          score: @parse s.score
          submitted: s.score? and s.score != ''
          submission: s
      relevantSubmissionData = if ignoreUngraded
        _(submissionData).filter (s) -> s.submitted
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
    # (http://web.mit.edu/dankane/www/droplowest.pdf)
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

      # make sure we drop the same submission regardless of order
      submissions.sort (a, b) ->
        a.submission.assignment_id - b.submission.assignment_id

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
      sortedSubmissions = submissions.sort (a,b) -> a.score - b.score
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

      kept = keepHelper(submissions, keepHighest, ([a,xx], [b,yy]) -> b - a)
      kept = keepHelper(kept, keepLowest, ([a,xx], [b,yy]) -> a - b)

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
        ret =
          score: finalGrade && Math.round(finalGrade * 10) / 10
          possible: 100
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
        score >= row[1] * 100 || i == (grading_scheme.length - 1)
      letter = letters[0]
      letter[0]
