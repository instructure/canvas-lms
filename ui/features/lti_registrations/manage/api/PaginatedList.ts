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

/**
 * Given a schema for a single item,
 * returns a schema that will parse a
 * paginated list of those items.
 * @param itemSchema
 * @returns
 */
export const ZPaginatedList = <ZA extends z.ZodTypeAny>(itemSchema: ZA) =>
  z.object({
    data: z.array(itemSchema),
    total: z.number(),
  })

export type PaginatedList<A> = {
  data: A[]
  total: number
}
