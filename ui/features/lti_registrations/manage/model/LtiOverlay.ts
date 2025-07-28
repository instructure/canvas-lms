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

import {z} from 'zod'
import {ZAccountId} from './AccountId'
import {ZLtiConfigurationOverlay} from './internal_lti_configuration/LtiConfigurationOverlay'
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUser} from './User'
import {ZLtiOverlayId} from './ZLtiOverlayId'
import {ZLtiOverlayVersion} from './LtiOverlayVersion'

export const ZLtiOverlay = z.object({
  id: ZLtiOverlayId,
  account_id: ZAccountId,
  registration_id: ZLtiRegistrationId,
  root_account_id: ZAccountId,
  data: ZLtiConfigurationOverlay,
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  updated_by: ZUser.nullable(),
})

export type LtiOverlay = z.infer<typeof ZLtiOverlay>

export const ZLtiOverlayWithVersions = ZLtiOverlay.extend({
  versions: z.array(ZLtiOverlayVersion),
})

export type LtiOverlayWithVersions = z.infer<typeof ZLtiOverlayWithVersions>
