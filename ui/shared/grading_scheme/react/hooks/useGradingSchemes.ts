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

export const useGradingSchemes = (): {
  loadGradingSchemes: (
    contextType: 'Account' | 'Course',
    contextId: string,
    includeArchived?: boolean
  ) => Promise<GradingScheme[]>
  loadGradingSchemesStatus: string
} => {
  const [loadGradingSchemesStatus, setLoadGradingSchemesStatus] = useState(
    ApiCallStatus.NOT_STARTED
  )

  const loadGradingSchemes = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      includeArchived = false
    ): Promise<GradingScheme[]> => {
      setLoadGradingSchemesStatus(ApiCallStatus.NOT_STARTED)
      const contextPath = buildContextPath(contextType, contextId)
      try {
        setLoadGradingSchemesStatus(ApiCallStatus.PENDING)

        // @ts-expect-error
        const result = await doFetchApi<GradingScheme[]>({
          path: `${contextPath}/grading_schemes?include_archived=${includeArchived}`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        const gradingSchemes = result.json || []
        setLoadGradingSchemesStatus(ApiCallStatus.COMPLETED)
        return gradingSchemes
      } catch (err) {
        setLoadGradingSchemesStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    loadGradingSchemes,
    loadGradingSchemesStatus,
  }
}
