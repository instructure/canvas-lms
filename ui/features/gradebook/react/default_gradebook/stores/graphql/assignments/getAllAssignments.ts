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

import {GetAllPagesCallbacks, getAllPages, GetAllPagesReturnValue} from '../getAllPages'
import {flatten} from 'lodash'
import {
  Assignment,
  getAssignments,
  GetAssignmentsParams,
  GetAssignmentsResult,
} from './getAssignments'

type GetAllAssignmentsParams = {
  queryParams: Pick<GetAssignmentsParams, 'assignmentGroupId' | 'gradingPeriodId'>
} & GetAllPagesCallbacks<GetAssignmentsResult>

export const getAllAssignments = ({
  queryParams,
  ...params
}: GetAllAssignmentsParams): GetAllPagesReturnValue<Assignment[]> =>
  getAllPages({
    query: (after: string) => getAssignments({...queryParams, after}),
    getPageInfo: page => page.assignmentGroup.assignmentsConnection.pageInfo,
    flattenPages: pages =>
      flatten(pages.map(page => page.assignmentGroup.assignmentsConnection.nodes)),
    ...params,
  })
