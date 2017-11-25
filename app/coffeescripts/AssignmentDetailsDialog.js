import I18n from 'i18n!assignment_details'
import $ from 'jquery'
import assignmentDetailsDialogTemplate from 'jst/AssignmentDetailsDialog'
import round from 'compiled/util/round'
import 'jqueryui/dialog'
import 'compiled/jquery/fixDialogButtons'

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
    const totalWidth = 100

    const widthForValue = val => (totalWidth * val / this.assignment.points_possible);
    
    $.extend(locals, {
      showDistribution: locals.average && this.assignment.points_possible,
      
      lowLeft: widthForValue(locals.min),
      lqLeft: widthForValue(locals.lowerQuartile),
      medianLeft: widthForValue(locals.median),
      uqLeft: widthForValue(locals.upperQuartile),
      highLeft: widthForValue(locals.max),
      maxLeft: totalWidth,
  
      highWidth: widthForValue(locals.max - locals.upperQuartile),
      lowLqWidth: widthForValue(locals.lowerQuartile - locals.min),
      medianLowWidth: widthForValue(locals.median - locals.lowerQuartile) + 1,
      medianHighWidth: widthForValue(locals.upperQuartile - locals.median),
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
      .sort()

    const locals = {
      assignment,
      cnt: I18n.n(scores.length),
      max: this.nonNumericGuard(Math.max(...scores)),
      min: this.nonNumericGuard(Math.min(...scores)),
      pointsPossible: this.nonNumericGuard(assignment.points_possible, I18n.t('N/A')),
      average: this.nonNumericGuard(round(scores.reduce((a, b) => a + b, 0) / scores.length, 2)),
      median: this.nonNumericGuard(this.percentile(scores, 0.5)),
      lowerQuartile: this.nonNumericGuard(this.percentile(scores, 0.25)),
      upperQuartile: this.nonNumericGuard(this.percentile(scores, 0.75)),
    }

    return {scores, locals}
  }
  
  percentile (values, percentile) {
    const k = Math.floor(percentile*(values.length - 1)+1)- 1
    const f = (percentile*(values.length - 1)+1) % 1

    return values[k] + (f * (values[k+1] - values[k]))
  }

  nonNumericGuard (number, message = I18n.t('No graded submissions')) {
    return (isFinite(number) && !isNaN(number)) ? I18n.n(number) : message
  }
}
