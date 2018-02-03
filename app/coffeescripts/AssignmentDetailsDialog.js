import I18n from 'i18n!assignment_details'
import $ from 'jquery'
import assignmentDetailsDialogTemplate from 'jst/AssignmentDetailsDialog'
import round from './util/round'
import 'jqueryui/dialog'
import './jquery/fixDialogButtons'

export default class AssignmentDetailsDialog {
  static show (opts) {
    const dialog = new AssignmentDetailsDialog(opts)
    return dialog.show()
  }

  constructor ({assignment, students}) {
    this.compute = this.compute.bind(this)
    this.assignment = assignment
    this.students = students
  }

  show () {
    const {scores, locals} = this.compute()
    let tally = 0
    let width = 0
    const totalWidth = 100
    $.extend(locals, {
      showDistribution: locals.average && this.assignment.points_possible,
      noneLeftWidth: (width = totalWidth * (locals.min / this.assignment.points_possible)),
      noneLeftLeft: (tally += width) - width,
      someLeftWidth: (width = totalWidth * ((locals.average - locals.min) / this.assignment.points_possible)),
      someLeftLeft: (tally += width) - width,
      someRightWidth: (width = totalWidth * ((locals.max - locals.average) / this.assignment.points_possible)),
      someRightLeft: (tally += width) - width,
      noneRightWidth: (width = totalWidth * ((this.assignment.points_possible - locals.max) / this.assignment.points_possible)),
      noneRightLeft: (tally += width) - width,
    })

    return $(assignmentDetailsDialogTemplate(locals)).dialog({
      width: 500,
      close () { $(this).remove() }
    })
  }

  compute (opts = {students: this.students, assignment: this.assignment}) {
    const {students, assignment} = opts

    const scores = Object.values(students)
      .filter(student => student[`assignment_${assignment.id}`] && student[`assignment_${assignment.id}`].score != null)
      .map(student => student[`assignment_${assignment.id}`].score)

    const locals = {
      assignment,
      cnt: I18n.n(scores.length),
      max: this.nonNumericGuard(Math.max(...scores)),
      min: this.nonNumericGuard(Math.min(...scores)),
      pointsPossible: this.nonNumericGuard(assignment.points_possible, I18n.t('N/A')),
      average: this.nonNumericGuard(round(scores.reduce((a, b) => a + b, 0) / scores.length, 2))
    }

    return {scores, locals}
  }

  nonNumericGuard (number, message = I18n.t('No graded submissions')) {
    return (isFinite(number) && !isNaN(number)) ? I18n.n(number) : message
  }
}
