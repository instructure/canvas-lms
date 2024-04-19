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
import type {GradingScheme} from '../../gradingSchemeApiModel'
import {ApiCallStatus} from './ApiCallStatus'

export const useGradingScheme = (): {
  loadGradingScheme: (
    contextType: 'Account' | 'Course',
    contextId: string,
    gradingSchemeId: string,
    assignmentId?: string | null
  ) => Promise<GradingScheme>
  loadGradingSchemeStatus: string
} => {
  const [loadGradingSchemeStatus, setLoadGradingSchemeStatus] = useState(ApiCallStatus.NOT_STARTED)

  const loadGradingScheme = useCallback(
    async (
      contextType,
      contextId,
      gradingSchemeId,
      assignmentId = null
    ): Promise<GradingScheme> => {
      setLoadGradingSchemeStatus(ApiCallStatus.NOT_STARTED)

      const contextPath = buildContextPath(contextType, contextId)
      try {
        setLoadGradingSchemeStatus(ApiCallStatus.PENDING)

        // @ts-expect-error
        const result = await doFetchApi<GradingScheme>({
          path: `${contextPath}/grading_schemes/${gradingSchemeId}${
            assignmentId !== null ? '?assignment_id=' + assignmentId : ''
          }`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        setLoadGradingSchemeStatus(ApiCallStatus.COMPLETED)
        return result.json
      } catch (err) {
        setLoadGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    loadGradingScheme,
    loadGradingSchemeStatus,
  }
}
