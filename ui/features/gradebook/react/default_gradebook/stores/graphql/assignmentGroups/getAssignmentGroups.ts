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
import {GET_ASSIGNMENT_GROUPS_QUERY} from './getAssignmentGroupsQuery'

const ZAssignmentGroupRules = z
  .object({
    dropHighest: z.number().nullable(),
    dropLowest: z.number().nullable(),
    neverDrop: z.array(z.object({_id: z.string()})).nullable(),
  })
  .strict()

const ZAssignmentGroup = z
  .object({
    _id: z.string(),
    name: z.string().nullable(),
    position: z.number().nullable(),
    groupWeight: z.number().nullable(),
    rules: ZAssignmentGroupRules.nullable(),
    sisId: z.string().nullable(),
  })
  .strict()
export type AssignmentGroup = z.infer<typeof ZAssignmentGroup>

const ZGetAssignmentGroupsResult = z
  .object({
    course: z.object({
      assignmentGroupsConnection: z.object({
        pageInfo: ZNextPageInfo,
        nodes: z.array(ZAssignmentGroup),
      }),
    }),
  })
  .strict()

export type GetAssignmentGroupsResult = z.infer<typeof ZGetAssignmentGroupsResult>

export type GetAssignmentGroupsParams = {
  courseId: string
  after?: string
}
export const getAssignmentGroups = async ({after, courseId}: GetAssignmentGroupsParams) => {
  const data = await executeQuery<GetAssignmentGroupsResult>(GET_ASSIGNMENT_GROUPS_QUERY, {
    courseId,
    after,
  })

  const validation = ZGetAssignmentGroupsResult.safeParse(data)
  if (!validation.success) {
    console.error('Validation failed:', validation.error.format())
  }
  return data
}
