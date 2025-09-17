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
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUser} from './User'

export const ZLtiRegistrationHistoryEntryId = z.string().brand('ZLtiRegistrationHistoryEntryId')

/**
 * @see The Lti::RegistrationHistoryEntry Rails model and its associated serializer.
 */
export const ZLtiRegistrationHistoryEntry = z.object({
  id: ZLtiRegistrationHistoryEntryId,
  root_account_id: ZAccountId,
  lti_registration_id: ZLtiRegistrationId,
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  // TODO: Refine this type to be a bit more specific once we start
  // working on the new history view.
  diff: z.unknown(), // The diff object containing all changes
  update_type: z.string(),
  comment: z.string().nullable(),
  created_by: z.union([ZUser, z.literal('Instructure')]),
})

export type LtiRegistrationHistoryEntry = z.infer<typeof ZLtiRegistrationHistoryEntry>
