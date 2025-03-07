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

export const ZLtiDisplayType = z.enum([
  'default',
  'full_width',
  'full_width_in_context',
  'full_width_with_nav',
  'in_nav_context',
  'borderless',
])

export type LtiDisplayType = z.infer<typeof ZLtiDisplayType>

export const isLtiDisplayType = (value: unknown): value is LtiDisplayType => {
  return ZLtiDisplayType.safeParse(value).success
}
