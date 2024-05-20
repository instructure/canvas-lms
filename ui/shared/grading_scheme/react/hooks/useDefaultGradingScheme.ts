/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import type {GradingScheme} from '../../gradingSchemeApiModel'
import {ApiCallStatus} from './ApiCallStatus'
import {buildContextPath} from './buildContextPath'

export const useDefaultGradingScheme = (): {
  loadDefaultGradingScheme: (
    contextType: 'Account' | 'Course',
    contextId: string
  ) => Promise<GradingScheme>
  loadDefaultGradingSchemeStatus: ApiCallStatus
} => {
  const [loadDefaultGradingSchemeStatus, setLoadDefaultGradingSchemeStatus] = useState(
    ApiCallStatus.NOT_STARTED
  )

  const loadDefaultGradingScheme = useCallback(
    async (contextType: 'Account' | 'Course', contextId: string): Promise<GradingScheme> => {
      setLoadDefaultGradingSchemeStatus(ApiCallStatus.NOT_STARTED)
      const contextPath = buildContextPath(contextType, contextId)
      try {
        setLoadDefaultGradingSchemeStatus(ApiCallStatus.PENDING)

        // @ts-expect-error
        const result = await doFetchApi<GradingScheme>({
          path: `${contextPath}/grading_schemes/default`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        const defaultGradingScheme: GradingScheme = result.json
        setLoadDefaultGradingSchemeStatus(ApiCallStatus.COMPLETED)
        return defaultGradingScheme
      } catch (err) {
        setLoadDefaultGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {loadDefaultGradingScheme, loadDefaultGradingSchemeStatus}
}
