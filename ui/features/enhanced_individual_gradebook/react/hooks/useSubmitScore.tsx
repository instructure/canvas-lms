/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import {useCallback, useState} from 'react'

import {ApiCallStatus, AssignmentConnection, GradebookUserSubmissionDetails} from '../../types'
import {mapUnderscoreSubmission} from '../../utils/gradebookUtils'
import {Submission} from '../../../../api.d'

const I18n = useI18nScope('enhanced_individual_gradebook_submit_score')

export const useSubmitScore = () => {
  const [submitScoreStatus, setSubmitScoreStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )
  const [submitScoreError, setSubmitScoreError] = useState<string>('')
  const [savedSubmission, setSavedSubmission] = useState<GradebookUserSubmissionDetails | null>(
    null
  )

  const gradeChangeUrl = ENV.GRADEBOOK_OPTIONS?.change_grade_url || ''

  const submit = useCallback(
    async (
      assignment: AssignmentConnection,
      submission: GradebookUserSubmissionDetails,
      gradeInput: string
    ) => {
      const {gradingType} = assignment
      const delocalizedGrade = GradeFormatHelper.delocalizeGrade(gradeInput)
      const url = gradeChangeUrl
        .replace(':assignment', assignment.id)
        .replace(':submission', submission.userId)

      if (
        delocalizedGrade === submission.grade ||
        ((delocalizedGrade === '-' || delocalizedGrade === '') && submission.grade === null)
      ) {
        setSubmitScoreStatus(ApiCallStatus.NO_CHANGE)
        return
      }

      setSubmitScoreStatus(ApiCallStatus.PENDING)

      if (gradingType === 'points' || gradingType === 'percent') {
        const formattedGrade = numberHelper.parse(delocalizedGrade?.replace(/%/g, '')).toString()

        if (formattedGrade === 'NaN') {
          setSubmitScoreError(I18n.t('Invalid Grade'))
          setSubmitScoreStatus(ApiCallStatus.FAILED)
          return
        }
      }

      const requestBody = {
        submission: {
          posted_grade: delocalizedGrade,
        },
      }

      const {data, status} = await axios.put<Submission>(url ?? '', requestBody)

      if (status === 200) {
        setSavedSubmission(mapUnderscoreSubmission(data))
        setSubmitScoreStatus(ApiCallStatus.COMPLETED)
      } else {
        setSubmitScoreError(I18n.t('Something went wrong'))
        setSubmitScoreStatus(ApiCallStatus.FAILED)
      }
    },
    [gradeChangeUrl]
  )

  return {
    submitScoreError,
    submitScoreStatus,
    savedSubmission,
    submit,
  }
}
