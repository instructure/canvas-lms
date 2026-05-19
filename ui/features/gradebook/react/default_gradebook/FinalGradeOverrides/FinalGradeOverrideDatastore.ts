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

import useStore from '../stores'
import type GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import type {FinalGradeOverride, FinalGradeOverrideMap} from '@canvas/grading/grading.d'

export default class FinalGradeOverrideDatastore {
  _gradesByUserId: FinalGradeOverrideMap

  _pendingGrades: Array<{
    userId: string
    gradingPeriodId: string | null
    gradeInfo: GradeOverrideInfo
  }>

  constructor() {
    this._gradesByUserId = {}
    this._pendingGrades = []
  }

  getGrade(
    userId: string,
    gradingPeriodId: string | null,
  ): FinalGradeOverride['courseGrade'] | null {
    const gradeOverrides = this._gradesByUserId[userId]
    if (!gradeOverrides) {
      return null
    }

    if (gradingPeriodId) {
      return (gradeOverrides.gradingPeriodGrades || {})[gradingPeriodId] || null
    }

    return gradeOverrides.courseGrade || null
  }

  updateGrade(
    userId: string,
    gradingPeriodId: string | null,
    grade: FinalGradeOverride['courseGrade'] | null,
  ) {
    this._gradesByUserId[userId] = this._gradesByUserId[userId] || {}
    const gradeOverrides = this._gradesByUserId[userId]

    if (gradingPeriodId) {
      gradeOverrides.gradingPeriodGrades = gradeOverrides.gradingPeriodGrades || {}
      if (grade != null) {
        gradeOverrides.gradingPeriodGrades[gradingPeriodId] = grade
      } else {
        delete gradeOverrides.gradingPeriodGrades[gradingPeriodId]
      }
    } else {
      gradeOverrides.courseGrade = grade ?? undefined
    }

    const {finalGradeOverrides: existingFinalGradeOverrides} = useStore.getState()
    useStore.setState({
      finalGradeOverrides: {
        ...existingFinalGradeOverrides,
        [userId]: {...gradeOverrides},
      },
    })
  }

  setGrades(gradeOverrides: FinalGradeOverrideMap) {
    this._gradesByUserId = gradeOverrides
  }

  addPendingGradeInfo(userId: string, gradingPeriodId: string | null, gradeInfo: GradeOverrideInfo) {
    const pendingGradeInfo = {gradeInfo, userId, gradingPeriodId}
    this.removePendingGradeInfo(userId, gradingPeriodId)
    this._pendingGrades.push(pendingGradeInfo)
  }

  removePendingGradeInfo(userId: string, gradingPeriodId: string | null) {
    this._pendingGrades = this._pendingGrades.filter(
      gradeInfo => gradeInfo.userId !== userId || gradeInfo.gradingPeriodId !== gradingPeriodId,
    )
  }

  getPendingGradeInfo(userId: string, gradingPeriodId: string | null): GradeOverrideInfo | null {
    const datum = this._pendingGrades.find(
      gradeInfo => gradeInfo.userId === userId && gradeInfo.gradingPeriodId === gradingPeriodId,
    )
    return datum ? datum.gradeInfo : null
  }
}
