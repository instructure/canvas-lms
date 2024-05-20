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

import type {DocumentNode} from 'graphql'
import request, {type Variables} from 'graphql-request'
import getCookie from '@instructure/get-cookie'

export interface QueryVariables extends Variables {
  [key: string]: unknown
}

export const executeQuery = async <QueryResponse>(
  query: DocumentNode,
  variables: QueryVariables
) => {
  return request<QueryResponse>('/api/graphql', query, variables, {
    'X-Requested-With': 'XMLHttpRequest',
    'GraphQL-Metrics': 'true',
    'X-CSRF-Token': getCookie('_csrf_token'),
  })
}
