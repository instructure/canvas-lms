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
import * as z from 'zod'
import {ZDynamicRegistrationTokenUUID} from '../DynamicRegistrationTokenUUID'
import {ZInternalLtiConfiguration} from '../internal_lti_configuration/InternalLtiConfiguration'
import {ZLtiRegistrationId} from '../LtiRegistrationId'
import {ZLtiRegistrationUpdateRequestId} from './LtiRegistrationUpdateRequestId'
import {ZUser} from '../User'
import {ZAccountId} from '../AccountId'

export const ZLtiRegistrationUpdateRequest = z.object({
  id: ZLtiRegistrationUpdateRequestId,
  root_account_id: ZAccountId,
  uuid: ZDynamicRegistrationTokenUUID.optional().nullable(),
  lti_registration_id: ZLtiRegistrationId,
  internal_lti_configuration: ZInternalLtiConfiguration,
  created_by: z.union([z.string(), ZUser]).optional().nullable(),
  comment: z.string().optional().nullable(),
  status: z.enum(['applied', 'rejected', 'pending']).optional().nullable(),
})

export interface LtiRegistrationUpdateRequest
  extends z.infer<typeof ZLtiRegistrationUpdateRequest> {}
