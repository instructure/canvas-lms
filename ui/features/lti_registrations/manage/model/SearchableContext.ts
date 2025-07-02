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

import {z} from 'zod'
import {ZAccountId} from './AccountId'
import {ZCourseId} from './CourseId'

export const ZSearchableContexts = z.object({
  accounts: z.array(
    z.object({
      id: ZAccountId,
      name: z.string(),
      display_path: z.array(z.string()),
      sis_id: z.string().optional().nullable(),
    }),
  ),
  courses: z.array(
    z.object({
      id: ZCourseId,
      name: z.string(),
      display_path: z.array(z.string()),
      sis_id: z.string().optional().nullable(),
      course_code: z.string().optional().nullable(),
    }),
  ),
})

export type SearchableContexts = z.infer<typeof ZSearchableContexts>
