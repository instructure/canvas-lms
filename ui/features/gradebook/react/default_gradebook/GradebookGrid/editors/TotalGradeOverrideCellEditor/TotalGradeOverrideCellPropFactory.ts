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

export default class TotalGradeOverrideCellPropFactory {
  _gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this._gradebook = gradebook
  }

  getProps(editorOptions) {
    const {finalGradeOverrides} = this._gradebook
    const userId = editorOptions.item.id

    const grade = finalGradeOverrides?.getGradeForUser(userId)
    const pendingGradeInfo = finalGradeOverrides?.getPendingGradeInfoForUser(userId)

    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: this._gradebook.getCourseGradingScheme(),
    })

    return {
      gradeEntry,
      gradeInfo: gradeEntry.gradeInfoFromGrade(grade),
      gradeIsUpdating: pendingGradeInfo != null && pendingGradeInfo.valid,

      onGradeUpdate: gradeInfo => {
        finalGradeOverrides?.updateGrade(userId, gradeInfo)
      },

      pendingGradeInfo,
      studentIsGradeable: this._gradebook.studentCanReceiveGradeOverride(userId),
    }
  }
}
