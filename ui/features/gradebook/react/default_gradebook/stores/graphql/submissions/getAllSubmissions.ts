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
import {mapValues} from 'lodash'
import {
  getSubmissions,
  GetSubmissionsParams,
  GetSubmissionsResult,
  Submission,
} from './getSubmissions'
import {lettersToNumber} from '../buildGraphQLQuery'

// Gradebook does not respect anonymous assignments, and groups submissions by userId
// Thus we are not returning an array of submissions, but the userId is coming from the
// alias (the userId filter we sent with the query)

const flattenPages = (pages: GetSubmissionsResult[]): Submission[] => {
  const data: Submission[] = []
  pages.forEach(page => {
    Object.entries(page.course).forEach(([alias, course]) => {
      const userId = lettersToNumber(alias).toString()
      data.push(...course.nodes.map(node => ({...node, userId})))
    })
  })
  return data
}
type GetAllSubmissionsParams = {
  queryParams: Pick<GetSubmissionsParams, 'courseId' | 'userIds'>
} & GetAllPagesCallbacks<GetSubmissionsResult>
export const getAllSubmissions = ({
  queryParams,
  ...params
}: GetAllSubmissionsParams): GetAllPagesReturnValue<Submission[]> =>
  getAllPages({
    query: after => getSubmissions({...queryParams, after}),
    getPageInfo: page => mapValues(page.course, it => it.pageInfo),
    flattenPages,
    isMulti: true,
    ...params,
  })
