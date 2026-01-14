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

import {getAllPages, GetAllPagesCallbacks, GetAllPagesReturnValue} from '../getAllPages'
import {flatten} from 'es-toolkit/compat'
import {
  AssignmentGroup,
  getAssignmentGroups,
  GetAssignmentGroupsParams,
  GetAssignmentGroupsResult,
} from './getAssignmentGroups'

type GetAllAssignmentGroupsParams = {
  queryParams: Pick<GetAssignmentGroupsParams, 'courseId'>
  headers?: Record<string, string>
} & GetAllPagesCallbacks<GetAssignmentGroupsResult>

export const getAllAssignmentGroups = ({
  queryParams,
  headers,
  ...params
}: GetAllAssignmentGroupsParams): GetAllPagesReturnValue<AssignmentGroup[]> =>
  getAllPages({
    query: (after: string) => getAssignmentGroups({...queryParams, after}, headers),
    getPageInfo: page => page.course.assignmentGroupsConnection.pageInfo,
    flattenPages: pages => flatten(pages.map(page => page.course.assignmentGroupsConnection.nodes)),
    ...params,
  })
