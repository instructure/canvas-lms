/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import assignmentDetailsDialogTemplate from '../jst/AssignmentDetailsDialog.handlebars'
import round from '@canvas/round'
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'

const I18n = useI18nScope('assignment_details')

export default class AssignmentDetailsDialog {
  static show(opts) {
    const dialog = new AssignmentDetailsDialog(opts)
    return dialog.show()
  }

  constructor({assignment, students}) {
    this.compute = this.compute.bind(this)
    this.assignment = assignment
    this.students = students
  }

  show() {
    const {locals} = this.compute()
    const totalWidth = 100

    const widthForValue = val => (totalWidth * val) / this.assignment.points_possible

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
      close() {
        $(this).remove()
      },
      modal: true,
      zIndex: 1000,
    })
  }

  compute(opts = {students: this.students, assignment: this.assignment}) {
    const {students, assignment} = opts

    const scores = Object.values(students)
      .filter(
        student =>
          student[`assignment_${assignment.id}`] &&
          student[`assignment_${assignment.id}`].score != null
      )
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

  nonNumericGuard(number, message = I18n.t('No graded submissions')) {
    return Number.isFinite(number) && !Number.isNaN(number) ? I18n.n(number) : message
  }

  percentile(values, percentile) {
    const k = Math.floor(percentile * (values.length - 1) + 1) - 1
    const f = (percentile * (values.length - 1) + 1) % 1

    return values[k] + f * (values[k + 1] - values[k])
  }
}
