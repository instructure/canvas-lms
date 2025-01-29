/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import type {AccountUsedLocation} from '@canvas/grading_scheme/gradingSchemeApiModel'

export const useGradingSchemeAccountUsedLocations = (): {
  getGradingSchemeAccountUsedLocations: (
    contextType: 'Account' | 'Course',
    contextId: string,
    gradingSchemeId: string,
  ) => Promise<{accountUsedLocations: AccountUsedLocation[]}>
  gradingSchemeAccountUsedLocationsStatus: string
} => {
  const [gradingSchemeAccountUsedLocationsStatus, setGradingSchemeAccountUsedLocationsStatus] =
    useState(ApiCallStatus.NOT_STARTED)

  const getGradingSchemeAccountUsedLocations = useCallback(
    async (
      contextType: 'Account' | 'Course',
      contextId: string,
      gradingSchemeId: string,
    ): Promise<{accountUsedLocations: AccountUsedLocation[]}> => {
      setGradingSchemeAccountUsedLocationsStatus(ApiCallStatus.PENDING)
      try {
        const contextPath = buildContextPath(contextType, contextId)
        const result = await doFetchApi({
          path: `${contextPath}/grading_schemes/${gradingSchemeId}/account_used_locations`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }

        setGradingSchemeAccountUsedLocationsStatus(ApiCallStatus.COMPLETED)
        return {
          // @ts-expect-error
          accountUsedLocations: result.json || [],
          isLastPage: result.link?.next === undefined,
          nextPage: result.link?.next?.url,
        }
      } catch (err) {
        setGradingSchemeAccountUsedLocationsStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    [],
  )

  return {
    getGradingSchemeAccountUsedLocations,
    gradingSchemeAccountUsedLocationsStatus,
  }
}
