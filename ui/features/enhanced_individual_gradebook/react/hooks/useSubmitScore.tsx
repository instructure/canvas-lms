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

import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import {useCallback, useState} from 'react'

import {
  ApiCallStatus,
  type AssignmentConnection,
  type GradebookUserSubmissionDetails,
} from '../../types'
import {mapUnderscoreSubmission} from '../../utils/gradebookUtils'
import type {Submission} from '../../../../api.d'

const I18n = useI18nScope('enhanced_individual_gradebook_submit_score')

type SubmitScoreRequestBody = {
  originator?: string
  submission: {
    posted_grade?: string
    excuse?: boolean | string
  }
}

export const useSubmitScore = () => {
  const [submitScoreStatus, setSubmitScoreStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )
  const [submitScoreError, setSubmitScoreError] = useState<string>('')
  const [savedSubmission, setSavedSubmission] = useState<GradebookUserSubmissionDetails | null>(
    null
  )

  const submit = useCallback(
    async (
      assignment: AssignmentConnection,
      submission: GradebookUserSubmissionDetails,
      gradeInput: string,
      submitScoreUrl?: string | null
    ) => {
      if (!submitScoreUrl) {
        setSubmitScoreError(I18n.t('Unable to submit score'))
        setSubmitScoreStatus(ApiCallStatus.FAILED)
        return
      }
      const {gradingType} = assignment
      const delocalizedGrade = GradeFormatHelper.delocalizeGrade(gradeInput)
      const isExcusedText =
        gradeInput?.toUpperCase() === 'EXCUSED' || gradeInput?.toUpperCase() === 'EX'
      if (
        delocalizedGrade === submission.grade ||
        ((delocalizedGrade === '-' || delocalizedGrade === '') && submission.grade === null) ||
        (isExcusedText && submission.excused)
      ) {
        setSubmitScoreStatus(ApiCallStatus.NO_CHANGE)
        return
      }

      setSubmitScoreStatus(ApiCallStatus.PENDING)

      if ((!isExcusedText && gradingType === 'points') || gradingType === 'percent') {
        const formattedGrade = numberHelper.parse(delocalizedGrade?.replace(/%/g, '')).toString()

        if (formattedGrade === 'NaN') {
          setSubmitScoreError(I18n.t('Invalid Grade'))
          setSubmitScoreStatus(ApiCallStatus.FAILED)
          return
        }
      }

      const requestBody: SubmitScoreRequestBody = {
        originator: 'individual_gradebook',
        submission: {},
      }

      if (isExcusedText) {
        requestBody.submission.excuse = true
      } else {
        requestBody.submission.posted_grade = delocalizedGrade
      }

      try {
        const {data, status} = await executeApiRequest<Submission>({
          method: 'PUT',
          path: submitScoreUrl,
          body: requestBody,
        })
        if (status === 200) {
          setSavedSubmission(mapUnderscoreSubmission(data))
          setSubmitScoreStatus(ApiCallStatus.COMPLETED)
        } else {
          throw new Error()
        }
      } catch (error) {
        setSubmitScoreError(I18n.t('Something went wrong'))
        setSubmitScoreStatus(ApiCallStatus.FAILED)
      }
    },
    []
  )

  const submitExcused = useCallback(async (excused: boolean, submitScoreUrl?: string | null) => {
    if (!submitScoreUrl) {
      setSubmitScoreError(I18n.t('Unable to submit score'))
      setSubmitScoreStatus(ApiCallStatus.FAILED)
      return
    }

    const requestBody: SubmitScoreRequestBody = {
      submission: {
        excuse: excused.toString(),
      },
    }

    try {
      setSubmitScoreStatus(ApiCallStatus.PENDING)
      const {data, status} = await executeApiRequest<Submission>({
        method: 'PUT',
        path: submitScoreUrl,
        body: requestBody,
      })
      if (status === 200) {
        setSavedSubmission(mapUnderscoreSubmission(data))
        setSubmitScoreStatus(ApiCallStatus.COMPLETED)
      } else {
        throw new Error()
      }
    } catch (error) {
      setSubmitScoreError(I18n.t('Something went wrong'))
      setSubmitScoreStatus(ApiCallStatus.FAILED)
    }
  }, [])

  return {
    submitScoreError,
    submitScoreStatus,
    savedSubmission,
    submitExcused,
    submit,
  }
}
