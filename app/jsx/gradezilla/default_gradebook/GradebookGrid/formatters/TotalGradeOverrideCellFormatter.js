/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import round from 'compiled/util/round'
import I18n from 'i18n!gradebook'
import {scoreToGrade} from '../../../../gradebook/GradingSchemeHelper'

// xsslint safeString.property schemeGrade
function render(options) {
  const percentage = options.percentage == null ? '–' : options.percentage
  let flexSpace = ''
  let schemeGrade = ''

  if (options.schemeGrade) {
    flexSpace = '<span class="flex-space"></span>'
    schemeGrade = `<span class="scheme-grade">${options.schemeGrade}</span>`
  }

  // xsslint safeString.identifier flexSpace percentage schemeGrade
  return `
    <div class="gradebook-cell">
      ${flexSpace}
      <span class="percentage-grade">
        ${percentage}
      </span>
      ${schemeGrade}
    </div>
  `
}

export default class TotalGradeOverrideCellFormatter {
  constructor(gradebook) {
    this.options = {
      getFinalGradeOverride(studentId) {
        return gradebook.finalGradeOverrides.getGradeForUser(studentId)
      },

      getCourseGradingScheme() {
        return gradebook.options.grading_standard
      }
    }

    this.render = this.render.bind(this)
  }

  render(_row, _cell, _value, _columnDef, student /* dataContext */) {
    const finalGradeOverride = this.options.getFinalGradeOverride(student.id)
    if (finalGradeOverride == null) {
      return render({schemeGrade: null, percentage: null})
    }

    const {percentage} = finalGradeOverride
    const gradingScheme = this.options.getCourseGradingScheme()
    const schemeGrade = gradingScheme ? scoreToGrade(percentage, gradingScheme) : null

    const options = {
      schemeGrade,
      percentage: I18n.n(round(percentage, round.DEFAULT), {percentage: true})
    }

    return render(options)
  }
}
