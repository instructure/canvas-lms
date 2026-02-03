/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {doFetchWithSchema} from '@canvas/do-fetch-api-effect'
import {z} from 'zod'
import type {AccountId} from '../model/AccountId'

const ZDuplicateRegistration = z.object({
  id: z.string(),
  name: z.string(),
  admin_nickname: z.string().optional(),
})

const ZCheckDomainDuplicatesResponse = z.object({
  duplicates: z.array(ZDuplicateRegistration),
})

export type DuplicateRegistration = z.infer<typeof ZDuplicateRegistration>
export type CheckDomainDuplicatesResponse = z.infer<typeof ZCheckDomainDuplicatesResponse>

/**
 * React Query hook to check for duplicate domains in LTI registrations
 * @param accountId The account ID to check within
 * @param domain The domain to check for duplicates
 * @returns React Query result with duplicate registrations
 */
export const useDomainDuplicates = (accountId: AccountId, domain: string | undefined) => {
  return useQuery({
    queryKey: ['check_domain_duplicates', accountId, domain],
    queryFn: () =>
      doFetchWithSchema(
        {
          path: `/api/v1/accounts/${accountId}/lti_registrations/check_domain_duplicates`,
          params: {domain},
        },
        ZCheckDomainDuplicatesResponse,
      ),
    enabled: Boolean(domain && domain.trim()),
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}
