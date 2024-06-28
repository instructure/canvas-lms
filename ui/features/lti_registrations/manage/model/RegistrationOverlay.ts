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
import {ZLtiPlacement} from './LtiPlacement'
import {ZLtiPrivacyLevel} from './LtiPrivacyLevel'
import {ZLtiScope} from './LtiScope'
import {ZLtiPlacementOverlay} from './PlacementOverlay'

export const ZRegistrationOverlay = z.object({
  title: z.string().optional().nullable(),
  disabledScopes: z.array(ZLtiScope).optional().nullable(),
  disabledSubs: z.array(z.string()).optional().nullable(),
  icon_url: z.string().optional().nullable(),
  launch_height: z.string().optional().nullable(),
  launch_width: z.string().optional().nullable(),
  disabledPlacements: z.array(ZLtiPlacement).optional().nullable(),
  placements: z.array(ZLtiPlacementOverlay).optional().nullable(),
  description: z.string().optional().nullable(),
  privacy_level: ZLtiPrivacyLevel.optional().nullable(),
})

export type RegistrationOverlay = z.infer<typeof ZRegistrationOverlay>
