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

import {escape as lodashEscape} from 'es-toolkit/compat'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import type Gradebook from '../../Gradebook'
import useStore from '../../stores'
import {gradeOverrideCustomStatus} from '../../FinalGradeOverrides/FinalGradeOverride.utils'

function renderStartContainer(gradeInfo: {valid: boolean}) {
  let content = ''
  if (!gradeInfo.valid) {
    content += '<div class="Grid__GradeCell__InvalidGrade"><i class="icon-warning"></i></div>'
  }
  // xsslint safeString.identifier content
  return `<div class="Grid__GradeCell__StartContainer">${content}</div>`
}

function render(
  formattedGrade: string,
  gradeInfo: {valid: boolean},
  studentId: string | null,
  selectedGradingPeriodId: string | null,
) {
  const escapedGrade = lodashEscape(formattedGrade)

  const {finalGradeOverrides} = useStore.getState()
  const customGradeStatusId = studentId != null
    ? gradeOverrideCustomStatus(finalGradeOverrides, studentId, selectedGradingPeriodId ?? undefined)
    : null
  const colorClass = customGradeStatusId ? `custom-grade-status-${customGradeStatusId}` : ''

  // xsslint safeString.identifier escapedGrade
  // xsslint safeString.function renderStartContainer
  return `
    <div class="gradebook-cell ${colorClass}">
      ${renderStartContainer(gradeInfo)}
      <div class="Grid__GradeCell__Content">
        <span class="Grade">${escapedGrade}</span>
      </div>
      <div class="Grid__GradeCell__EndContainer"></div>
    </div>
  `
}

type Getters = {
  getGradeInfoForUser(studentId: string): any
  formatGradeInfo(gradeInfo: any): string
  customGradeStatusesEnabled: boolean
  getSelectedGradingPeriodId(): string | null
}

export default class TotalGradeOverrideCellFormatter {
  options: Getters

  constructor(gradebook: Gradebook) {
    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: gradebook.getCourseGradingScheme(),
    })

    this.options = {
      getGradeInfoForUser(studentId: string) {
        const pendingGradeInfo =
          gradebook.finalGradeOverrides?.getPendingGradeInfoForUser(studentId)
        if (pendingGradeInfo) {
          return pendingGradeInfo
        }

        const grade = gradebook.finalGradeOverrides?.getGradeForUser(studentId)
        return gradeEntry.gradeInfoFromGrade(grade, false)
      },

      formatGradeInfo(gradeInfo) {
        return gradeEntry.formatGradeInfoForDisplay(gradeInfo)
      },
      customGradeStatusesEnabled: gradebook.options.custom_grade_statuses_enabled,
      getSelectedGradingPeriodId() {
        return gradebook.gradingPeriodId
      },
    }

    this.render = this.render.bind(this)
  }

  render(_row: unknown, _cell: unknown, _value: unknown, _columnDef: unknown, student: {id: string}) {
    const gradeInfo = this.options.getGradeInfoForUser(student.id)
    const formattedGrade = this.options.formatGradeInfo(gradeInfo)
    const studentId = this.options.customGradeStatusesEnabled ? student.id : null
    const selectedGradingPeriodId = this.options.getSelectedGradingPeriodId()
    return render(formattedGrade, gradeInfo, studentId, selectedGradingPeriodId)
  }
}
