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
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZAccountId} from './AccountId'
import {ZUser} from './User'
import {ZCourseId} from './CourseId'

export type LtiContextControlId = z.infer<typeof ZLtiContextControlId>
export const ZLtiContextControlId = z.string().brand('LtiContextControlId')

export const ZLtiContextControl = z.object({
  id: ZLtiContextControlId,
  registration_id: ZLtiRegistrationId,
  deployment_id: z.string(),
  account_id: ZAccountId.nullable(),
  course_id: ZCourseId.nullable(),
  available: z.boolean(),
  path: z.string(),
  display_path: z.array(z.string()),
  context_name: z.string(),
  depth: z.number(),
  child_control_count: z.number(),
  course_count: z.number(),
  subaccount_count: z.number(),
  workflow_state: z.enum(['active', 'deleted']),
  created_at: z.coerce.date(),
  updated_at: z.coerce.date(),
  created_by: ZUser.nullable(),
  updated_by: ZUser.nullable(),
})

export type LtiContextControl = z.infer<typeof ZLtiContextControl>
