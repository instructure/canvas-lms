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

import type {LtiScope} from '../LtiScopes'
import type {LtiRegistration} from '../LtiRegistration'
import type {Configuration} from './LtiToolConfiguration'

export interface DeveloperKeyAccountBinding {
  account_id: string
  account_owns_binding: boolean
  developer_key_id: string
  id: string
  workflow_state: string
}

export interface DeveloperKey {
  id: string
  access_token_count: number
  account_name: string
  allow_includes: boolean
  api_key: string
  created_at: string
  developer_key_account_binding?: DeveloperKeyAccountBinding
  scopes: Array<LtiScope>
  inherited_from?: string

  notes: string | null
  icon_url: string | null
  vendor_code: string | null
  redirect_uri: string | null
  redirect_uris?: string
  public_jwk_url?: string
  public_jwk?: string
  email: string | null
  name: string | null
  require_scopes: boolean | null
  tool_configuration: Configuration | null
  test_cluster_only?: boolean
  client_credentials_audience: string | null
  is_lti_key: boolean
  is_lti_registration: boolean
  lti_registration?: LtiRegistration
}
