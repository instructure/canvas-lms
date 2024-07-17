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
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZDeveloperKeyId} from './developer_key/DeveloperKeyId'
import {ZLtiRegistrationAccountBinding} from './LtiRegistrationAccountBinding'
import {ZUser} from './User'

export const ZLtiRegistration = z.object({
  id: ZLtiRegistrationId,
  account_id: ZAccountId,
  icon_url: z.string().optional().nullable(),
  name: z.string(),
  admin_nickname: z.string().optional().nullable(),
  workflow_state: z.string(),
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  created_by: ZUser.optional().nullable(),
  updated_by: ZUser.optional().nullable(),
  vendor: z.string().optional().nullable(),
  internal_service: z.boolean(),
  developer_key_id: ZDeveloperKeyId.optional().nullable(),
  ims_registration_id: z.string().optional().nullable(),
  manual_configuration_id: z.string().optional().nullable(),
  legacy_configuration_id: z.string().optional().nullable(),
  account_binding: ZLtiRegistrationAccountBinding.optional().nullable(),
})

export type LtiRegistration = z.infer<typeof ZLtiRegistration>
