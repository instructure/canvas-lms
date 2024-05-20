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

import doFetchApi from '@canvas/do-fetch-api-effect'
import type {GradingScheme, GradingSchemeUpdateRequest} from '../../gradingSchemeApiModel.d'
import {ApiCallStatus} from './ApiCallStatus'
import {buildContextPath} from './buildContextPath'

export const useGradingSchemeUpdate = (): {
  updateGradingScheme: (
    contextType: 'Account' | 'Course',
    contextId: string,
    gradingSchemeUpdateRequest: GradingSchemeUpdateRequest
  ) => Promise<GradingScheme>
  updateGradingSchemeStatus: string
} => {
  const [updateGradingSchemeStatus, setUpdateGradingSchemeStatus] = useState(
    ApiCallStatus.NOT_STARTED
  )

  const updateGradingScheme = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      gradingSchemeUpdateRequest: GradingSchemeUpdateRequest
    ): Promise<GradingScheme> => {
      setUpdateGradingSchemeStatus(ApiCallStatus.NOT_STARTED)

      const contextPath = buildContextPath(contextType, contextId)

      try {
        setUpdateGradingSchemeStatus(ApiCallStatus.PENDING)
        // @ts-expect-error
        const result = await doFetchApi<GradingScheme>({
          path: `${contextPath}/grading_schemes/${gradingSchemeUpdateRequest.id}`,
          method: 'PUT',
          body: gradingSchemeUpdateRequest,
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        setUpdateGradingSchemeStatus(ApiCallStatus.COMPLETED)
        return result.json
      } catch (err) {
        setUpdateGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )
  return {
    updateGradingScheme,
    updateGradingSchemeStatus,
  }
}
