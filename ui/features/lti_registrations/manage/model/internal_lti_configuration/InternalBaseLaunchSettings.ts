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
import {ZLtiDisplayType} from './LtiDisplayType'

export const ZInternalBaseLaunchSettings = z.object({
  message_type: ZLtiMessageType.optional(),
  text: z.string().optional(),
  /**
   * A record of labels to be displayed in the platform settings.
   * The key is the key and the value is the label value.
   */
  labels: z.record(z.string()).optional(),
  custom_fields: z.record(z.string()).optional(),
  selection_height: z.number().optional(),
  selection_width: z.number().optional(),
  launch_height: z.number().optional(),
  launch_width: z.number().optional(),
  icon_url: z.string().optional(),
  canvas_icon_class: z.string().optional(),
  required_permissions: z.array(z.string()).optional(),
  windowTarget: z.literal('_blank').optional(),
  display_type: ZLtiDisplayType.optional(),
  url: z.string().optional(),
  target_link_uri: z.string().optional(),
  visibility: z.enum(['admins', 'members', 'public']).optional(),
  icon_svg_path_64: z.string().optional(),
  /**
   * This supports a very old parameter (hence the obtuse name) that only applies to the course navigation placement. It hides the
   * tool from the course navigation by default. Teachers can still add the tool to the course navigation using the course
   * settings page if they'd like.
   * If this value is enabled, it will show the tool. If it's disabled, it will hide the tool.
   */
  default: z.enum(['disabled', 'enabled']).optional(),
  accept_media_types: z.string().optional().nullable(),
  use_tray: z.boolean().optional().nullable(),
  eula: z
    .object({
      target_link_uri: z.string().optional(),
      custom_fields: z.record(z.string()).optional(),
    })
    .optional(),
})

export interface InternalBaseLaunchSettings extends z.infer<typeof ZInternalBaseLaunchSettings> {}
