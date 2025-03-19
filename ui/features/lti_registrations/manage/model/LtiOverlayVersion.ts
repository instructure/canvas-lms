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

import {z} from 'zod'
import {ZAccountId} from './AccountId'
import {ZUser} from './User'
import {ZLtiOverlayId} from './ZLtiOverlayId'

export const ZLtiOverlayVersionId = z.string().brand('ZLtiOverlayVersionId')

/**
 * @see The Lti::OverlayVersion Rails model and its associated serializer.
 */
export const ZLtiOverlayVersion = z.object({
  id: ZLtiOverlayVersionId,
  account_id: ZAccountId,
  root_account_id: ZAccountId,
  lti_overlay_id: ZLtiOverlayId,
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  // TODO: Refine this type to be a bit more specific. If we switch to storing
  // a copy instead of a diff, it can just be the regular overlay data type.
  diff: z.unknown(),
  caused_by_reset: z.boolean(),
  created_by: z.union([ZUser, z.literal('Instructure')]),
})

export type LtiOverlayVersion = z.infer<typeof ZLtiOverlayVersion>
