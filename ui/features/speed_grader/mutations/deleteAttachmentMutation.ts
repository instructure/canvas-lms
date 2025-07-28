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
import doFetchApi from '@canvas/do-fetch-api-effect'

export const ZParams = z.object({
  attachmentId: z.string(),
})

type Params = z.infer<typeof ZParams>

export function deleteAttachment(params: Params): Promise<unknown> {
  ZParams.parse(params)
  return doFetchApi({
    path: `/api/v1/files/${params.attachmentId}?replace=1`,
    method: 'DELETE',
  })
}
