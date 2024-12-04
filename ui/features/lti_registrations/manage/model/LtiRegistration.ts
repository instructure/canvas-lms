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
import {ZDeveloperKeyId} from './developer_key/DeveloperKeyId'
import {ZInternalLtiConfiguration} from './internal_lti_configuration/InternalLtiConfiguration'
import {ZLtiImsRegistrationId} from './lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from './lti_tool_configuration/LtiToolConfigurationId'
import {ZLtiOverlay} from './LtiOverlay'
import {ZLtiRegistrationAccountBinding} from './LtiRegistrationAccountBinding'
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZUser} from './User'

export const ZLtiRegistration = z.object({
  id: ZLtiRegistrationId,
  account_id: ZAccountId,
  icon_url: z.string().nullable(),
  name: z.string(),
  admin_nickname: z.string().nullable(),
  workflow_state: z.string(),
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  created_by: ZUser.optional(),
  updated_by: ZUser.optional(),
  vendor: z.string().nullable(),
  internal_service: z.boolean(),
  developer_key_id: ZDeveloperKeyId.nullable(),
  ims_registration_id: ZLtiImsRegistrationId.nullable(),
  manual_configuration_id: ZLtiToolConfigurationId.nullable(),
  account_binding: ZLtiRegistrationAccountBinding.nullable().optional(),
  overlay: ZLtiOverlay.nullable().optional(),
})

export type LtiRegistration = z.infer<typeof ZLtiRegistration>

export const ZLtiRegistrationWithConfiguration = ZLtiRegistration.extend({
  configuration: ZInternalLtiConfiguration,
})

export type LtiRegistrationWithConfiguration = z.infer<typeof ZLtiRegistrationWithConfiguration>
