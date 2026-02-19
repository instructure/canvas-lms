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
import {ZLtiMessageType, ZLtiPlacementlessMessageType} from '../LtiMessageType'
import {ZLtiDisplayType} from './LtiDisplayType'

export const ZMessageSetting = z.object({
  type: ZLtiPlacementlessMessageType,
  enabled: z.boolean(),
  target_link_uri: z.string().optional(),
  custom_fields: z.record(z.string()).optional(),
})

export type MessageSetting = z.infer<typeof ZMessageSetting>

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
  /**
   * A comma separated list of permissions that are required for the tool to be launched
   * from this placement.
   */
  required_permissions: z.string().optional(),
  // windowTarget should be z.literal('_blank'), but on the backend we allow it to
  // be a string for now. See commit 0e6186f8703e. To avoid throwing an error when
  // the user has given a "valid" configuration ("valid" according to the backend),
  // we can relax this schema as well, so that at least they can edit the app without
  // getting an error for having an invalid windowTarget value. This does not change
  // how the tool can be displayed. keyword: INTEROP-8921
  windowTarget: z.string().optional(),
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
  /**
   * This only applies to the top navigation placement. It allows the tool to be launched in fullscreen mode.
   */
  allow_fullscreen: z.boolean().optional(),
  accept_media_types: z.string().optional().nullable(),
  use_tray: z.boolean().optional().nullable(),

  message_settings: z.array(ZMessageSetting).optional(),
})

export interface InternalBaseLaunchSettings extends z.infer<typeof ZInternalBaseLaunchSettings> {}
