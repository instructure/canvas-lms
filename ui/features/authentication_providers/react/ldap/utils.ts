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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  BindTestResponse,
  ConnectionTestResponse,
  LoginTestRequestParams,
  LoginTestResponse,
  SearchTestResponse,
} from './types'
import {MutationFunction, QueryFunction} from '@tanstack/react-query'

export const verifyConnection: QueryFunction<ConnectionTestResponse> = async ({queryKey}) => {
  const [, accountId] = queryKey
  const {json} = await doFetchApi<Array<ConnectionTestResponse>>({
    path: `/accounts/${accountId}/test_ldap_connections`,
    method: 'GET',
  })
  const [testResult] = json!

  return testResult
}

export const verifyBind: QueryFunction<BindTestResponse> = async ({queryKey}) => {
  const [, accountId] = queryKey
  const {json} = await doFetchApi<Array<BindTestResponse>>({
    path: `/accounts/${accountId}/test_ldap_binds`,
    method: 'GET',
  })

  const [testResult] = json!

  return testResult
}

export const verifySearch: QueryFunction<SearchTestResponse> = async ({queryKey}) => {
  const [, accountId] = queryKey
  const {json} = await doFetchApi<Array<SearchTestResponse>>({
    path: `/accounts/${accountId}/test_ldap_searches`,
    method: 'GET',
  })

  const [testResult] = json!

  return testResult
}

export const verifyLogin: MutationFunction<LoginTestResponse, LoginTestRequestParams> = async ({
  accountId,
  ...params
}) => {
  const {json} = await doFetchApi<Array<LoginTestResponse>>({
    path: `/accounts/${accountId}/test_ldap_logins`,
    method: 'POST',
    params,
  })

  const [testResult] = json!

  return testResult
}
