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

import axios from '@canvas/axios'
import {camelizeProperties} from '@canvas/convert-case'
import {useScope as useI18nScope} from '@canvas/i18n'
import {createClient, gql} from '@canvas/apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {FinalGradeOverrideMap} from './grading.d'

const I18n = useI18nScope('finalGradeOverrideApi')

export function getFinalGradeOverrides(
  courseId: string
): Promise<void | {finalGradeOverrides: FinalGradeOverrideMap}> {
  const url = `/courses/${courseId}/gradebook/final_grade_overrides`

  return axios
    .get<{final_grade_overrides: {[studentId: string]: any}}>(url)
    .then(response => {
      const data = {finalGradeOverrides: {}}

      for (const studentId in response.data.final_grade_overrides) {
        const responseOverrides = response.data.final_grade_overrides[studentId]
        const studentOverrides: {
          courseGrade?: {
            percentage: number | null
            schemeKey: string | null
          }
          gradingPeriodGrades?: {[gradingPeriodId: string]: string}
        } = (data.finalGradeOverrides[studentId] = {})

        if (responseOverrides.course_grade) {
          studentOverrides.courseGrade = camelizeProperties(responseOverrides.course_grade)
        }

        if (responseOverrides.grading_period_grades) {
          studentOverrides.gradingPeriodGrades = {}

          for (const gradingPeriodId in responseOverrides.grading_period_grades) {
            studentOverrides.gradingPeriodGrades[gradingPeriodId] = camelizeProperties(
              responseOverrides.grading_period_grades[gradingPeriodId]
            )
          }
        }
      }

      return data
    })
    .catch(_error => {
      showFlashAlert({
        message: I18n.t('There was a problem loading final grade overrides.'),
        type: 'error',
        err: null,
      })
    })
}

export function updateFinalGradeOverride(enrollmentId, gradingPeriodId, grade) {
  const gradingPeriodQuery = gradingPeriodId ? `gradingPeriodId: ${gradingPeriodId}` : ''

  const mutation = gql`
    mutation {
      setOverrideScore(input: {
        enrollmentId: ${enrollmentId}
        ${gradingPeriodQuery}
        overrideScore: ${grade && grade.percentage}
      }) {
        grades {
          overrideScore
        }
      }
    }
  `

  return createClient()
    .mutate({mutation})
    .then(response => {
      const {overrideScore} = response.data.setOverrideScore.grades
      return overrideScore != null ? {percentage: overrideScore} : null
    })
    .catch((/* error */) => {
      showFlashAlert({
        message: I18n.t('There was a problem overriding the grade.'),
        type: 'error',
        err: null,
      })
    })
}
