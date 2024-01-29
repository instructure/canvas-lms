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
import type {GradingSchemeTemplate, GradingScheme} from '../../gradingSchemeApiModel'
import {ApiCallStatus} from './ApiCallStatus'
import {buildContextPath} from './buildContextPath'

export const useGradingSchemeCreate = (): {
  createGradingScheme: (
    contextType: 'Account' | 'Course',
    contextId: string,
    gradingSchemeTemplate: GradingSchemeTemplate
  ) => Promise<GradingScheme>
  createGradingSchemeStatus: ApiCallStatus
} => {
  const [createGradingSchemeStatus, setCreateGradingSchemeStatus] = useState<ApiCallStatus>(
    ApiCallStatus.NOT_STARTED
  )

  const createGradingScheme = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      gradingSchemeTemplate: GradingSchemeTemplate
    ): Promise<GradingScheme> => {
      setCreateGradingSchemeStatus(ApiCallStatus.NOT_STARTED)

      const contextPath = buildContextPath(contextType, contextId)

      try {
        setCreateGradingSchemeStatus(ApiCallStatus.PENDING)
        // @ts-expect-error
        const result = await doFetchApi<GradingScheme>({
          path: `${contextPath}/grading_schemes`,
          method: 'POST',
          body: gradingSchemeTemplate,
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        setCreateGradingSchemeStatus(ApiCallStatus.COMPLETED)
        return result.json
      } catch (err) {
        setCreateGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )
  return {
    createGradingScheme,
    createGradingSchemeStatus,
  }
}
