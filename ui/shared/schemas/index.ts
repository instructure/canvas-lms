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

export const ZAccount = z
  .object({
    course_template_id: z.string().nullish(),
    default_group_storage_quota_mb: z.number(),
    default_storage_quota_mb: z.number(),
    default_time_zone: z.string(),
    default_user_storage_quota_mb: z.number(),
    id: z.string(),
    integration_id: z.string().nullish(),
    name: z.string(),
    parent_account_id: z.string().nullable(),
    root_account_id: z.string().nullable(),
    sis_account_id: z.string().nullish(),
    sis_import_id: z.string().nullish(),
    uuid: z.string(),
    workflow_state: z.string(),
  })
  .strict()

export type Account = z.infer<typeof ZAccount>

export const ZAccounts = z.array(ZAccount)

export type Accounts = z.infer<typeof ZAccounts>
