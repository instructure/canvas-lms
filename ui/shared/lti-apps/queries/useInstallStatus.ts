/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useQuery} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {LtiRegistration} from '../models/LtiRegistration'

const getAccountId = () => window.location.pathname.split('/')[2]

const fetchInstallStatus = async (developerKeyId: string): Promise<LtiRegistration | null> => {
  const accountId = getAccountId()
  const url = `/api/v1/accounts/${accountId}/lti_registrations/install_status/${developerKeyId}`
  try {
    const result = await doFetchApi({
      method: 'GET',
      path: url,
    })
    return result.json as LtiRegistration
  } catch (error: any) {
    if (error?.response?.status === 404) {
      return null
    } else {
      throw error
    }
  }
}

const useInstallStatus = (developerKeyId?: string) =>
  useQuery({
    queryKey: ['lti_install_status', getAccountId(), developerKeyId],
    queryFn: ({queryKey: [_, __, developerKeyId]}) => {
      if (!developerKeyId) {
        // In tanner we trust that the developerKeyId will always be provided when enabled
        throw new Error('Developer key ID is required to fetch install status')
      }
      return fetchInstallStatus(developerKeyId)
    },
    enabled: !!developerKeyId && window.ENV.FEATURES.lti_registrations_templates,
  })

export default useInstallStatus
