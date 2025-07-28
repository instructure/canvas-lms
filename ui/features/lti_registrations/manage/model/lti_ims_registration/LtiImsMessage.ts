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
import {ZLtiMessageType} from '../LtiMessageType'

export const ZLtiImsMessage = z.object({
  type: ZLtiMessageType,
  label: z.string().optional().nullable(),
  roles: z.array(z.string()).optional().nullable(),
  icon_uri: z.string().optional().nullable(),
  placements: z.array(z.string()).optional().nullable(),
  target_link_uri: z.string().optional().nullable(),
  custom_parameters: z.record(z.string()).optional().nullable(),
  'https://canvas.instructure.com/lti/course_navigation/default_enabled': z
    .boolean()
    .optional()
    .nullable(),
})

export type LtiImsMessage = z.infer<typeof ZLtiImsMessage>
