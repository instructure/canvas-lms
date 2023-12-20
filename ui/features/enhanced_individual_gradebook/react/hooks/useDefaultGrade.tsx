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

import {useCallback, useState} from 'react'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

import {ApiCallStatus, type SubmissionGradeChange} from '../../types'
import {mapToSubmissionGradeChange} from '../../utils/gradebookUtils'
import type {Submission} from '../../../../api'

export type DefaultGradeSubmissionParams = {
  submissions: {
    [key: string]: {
      assignment_id: string
      user_id: string
      set_by_default_grade: boolean
      late_policy_status?: string
      grade?: string
    }
  }
  dont_overwrite_grades: boolean
}

export type ApiResultType = {
  submission: Submission
}[]

export const useDefaultGrade = () => {
  const [defaultGradeStatus, setDefaultGradeStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )
  const [savedGrade, setSavedGrade] = useState<string>('')
  const [updatedSubmissions, setUpdatedSubmissions] = useState<SubmissionGradeChange[]>([])

  const resetDefaultGradeStatus = () => {
    setDefaultGradeStatus(ApiCallStatus.NOT_STARTED)
  }

  const setGrades = useCallback(
    async (
      contextUrl: string,
      gradeInput: string,
      submissionParams: DefaultGradeSubmissionParams
    ) => {
      setDefaultGradeStatus(ApiCallStatus.PENDING)
      setUpdatedSubmissions([])
      setSavedGrade('')

      try {
        const {status, data} = await executeApiRequest<ApiResultType>({
          path: `${contextUrl}/gradebook/update_submission`,
          body: submissionParams,
          method: 'POST',
        })

        if (status === 201) {
          setUpdatedSubmissions(data.map(({submission}) => mapToSubmissionGradeChange(submission)))
          setSavedGrade(gradeInput)
          setDefaultGradeStatus(ApiCallStatus.COMPLETED)
        } else {
          throw new Error()
        }
      } catch (err) {
        setDefaultGradeStatus(ApiCallStatus.FAILED)
      }
    },
    []
  )

  return {
    defaultGradeStatus,
    savedGrade,
    setGrades,
    resetDefaultGradeStatus,
    updatedSubmissions,
  }
}
