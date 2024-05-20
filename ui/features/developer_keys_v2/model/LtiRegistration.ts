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
import {type RegistrationOverlay} from '../react/RegistrationSettings/RegistrationOverlayState'
import {type LtiPlacement} from './LtiPlacements'
import {type LtiPrivacyLevel} from './LtiPrivacyLevel'
import {type LtiScope} from './LtiScopes'
import type {Configuration} from './api/LtiToolConfiguration'

export type SubClaims = Array<string>
export type MessageType = 'LtiResourceLinkRequest' | 'LtiDeepLinkingRequest'

export type LtiMessage = {
  type: MessageType
  label: string
  roles: Array<string>
  icon_uri: string
  placements?: Array<LtiPlacement>
  target_link_uri: string
  custom_parameters: Record<string, string>
}

export type LtiRegistration = {
  id: string
  lti_tool_configuration: {
    claims: SubClaims
    domain: string
    messages: Array<LtiMessage>
    target_link_uri: string
    'https://canvas.instructure.com/lti/privacy_level'?: LtiPrivacyLevel
  }
  developer_key_id: string
  overlay: null | RegistrationOverlay
  application_type: 'web'
  grant_types: Array<string>
  response_types: Array<string>
  redirect_uris: Array<string>
  initiate_login_uri: string
  client_name: string
  jwks_uri: string
  logo_uri: string | null
  token_endpoint_auth_method: string
  contacts: Array<string>
  client_uri: string | null
  policy_uri: string | null
  tos_uri: string | null
  scopes: Array<LtiScope>
  created_at: string
  updated_at: string
  guid: string
  /**
   * Tool configuration with overlay applied
   */
  tool_configuration: Configuration
  /**
   * The configuration without the overlay applied
   */
  default_configuration: Configuration
}
