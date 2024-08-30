/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as z from 'zod'
import {ZLtiPrivacyLevel} from '../LtiPrivacyLevel'
import {ZLtiMessageType} from '../LtiMessageType'
import {ZLtiPlacement} from '../LtiPlacement'

export const ZLtiPlacementOverlay = z.object({
  text: z.string().optional(),
  target_link_uri: z.string().optional(),
  message_type: ZLtiMessageType.optional(),
  launch_height: z.string().optional(),
  launch_width: z.string().optional(),
})

export const ZLtiConfigurationOverlay = z.object({
  title: z.string().optional(),
  description: z.string().optional(),
  custom_fields: z.record(z.string()).optional(),
  target_link_uri: z.string().optional(),
  oidc_initiation_url: z.string().optional(),
  redirect_uris: z.array(z.string()).optional(),
  public_jwk: z.any().optional(),
  public_jwk_url: z.string().optional(),
  disabled_scopes: z.string().optional(),
  domain: z.string().optional(),
  privacy_level: ZLtiPrivacyLevel.optional(),
  disabled_placements: z.array(ZLtiPlacement).optional(),
  placements: z.array(ZLtiPlacement).optional(),
})
