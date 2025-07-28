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
import {ZNextPageInfo} from '../PaginatedResult'
import {executeQuery} from '@canvas/graphql'
import {GET_USERS_QUERY} from './getUsersQuery'

const ZUser = z
  .object({
    _id: z.string(),
    avatarUrl: z.string().nullable(),
    createdAt: z.string().nullable(),
    email: z.string().nullable(),
    firstName: z.string().nullable(),
    integrationId: z.string().nullable(),
    lastName: z.string().nullable(),
    loginId: z.string().nullable(),
    name: z.string().nullable(),
    shortName: z.string().nullable(),
    sisId: z.string().nullable(),
    sortableName: z.string().nullable(),
    groupMemberships: z.array(
      z
        .object({group: z.object({_id: z.string(), nonCollaborative: z.boolean()}).strict()})
        .strict(),
    ),
  })
  .strict()

export type User = z.infer<typeof ZUser>

export const ZGetUsersResult = z
  .object({
    course: z.object({
      usersConnection: z.object({
        pageInfo: ZNextPageInfo,
        nodes: z.array(ZUser),
      }),
    }),
  })
  .strict()

export type GetUsersResult = z.infer<typeof ZGetUsersResult>

export type GetUsersParams = {
  courseId: string
  userIds?: string[]
  after?: string
  first?: number
}
export const getUsers = async (queryParams: GetUsersParams) => {
  const data = await executeQuery<GetUsersResult>(GET_USERS_QUERY, queryParams)

  const validation = ZGetUsersResult.safeParse(data)
  if (!validation.success) {
    console.error('Validation failed:', validation.error.format())
  }
  return data
}
