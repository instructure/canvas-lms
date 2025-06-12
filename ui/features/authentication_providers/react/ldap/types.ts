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

export interface TestResultResponse {
  account_authorization_config_id: string
  errors: Array<{[key: string | number]: string}>
}

export interface ConnectionTestResponse extends TestResultResponse {
  ldap_connection_test: boolean
}

export interface BindTestResponse extends TestResultResponse {
  ldap_bind_test: boolean
}

export interface SearchTestResponse extends TestResultResponse {
  ldap_search_test: boolean
}

export interface LoginTestResponse extends TestResultResponse {
  ldap_login_test: boolean
}

export interface LoginTestRequestParams {
  accountId: string
  username: string
  password: string
}

export enum TestStatus {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCEED = 'succeed',
  FAILED = 'failed',
  CANCELED = 'canceled',
}

export type TroubleshootInfo = {
  title: string
  description: string
  hints: Array<string>
}
