/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {ZLtiPlacement} from './LtiPlacement'

export const ZLtiPlacementOverlay = z.object({
  type: ZLtiPlacement,
  icon_url: z.string().optional().nullable(),
  label: z.string().optional().nullable(),
  launch_height: z.string().optional().nullable(),
  launch_width: z.string().optional().nullable(),
  /**
   * See LtiPlacementConfig.default for more information on this obtuse parameter.
   */
  default: z.enum(['enabled', 'disabled']).optional().nullable(),
})

export type LtiPlacementOverlay = z.infer<typeof ZLtiPlacementOverlay>
