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
import {ZLtiRegistrationId} from './LtiRegistrationId'
import {ZLtiDeploymentId} from './LtiDeploymentId'
import {ZLtiContextControl} from './LtiContextControl'

export const ZLtiDeployment = z.object({
  id: ZLtiDeploymentId,
  registration_id: ZLtiRegistrationId,
  deployment_id: z.string(),
  context_id: z.string(),
  context_type: z.enum(['Course', 'Account']),
  context_name: z.string(),
  workflow_state: z.enum(['active', 'deleted']),
  context_controls: z.array(ZLtiContextControl),
})

export type LtiDeployment = z.infer<typeof ZLtiDeployment>
