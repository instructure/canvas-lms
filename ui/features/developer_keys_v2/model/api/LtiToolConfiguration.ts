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

import type {LtiPlacement} from '../LtiPlacements'
import type {LtiPrivacyLevel} from '../LtiPrivacyLevel'
import type {LtiScope} from '../LtiScopes'

/// @see lib/schemas/lti/tool_configuration.rb
export interface LtiToolConfiguration {
  id: string
  privacy_level: LtiPrivacyLevel
  developer_key_id: string
  disabled_placements: string[]
  settings: Configuration
  /// ISO8601 timestamp.
  created_at: string
  /// ISO8601 timestamp.
  updated_at: string
}

export interface Configuration {
  title: string
  description: string
  target_link_uri: string
  oidc_initiation_url: string
  custom_fields?: Record<string, string>
  oidc_initiation_urls?: Record<string, unknown>
  public_jwk_url?: string
  is_lti_key?: boolean
  icon_url?: string
  scopes?: LtiScope[]
  extensions?: Extension[]
}

export interface Extension {
  domain?: string
  platform: string
  /// This is *not* the actual meaningful id of any tool, but rather a tool provided value.
  tool_id?: string
  privacy_level?: LtiPrivacyLevel
  settings: PlatformSettings
}

export interface PlatformSettings {
  text: string
  icon_url: any
  platform?: string
  placements: PlacementConfig[]
}

export interface PlacementConfig {
  placement: LtiPlacement
  enabled?: boolean
  message_type: string
  target_link_uri?: string
  text?: string
  icon_url?: string
  custom_fields?: Record<string, string>
}

/// @see lib/schemas/lti/public_jwk.rb
export interface PublicJwk {
  kty: 'RSA'
  alg: 'RS256'
  e: string
  n: string
  kid: string
  use: string
}
