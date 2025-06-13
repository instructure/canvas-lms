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

export const fetchContextSearch = (
  accountId: AccountId,
  searchTerm?: string,
  byAccountId?: AccountId,
): Promise<ApiResult<SearchableContexts>> =>
  parseFetchResult(ZSearchableContexts)(
    fetch(
      `/api/v1/accounts/${accountId}/lti_registrations/context_search?${toQueryString({
        search_term: searchTerm,
        by_account_id: byAccountId,
      })}`,
      {
        ...defaultFetchOptions(),
      },
    ),
  )
