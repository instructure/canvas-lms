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
import {ZUserId} from './UserId'

export const ZTokenId = z.string().brand('TokenId')
export type TokenId = z.infer<typeof ZTokenId>

export const ZToken = z.object({
  id: ZTokenId,
  user_id: ZUserId,
  purpose: z.string(),
  created_at: z.string().datetime({offset: true}),
  updated_at: z.string().datetime({offset: true}),
  expires_at: z.string().datetime({offset: true}).nullable(),
  last_used_at: z.string().datetime({offset: true}).nullable(),
  scopes: z.array(z.string()),
  remember_access: z.boolean().nullable(),
  workflow_state: z.string(),
  real_user_id: ZUserId.nullable(),
  app_name: z.string(),
  visible_token: z.string(),
  can_manually_regenerate: z.boolean(),
})

export type Token = z.infer<typeof ZToken>
