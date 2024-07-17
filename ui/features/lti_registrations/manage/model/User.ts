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

import {z} from 'zod'

import {ZUserId} from './UserId'

export const ZUser = z.object({
  created_at: z.coerce.date(),
  id: ZUserId,
  integration_id: z.string().optional().nullable(),
  login_id: z.string().optional().nullable(),
  name: z.string(),
  short_name: z.string(),
  sis_import_id: z.string().optional().nullable(),
  sis_user_id: z.string().optional().nullable(),
  sortable_name: z.string(),
})
