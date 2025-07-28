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
import {ZLtiPlacement} from '../../LtiPlacement'
import {ZInternalBaseLaunchSettings} from '../InternalBaseLaunchSettings'

export const ZInternalPlacementConfiguration = ZInternalBaseLaunchSettings.merge(
  z.object({
    placement: ZLtiPlacement,
    // TODO: make this just a boolean along with INTEROP-8921
    enabled: z.union([z.literal('true'), z.literal('false'), z.boolean()]).optional(),
  }),
)

export interface InternalPlacementConfiguration
  extends z.infer<typeof ZInternalPlacementConfiguration> {}
