/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {COURSE_QUERY, GROUP_QUERY} from '../graphql/Queries'

export const getContextQuery = contextType => {
  const contextQueryToUse = contextType === 'Course' ? COURSE_QUERY : GROUP_QUERY
  const contextQueryVariables =
    contextType === 'Course' ? {courseId: ENV.context_id} : {groupId: ENV.context_id}

  return {
    contextQueryToUse,
    contextQueryVariables,
  }
}

export const addNewGroupCategoryToCache = (cache, newCategory) => {
  const {contextQueryToUse, contextQueryVariables} = getContextQuery(
    ENV.context_is_not_group ? 'Course' : 'Group'
  )

  const data = cache.readQuery({
    query: contextQueryToUse,
    variables: contextQueryVariables,
  })

  const relevantGroupCategoryData = {
    _id: newCategory.id,
    name: newCategory.name,
    __typename: 'GroupSet',
  }

  if (data) {
    data.legacyNode.groupSetsConnection.nodes.push(relevantGroupCategoryData)
    cache.writeQuery({
      query: contextQueryToUse,
      variables: contextQueryVariables,
      data,
    })
  }
}
