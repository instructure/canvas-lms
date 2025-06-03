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

import {request} from 'graphql-request'
import getCookie from '@instructure/get-cookie'
import type {Variables} from 'graphql-request'
import type {TypedDocumentNode} from '@graphql-typed-document-node/core'

export const graphqlDefaults = {
  url: `${window.location.origin}/api/graphql`,
  requestHeaders: {
    'X-Requested-With': 'XMLHttpRequest',
    'GraphQL-Metrics': 'true',
    'X-CSRF-Token': String(getCookie('_csrf_token')),
  },
}

/**
 * Execute a GraphQL query
 * @template TResult
 * @template TVariables
 * @param query - The typed GraphQL query document
 * @param variables - The variables to pass to the query
 * @param customHeaders - Optional additional headers to include with the request
 * @returns A promise that resolves to the response
 */
export const executeQuery = async <TResult, TVariables extends Variables = Variables>(
  query: TypedDocumentNode<TResult, TVariables>,
  variables: TVariables,
  customHeaders?: Record<string, string>,
): Promise<TResult> => {
  const requestHeaders = customHeaders
    ? {...graphqlDefaults.requestHeaders, ...customHeaders}
    : graphqlDefaults.requestHeaders
  return request<TResult>(graphqlDefaults.url, query, variables, requestHeaders)
}
