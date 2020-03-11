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

import GradeOverrideEntry from '../../../../grading/GradeEntry/GradeOverrideEntry'

function renderStartContainer(gradeInfo) {
  let content = ''
  if (!gradeInfo.valid) {
    content += '<div class="Grid__GradeCell__InvalidGrade"><i class="icon-warning"></i></div>'
  }
  // xsslint safeString.identifier content
  return `<div class="Grid__GradeCell__StartContainer">${content}</div>`
}

function render(formattedGrade, gradeInfo) {
  // xsslint safeString.identifier formattedGrade
  // xsslint safeString.function renderStartContainer
  return `
    <div class="gradebook-cell">
      ${renderStartContainer(gradeInfo)}
      <div class="Grid__GradeCell__Content">
        <span class="Grade">${formattedGrade}</span>
      </div>
      <div class="Grid__GradeCell__EndContainer"></div>
    </div>
  `
}

export default class TotalGradeOverrideCellFormatter {
  constructor(gradebook) {
    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: gradebook.getCourseGradingScheme()
    })

    this.options = {
      getGradeInfoForUser(studentId) {
        const pendingGradeInfo = gradebook.finalGradeOverrides.getPendingGradeInfoForUser(studentId)
        if (pendingGradeInfo) {
          return pendingGradeInfo
        }

        const grade = gradebook.finalGradeOverrides.getGradeForUser(studentId)
        return gradeEntry.gradeInfoFromGrade(grade)
      },

      formatGradeInfo(gradeInfo) {
        return gradeEntry.formatGradeInfoForDisplay(gradeInfo)
      }
    }

    this.render = this.render.bind(this)
  }

  render(_row, _cell, _value, _columnDef, student /* dataContext */) {
    const gradeInfo = this.options.getGradeInfoForUser(student.id)
    const formattedGrade = this.options.formatGradeInfo(gradeInfo)
    return render(formattedGrade, gradeInfo)
  }
}
