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

export const useAccountDefaultGradingSchemeUpdate = (): {
  updateAccountDefaultGradingScheme: (
    contextId: string,
    id: string | null
  ) => Promise<GradingScheme | null>
  updateAccountDefaultGradingSchemeStatus: string
} => {
  const [updateAccountDefaultGradingSchemeStatus, setUpdateAccountDefaultGradingSchemeStatus] =
    useState(ApiCallStatus.NOT_STARTED)

  const updateAccountDefaultGradingScheme = useCallback(
    async (contextId: string, id: string | null): Promise<GradingScheme | null> => {
      setUpdateAccountDefaultGradingSchemeStatus(ApiCallStatus.NOT_STARTED)

      try {
        setUpdateAccountDefaultGradingSchemeStatus(ApiCallStatus.PENDING)
        const result = await doFetchApi<GradingScheme>({
          path: `/accounts/${contextId}/grading_schemes/account_default`,
          method: 'PUT',
          body: {id},
        })
        if (!result.response.ok) {
          throw new Error(result.response.statusText)
        }
        setUpdateAccountDefaultGradingSchemeStatus(ApiCallStatus.COMPLETED)

        return result.json || null
      } catch (err) {
        setUpdateAccountDefaultGradingSchemeStatus(ApiCallStatus.FAILED)
        throw err
      }
    },
    []
  )

  return {
    updateAccountDefaultGradingScheme,
    updateAccountDefaultGradingSchemeStatus,
  }
}
