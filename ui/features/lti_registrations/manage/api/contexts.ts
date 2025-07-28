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

import {ApiResult, parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import {AccountId} from '../model/AccountId'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {ZSearchableContexts, SearchableContexts} from '../model/SearchableContext'
import {toQueryString} from '@instructure/query-string-encoding'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import {LtiDeploymentId} from '../model/LtiDeploymentId'

/**
 * Search for accounts and courses, including sub-accounts and sub-courses, that match the given search term.
 * Results are limited to contexts that are descendants of the context for which the supplied deployment is for.
 *
 * @param accountId Root account ID to search under
 * @param registrationId LTI registration ID of the LTI deployment to search under
 * @param deploymentId
 * @param searchTerm
 * @param onlyChildrenOf limit results to contexts that are children of this account ID
 * @returns
 */
export const fetchContextSearch = (
  accountId: AccountId,
  registrationId: LtiRegistrationId,
  deploymentId: LtiDeploymentId,
  searchTerm?: string,
  onlyChildrenOf?: AccountId,
): Promise<ApiResult<SearchableContexts>> => {
  return parseFetchResult(ZSearchableContexts)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/deployments/${deploymentId}/context_search?${toQueryString(
        {
          search_term: searchTerm,
          ...(onlyChildrenOf !== undefined ? {only_children_of: onlyChildrenOf} : {}),
        },
      )}`,
      {
        ...defaultFetchOptions(),
      },
    ),
  )
}
