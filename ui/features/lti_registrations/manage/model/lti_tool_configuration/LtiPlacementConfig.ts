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
import {ZLtiPlacement} from '../LtiPlacement'

export interface LtiPlacementConfig extends z.infer<typeof ZPlacementConfig> {}

export const ZPlacementConfig = z.object({
  placement: ZLtiPlacement,
  enabled: z.boolean().optional(),
  message_type: z.string(),
  target_link_uri: z.string().optional(),
  text: z.string().optional(),
  icon_url: z.string().optional(),
  custom_fields: z.record(z.string()).optional(),
})
