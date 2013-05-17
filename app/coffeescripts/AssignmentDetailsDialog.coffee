define [
  'jquery'
  'jst/AssignmentDetailsDialog'
  'jqueryui/dialog'
  'compiled/jquery/fixDialogButtons'
], ($, assignmentDetailsDialogTemplate) ->

  class AssignmentDetailsDialog
    constructor: (@assignment, @gradebook) ->
      scores = (student["assignment_#{@assignment.id}"].score for own idx, student of @gradebook.students when student["assignment_#{@assignment.id}"]?.score?)
      locals =
        assignment: @assignment
        cnt: scores.length
        max: Math.max scores...
        min: Math.min scores...
        average: do (scores) ->
          total = 0
          total += score for score in scores
          Math.round(total / scores.length)

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
