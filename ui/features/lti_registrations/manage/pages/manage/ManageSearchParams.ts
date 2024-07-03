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

import type {ParsedSearchParamsValue} from '../../../common/lib/useZodParams/useZodSearchParams'
import {useZodSearchParams} from '../../../common/lib/useZodParams/useZodSearchParams'
import {z} from 'zod'

export const ZManageSearchParams = {
  q: z.string().optional(),
  sort: z
    .enum(['name', 'nickname', 'lti_version', 'installed', 'installed_by', 'updated_by', 'on'])
    .default('installed'),
  dir: z.enum(['asc', 'desc']).default('desc'),
  page: z.string().pipe(z.coerce.number()).default('1'),
}

export type ManageSearchParams = ParsedSearchParamsValue<typeof ZManageSearchParams>

export const useManageSearchParams = () => useZodSearchParams(ZManageSearchParams)
