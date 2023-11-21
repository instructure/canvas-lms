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

import {LtiPlacement} from './LtiPlacements'

export interface LtiToolConfiguration {
  title: string
  scopes: string[]
  public_jwk_url?: string
  public_jwk?: string
  description: string | null
  custom_parameters: Record<string, string> | null
  target_link_uri: string
  oidc_initiation_url: string
  url: string
  extensions: Extension[]
}

export interface Extension {
  domain: string
  platform: string
  tool_id: string
  privacy_level: string
  settings: Settings
}

export interface Settings {
  text: string
  icon_url: any
  platform: string
  placements: PlacementConfig[]
}

export interface PlacementConfig {
  placement: LtiPlacement
  enabled: boolean
  message_type: string
  target_link_uri: string
  text: string
  icon_url: string
  custom_fields: Record<string, string>
}
