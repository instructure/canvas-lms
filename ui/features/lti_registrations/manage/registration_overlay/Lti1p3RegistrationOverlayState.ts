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

import type {LtiScope} from '@canvas/lti/model/LtiScope'
import type {LtiMessageType} from '../model/LtiMessageType'
import type {LtiPlacement, LtiPlacementWithIcon} from '../model/LtiPlacement'
import type {LtiPrivacyLevel} from '../model/LtiPrivacyLevel'
import {PlacementLabelOverride, IconUrlOverride} from './Lti1p3RegistrationOverlayStore'

export type Lti1p3RegistrationOverlayState = {
  launchSettings: Partial<{
    redirectURIs: string
    targetLinkURI: string
    openIDConnectInitiationURL: string
    JwkMethod: 'public_jwk_url' | 'public_jwk'
    JwkURL: string
    Jwk: string
    domain: string
    customFields: string
  }>
  permissions: {
    scopes?: LtiScope[]
  }
  data_sharing: {
    privacy_level?: LtiPrivacyLevel
  }
  placements: {
    placements?: LtiPlacement[]
    courseNavigationDefaultDisabled?: boolean
  }
  override_uris: {
    placements: Partial<
      Record<
        LtiPlacement,
        {
          message_type?: LtiMessageType
          uri?: string
        }
      >
    >
  }
  naming: {
    nickname?: string
    description?: string
    notes?: string
    placements: Partial<Record<LtiPlacement, PlacementLabelOverride>>
  }
  icons: {
    placements: Partial<Record<LtiPlacementWithIcon, IconUrlOverride>>
  }
  dirty: boolean
  hasSubmitted: boolean
}
