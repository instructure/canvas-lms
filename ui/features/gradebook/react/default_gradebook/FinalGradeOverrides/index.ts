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

import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateFinalGradeOverride} from '@canvas/grading/FinalGradeOverrideApi'
import FinalGradeOverrideDatastore from './FinalGradeOverrideDatastore'
import type Gradebook from '../Gradebook'

const I18n = useI18nScope('gradebook')

export default class FinalGradeOverrides {
  _gradebook: Gradebook

  _datastore: FinalGradeOverrideDatastore

  constructor(gradebook: Gradebook) {
    this._gradebook = gradebook
    this._datastore = new FinalGradeOverrideDatastore()
  }

  getGradeForUser(userId) {
    let gradingPeriodId: null | string = null
    if (this._gradebook.isFilteringColumnsByGradingPeriod()) {
      gradingPeriodId = this._gradebook.gradingPeriodId
    }

    return this._datastore.getGrade(userId, gradingPeriodId)
  }

  getPendingGradeInfoForUser(userId: string) {
    let gradingPeriodId: null | string = null
    if (this._gradebook.isFilteringColumnsByGradingPeriod()) {
      gradingPeriodId = this._gradebook.gradingPeriodId
    }

    return this._datastore.getPendingGradeInfo(userId, gradingPeriodId)
  }

  setGrades(gradeOverrides) {
    this._datastore.setGrades(gradeOverrides)
    const studentIds = Object.keys(gradeOverrides)
    studentIds.forEach(userId => {
      this._gradebook.gradebookGrid?.updateRowCell(userId, 'total_grade_override')
    })
  }

  updateGrade(userId: string, gradeOverrideInfo) {
    const [enrollment] = this._gradebook.student(userId).enrollments

    let gradingPeriodId: null | string = null
    if (this._gradebook.isFilteringColumnsByGradingPeriod()) {
      gradingPeriodId = this._gradebook.gradingPeriodId
    }

    this._datastore.addPendingGradeInfo(userId, gradingPeriodId, gradeOverrideInfo)
    this._gradebook.gradebookGrid?.updateRowCell(userId, 'total_grade_override')

    if (gradeOverrideInfo.valid) {
      updateFinalGradeOverride(enrollment.id, gradingPeriodId, gradeOverrideInfo.grade)
        .then(grade => {
          this._datastore.removePendingGradeInfo(userId, gradingPeriodId)
          this._datastore.updateGrade(userId, gradingPeriodId, grade)
          this._gradebook.gradebookGrid?.updateRowCell(userId, 'total_grade_override')

          showFlashAlert({
            message: I18n.t('Grade saved.'),
            type: 'success',
            err: null,
          })
        })
        .catch((/* error */) => {
          showFlashAlert({
            message: I18n.t('There was a problem saving the grade.'),
            type: 'error',
            err: null,
          })
        })
    } else {
      showFlashAlert({
        message: I18n.t(
          'You have entered an invalid grade for this student. Check the value and the grading type and try again.'
        ),
        type: 'error',
        err: null,
      })
    }
  }
}
