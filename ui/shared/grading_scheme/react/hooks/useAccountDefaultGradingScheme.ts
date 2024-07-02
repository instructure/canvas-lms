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
import type {GradingScheme} from '../../gradingSchemeApiModel'
import {ApiCallStatus} from './ApiCallStatus'

export const useAccountDefaultGradingScheme = (): {
  loadAccountDefaultGradingScheme: (contextId: string) => Promise<GradingScheme | null>
  loadAccountDefaultGradingSchemeStatus: string
} => {
  const [loadAccountDefaultGradingSchemeStatus, setLoadAccountDefaultGradingSchemeStatus] =
    useState(ApiCallStatus.NOT_STARTED)

  const loadAccountDefaultGradingScheme = useCallback(
    async (contextId: string): Promise<GradingScheme | null> => {
      setLoadAccountDefaultGradingSchemeStatus(ApiCallStatus.NOT_STARTED)

      try {
        setLoadAccountDefaultGradingSchemeStatus(ApiCallStatus.PENDING)
        const result = await doFetchApi<GradingScheme>({
          path: `/accounts/${contextId}/grading_schemes/account_default`,
          method: 'GET',
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        setLoadAccountDefaultGradingSchemeStatus(ApiCallStatus.COMPLETED)
        return result.json || null
      } catch (err) {
        setLoadAccountDefaultGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    loadAccountDefaultGradingScheme,
    loadAccountDefaultGradingSchemeStatus,
  }
}
