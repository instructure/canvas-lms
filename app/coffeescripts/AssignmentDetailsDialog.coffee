define [
  'i18n!assignment_details'
  'jquery'
  'jst/AssignmentDetailsDialog'
  'compiled/util/round'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], (I18n, $, assignmentDetailsDialogTemplate, round) ->

  class AssignmentDetailsDialog
    @show: (opts) ->
      dialog = new AssignmentDetailsDialog(opts)
      dialog.show()

    constructor: ({@assignment, @students}) ->

    show: () ->
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
        cnt: I18n.n scores.length
        max: @nonNumericGuard Math.max scores...
        min: @nonNumericGuard Math.min scores...
        pointsPossible: @nonNumericGuard assignment.points_possible, I18n.t('N/A')
        average: do (scores) =>
          total = 0
          total += score for score in scores
          @nonNumericGuard round((total / scores.length), 2)

      scores: scores
      locals: locals

    nonNumericGuard: (number, message = I18n.t("No graded submissions")) =>
      if isFinite(number) and not isNaN(number)
        I18n.n number
      else
        message
