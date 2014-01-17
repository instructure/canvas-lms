define [
  'i18n!assignment_details'
  'jquery'
  'jst/AssignmentDetailsDialog'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], (I18n, $, assignmentDetailsDialogTemplate) ->

  class AssignmentDetailsDialog
    constructor: ({@assignment, @students}) ->
      {scores, locals} = @compute()
      tally = 0
      width = 0
      totalWidth = 100
      $.extend locals,
        showDistribution: locals.average && @assignment.points_possible
        noneLeftWidth: width = totalWidth * (locals.min / @assignment.points_possible)
        noneLeftLeft: (tally += width) - width
        someLeftWidth: width = totalWidth * ((locals.average - locals.min) / @assignment.points_possible)
        someLeftLeft: (tally += width) - width
        someRightWidth: width = totalWidth * ((locals.max - locals.average) / @assignment.points_possible)
        someRightLeft: (tally += width) - width
        noneRightWidth: width = totalWidth * ((@assignment.points_possible - locals.max) / @assignment.points_possible)
        noneRightLeft: (tally += width) - width

      $(assignmentDetailsDialogTemplate(locals)).dialog
        width: 500
        close: -> $(this).remove()

    compute: (opts={
      students: @students
      assignment: @assignment
    })=>
      {students, assignment} = opts
      scores = (student["assignment_#{assignment.id}"].score for idx, student of students when student["assignment_#{assignment.id}"]?.score?)
      locals =
        assignment: assignment
        cnt: scores.length
        max: @nonNumericGuard Math.max scores...
        min: @nonNumericGuard Math.min scores...
        average: do (scores) =>
          total = 0
          total += score for score in scores
          @nonNumericGuard Math.round(total / scores.length)

      scores: scores
      locals: locals

    nonNumericGuard: (number) =>
      if isFinite(number) and not isNaN(number)
        number
      else
        I18n.t('no_graded_submissions', "No graded submissions")
