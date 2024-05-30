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
import {ZAccountId} from '../AccountId'
import {ZDeveloperKeyId} from './DeveloperKeyId'
import {ZDeveloperKeyAccountBindingId} from './DeveloperKeyAccountBindingId'

export interface DeveloperKeyAccountBinding extends z.infer<typeof ZDeveloperKeyAccountBinding> {}

export const ZDeveloperKeyAccountBinding = z.object({
  account_id: ZAccountId,
  account_owns_binding: z.boolean(),
  developer_key_id: ZDeveloperKeyId,
  id: ZDeveloperKeyAccountBindingId,
  workflow_state: z.string(),
})
