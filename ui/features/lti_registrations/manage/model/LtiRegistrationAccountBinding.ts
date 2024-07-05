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
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUserId} from './UserId'
import {ZAccountId} from './AccountId'
import {ZUser} from './User'

export const ZLtiRegistrationAccountBindingId = z.string().brand('LtiRegistrationAccountBindingId')
export type LtiRegistrationAccountBindingId = z.infer<typeof ZLtiRegistrationAccountBindingId>

export const ZLtiRegistrationAccountBinding = z.object({
  id: ZLtiRegistrationAccountBindingId,
  account_id: ZAccountId,
  registration_id: ZLtiRegistrationId,
  workflow_state: z.string(),
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  created_by: ZUser.optional().nullable(),
  updated_by: ZUser.optional().nullable(),
})

export type LtiRegistrationAccountBinding = z.infer<typeof ZLtiRegistrationAccountBinding>
