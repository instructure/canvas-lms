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

import useStore from '../stores'

export default class FinalGradeOverrideDatastore {
  _gradesByUserId: {
    [userId: string]: {
      courseGrade?: string
      gradingPeriodGrades?: {[gradingPeriodId: string]: string}
    }
  }

  _pendingGrades: Array<{userId: string; gradingPeriodId: string | null; gradeInfo: any}>

  constructor() {
    this._gradesByUserId = {}
    this._pendingGrades = []
  }

  getGrade(userId: string, gradingPeriodId: string | null) {
    const gradeOverrides = this._gradesByUserId[userId]
    if (!gradeOverrides) {
      return null
    }

    if (gradingPeriodId) {
      return (gradeOverrides.gradingPeriodGrades || {})[gradingPeriodId] || null
    }

    return gradeOverrides.courseGrade || null
  }

  updateGrade(userId: string, gradingPeriodId: string | null, grade) {
    this._gradesByUserId[userId] = this._gradesByUserId[userId] || {}
    const gradeOverrides = this._gradesByUserId[userId]

    if (gradingPeriodId) {
      gradeOverrides.gradingPeriodGrades = gradeOverrides.gradingPeriodGrades || {}
      gradeOverrides.gradingPeriodGrades[gradingPeriodId] = grade
    } else {
      gradeOverrides.courseGrade = grade
    }

    const {finalGradeOverrides: existingFinalGradeOverrides} = useStore.getState()
    useStore.setState({
      finalGradeOverrides: {
        ...existingFinalGradeOverrides,
        [userId]: {...gradeOverrides},
      },
    })
  }

  setGrades(gradeOverrides) {
    this._gradesByUserId = gradeOverrides
  }

  addPendingGradeInfo(userId: string, gradingPeriodId: string | null, gradeInfo) {
    const pendingGradeInfo = {gradeInfo, userId, gradingPeriodId}
    this.removePendingGradeInfo(userId, gradingPeriodId)
    this._pendingGrades.push(pendingGradeInfo)
  }

  removePendingGradeInfo(userId: string, gradingPeriodId: string | null) {
    this._pendingGrades =
      this._pendingGrades.filter(
        gradeInfo => gradeInfo.userId !== userId || gradeInfo.gradingPeriodId !== gradingPeriodId
      ) || null
  }

  getPendingGradeInfo(userId: string, gradingPeriodId: string | null) {
    const datum = this._pendingGrades.find(
      gradeInfo => gradeInfo.userId === userId && gradeInfo.gradingPeriodId === gradingPeriodId
    )
    return datum ? datum.gradeInfo : null
  }
}
