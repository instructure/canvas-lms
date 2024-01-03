// @ts-nocheck
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

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import type Gradebook from '../../../Gradebook'
import {htmlDecode} from '../../../Gradebook.utils'
import useStore from '../../../stores'
import {gradeOverrideCustomStatus} from '../../../FinalGradeOverrides/FinalGradeOverride.utils'

export default class TotalGradeOverrideCellPropFactory {
  _gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this._gradebook = gradebook
  }

  getProps(editorOptions) {
    const {finalGradeOverrides} = this._gradebook
    const {item: student, activeRow} = editorOptions
    const userId = student.id

    const grade = finalGradeOverrides?.getGradeForUser(userId)
    const pendingGradeInfo = finalGradeOverrides?.getPendingGradeInfoForUser(userId)

    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: this._gradebook.getCourseGradingScheme(),
    })

    const gradeInfo = gradeEntry.gradeInfoFromGrade(grade, false)

    const totalRows = this._gradebook.gridData.rows.length
    const isFirstStudent = activeRow === 0
    const isLastStudent = activeRow === totalRows - 1
    const [enrollment] = student.enrollments
    const studentInfo = {
      id: userId,
      avatarUrl: htmlDecode(student.avatar_url),
      name: htmlDecode(student.name),
      gradesUrl: `${enrollment.grades.html_url}#tab-assignments`,
      enrollmentId: enrollment.id,
    }

    const {finalGradeOverrideTrayProps, finalGradeOverrides: finalGradeOverrideMap = {}} =
      useStore.getState()
    useStore.setState({
      finalGradeOverrideTrayProps: {
        ...finalGradeOverrideTrayProps,
        gradeEntry,
        isFirstStudent,
        isLastStudent,
        studentInfo,
      },
    })

    const selectedCustomStatusId = gradeOverrideCustomStatus(
      finalGradeOverrideMap,
      userId,
      this._gradebook.gradingPeriodId
    )
    const selectedCustomGradeStatus = this._gradebook.options.custom_grade_statuses?.find(
      status => status.id === selectedCustomStatusId
    )

    return {
      customGradeStatusesEnabled: this._gradebook.options.custom_grade_statuses_enabled,
      gradeEntry,
      gradeInfo,
      gradeIsUpdating: pendingGradeInfo != null && pendingGradeInfo.valid,

      onGradeUpdate: updatedGradeInfo => {
        finalGradeOverrides?.updateGrade(userId, updatedGradeInfo)
      },

      onTrayOpen: () => {
        this._gradebook.gradebookGrid?.gridSupport?.helper.commitCurrentEdit()
      },

      pendingGradeInfo,
      studentIsGradeable: this._gradebook.studentCanReceiveGradeOverride(userId),
      disabledByCustomStatus:
        this._gradebook.options.custom_grade_statuses_enabled &&
        selectedCustomGradeStatus?.allow_final_grade_value === false,
    }
  }
}
