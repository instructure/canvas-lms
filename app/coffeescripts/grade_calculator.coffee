define [
  'INST'
  'jquery'
  'jquery.instructure_misc_helpers'
], (INST, $) ->

  class GradeCalculator
    # each submission needs fields: score, points_possible, assignment_id, assignment_group_id
    #   to represent assignments that the student hasn't submitted, pass a
    #   submission with score == null
    #
    # each group needs fields: id, rules, group_weight
    #   rules is { drop_lowest: n, drop_highest: n, never_drop: [id...] }
    #
    # if weighting_scheme is "percent", group weights are used, otherwise no weighting is applied
    @calculate: (submissions, groups, weighting_scheme) ->
      result = {}
      # NOTE: purposely using $.map because it can handle array or object, old gradebook sends array
      # new gradebook sends object, needs jquery >1.6's version of $.map, since it can handle both
      result.group_sums = $.map groups, (group) =>
        group: group
        current: @create_group_sum(group, submissions, true)
        'final':   @create_group_sum(group, submissions, false)
      result.current  = @calculate_total(result.group_sums, true, weighting_scheme)
      result['final'] = @calculate_total(result.group_sums, false, weighting_scheme)
      result

    @create_group_sum: (group, submissions, ignore_ungraded) ->
      sum = { submissions: [], score: 0, possible: 0, submission_count: 0 }
      for assignment in group.assignments
        data = { score: 0, possible: 0, percent: 0, drop: false, submitted: false }
        submission = $.detect(submissions, -> this.assignment_id == assignment.id)
        submission ?= { score: null }
        submission.assignment_group_id = group.id
        submission.points_possible ?= assignment.points_possible
        data.submission = submission
        sum.submissions.push data
        unless ignore_ungraded and (!submission.score? || submission.score == '')
          data.score = @parse submission.score
          data.possible = @parse assignment.points_possible
          data.percent = @parse(data.score / data.possible)
          data.submitted = (submission.score? and submission.score != '')
          sum.submission_count += 1 if data.submitted

      # sort the submissions by assigned score
      sum.submissions.sort (a,b) -> a.percent - b.percent
      rules = $.extend({ drop_lowest: 0, drop_highest: 0, never_drop: [] }, group.rules)

      dropped = 0

      # drop the lowest and highest assignments
      for lowOrHigh in ['low', 'high']
        for data in sum.submissions
          if !data.drop and rules["drop_#{lowOrHigh}est"] > 0 and $.inArray(data.assignment_id, rules.never_drop) == -1 and data.possible > 0 and data.submitted
            data.drop = true
            # TODO: do I want to do this, it actually modifies the passed in submission object but it
            # it seems like the best way to tell it it should be dropped.
            data.submission?.drop = true
            rules["drop_#{lowOrHigh}est"] -= 1
            dropped += 1

      # if everything was dropped, un-drop the highest single submission
      if dropped > 0 and dropped == sum.submission_count
        sum.submissions[sum.submissions.length - 1].drop = false
        # see TODO above
        sum.submissions[sum.submissions.length - 1].submission?.drop = false
        dropped -= 1

      sum.submission_count -= dropped

      sum.score += s.score for s in sum.submissions when !s.drop
      sum.possible += s.possible for s in sum.submissions when !s.drop
      sum

    @calculate_total: (group_sums, ignore_ungraded, weighting_scheme) ->
      data_idx = if ignore_ungraded then 'current' else 'final'
      if weighting_scheme == 'percent'
        score = 0.0
        possible_weight_from_submissions = 0.0
        total_possible_weight = 0.0
        for data in group_sums when data.group.group_weight > 0
          if data[data_idx].submission_count > 0 and data[data_idx].possible > 0
            tally = data[data_idx].score / data[data_idx].possible
            score += data.group.group_weight * tally
            possible_weight_from_submissions += data.group.group_weight
          total_possible_weight += data.group.group_weight

        if ignore_ungraded and possible_weight_from_submissions < 100.0
          possible = if total_possible_weight < 100.0 then total_possible_weight else 100.0
          score = score * possible / possible_weight_from_submissions
        {
          score: score
          possible: 100.0
        }
      else
        {
          score: @sum(data[data_idx].score for data in group_sums)
          possible: @sum(data[data_idx].possible for data in group_sums)
        }

    @sum: (values) ->
      result = 0
      result += value for value in values
      result

    @parse: (score) ->
      result = parseFloat score
      if result && isFinite(result) then result else 0

    @letter_grade: (grading_scheme, score) ->
      score = 0 if score < 0
      letters = $.grep grading_scheme, (row, i) ->
        score >= row[1] * 100 || i == (grading_scheme.length - 1)
      letter = letters[0]
      letter[0]

  window.INST.GradeCalculator = GradeCalculator

