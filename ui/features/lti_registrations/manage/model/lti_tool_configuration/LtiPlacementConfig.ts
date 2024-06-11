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
  enabled: z.boolean().optional().nullable(),
  message_type: z.string(),
  target_link_uri: z.string().optional().nullable(),
  text: z.string().optional().nullable(),
  icon_url: z.string().optional().nullable(),
  custom_fields: z.record(z.string()).optional().nullable(),
  /**
   * This supports a very old parameter (hence the obtuse name) that only applies to the course navigation placement. It hides the
   * tool from the course navigation by default. Teachers can still add the tool to the course navigation using the course
   * settings page if they'd like.
   * If this value is enabled, it will show the tool. If it's disabled, it will hide the tool.
   */
  default: z.enum(['disabled', 'enabled']).optional().nullable(),
})
