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

const ZPageInfo = z.object({
  endCursor: z.string().nullable().optional(),
  hasNextPage: z.boolean().optional(),
  hasPreviousPage: z.boolean().optional(),
  startCursor: z.string().nullable().optional(),
})

export type PageInfo = z.infer<typeof ZPageInfo>

export const ZNextPageInfo = ZPageInfo.pick({
  endCursor: true,
  hasNextPage: true,
}).required()

export type NextPageInfo = z.infer<typeof ZNextPageInfo>

export const ZPreviousPageInfo = ZPageInfo.pick({
  hasPreviousPage: true,
  startCursor: true,
}).required()

export type PreviousPageInfo = z.infer<typeof ZPreviousPageInfo>
