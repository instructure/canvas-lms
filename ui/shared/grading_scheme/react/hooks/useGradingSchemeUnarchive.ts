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
import {buildContextPath} from './buildContextPath'
import {ApiCallStatus} from './ApiCallStatus'

export const useGradingSchemeUnarchive = (): {
  unarchiveGradingScheme: (
    contextType: 'Account' | 'Course',
    contextId: string,
    gradingSchemeId: string
  ) => Promise<void>
  unarchiveGradingSchemeStatus: string
} => {
  const [unarchiveGradingSchemeStatus, setUnarchiveGradingSchemeStatus] = useState(
    ApiCallStatus.NOT_STARTED
  )

  const unarchiveGradingScheme = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      gradingSchemeId: string
    ): Promise<void> => {
      setUnarchiveGradingSchemeStatus(ApiCallStatus.NOT_STARTED)
      try {
        const contextPath = buildContextPath(contextType, contextId)
        setUnarchiveGradingSchemeStatus(ApiCallStatus.PENDING)

        const result = await doFetchApi({
          path: `${contextPath}/grading_schemes/${gradingSchemeId}/unarchive`,
          method: 'POST',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }

        setUnarchiveGradingSchemeStatus(ApiCallStatus.COMPLETED)
      } catch (err) {
        setUnarchiveGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    unarchiveGradingScheme,
    unarchiveGradingSchemeStatus,
  }
}
