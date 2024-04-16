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

import {useState, useCallback} from 'react'
import {buildContextPath} from './buildContextPath'

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GradingSchemeSummary} from '../../gradingSchemeApiModel.d'
import {ApiCallStatus} from './ApiCallStatus'

export const useGradingSchemeSummaries = (): {
  loadGradingSchemeSummaries: (
    contextType: 'Account' | 'Course',
    contextId: string,
    assignmentId?: string | null
  ) => Promise<GradingSchemeSummary[]>
  loadGradingSchemeSummariesStatus: string
} => {
  const [loadGradingSchemeSummariesStatus, setLoadGradingSchemeSummariesStatus] = useState(
    ApiCallStatus.NOT_STARTED
  )

  const loadGradingSchemeSummaries = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      assignmentId = null
    ): Promise<GradingSchemeSummary[]> => {
      setLoadGradingSchemeSummariesStatus(ApiCallStatus.NOT_STARTED)

      const contextPath = buildContextPath(contextType, contextId)
      try {
        setLoadGradingSchemeSummariesStatus(ApiCallStatus.PENDING)

        // @ts-expect-error
        const result = await doFetchApi<GradingSchemeSummary[]>({
          path: `${contextPath}/grading_scheme_summaries${
            assignmentId ? `?assignment_id=${assignmentId}` : ''
          }`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        const gradingSchemeSummaries = result.json || []
        setLoadGradingSchemeSummariesStatus(ApiCallStatus.COMPLETED)
        return gradingSchemeSummaries
      } catch (err) {
        setLoadGradingSchemeSummariesStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    loadGradingSchemeSummaries,
    loadGradingSchemeSummariesStatus,
  }
}
