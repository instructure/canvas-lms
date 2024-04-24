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

import {COURSE_QUERY, GROUP_QUERY} from '../../graphql/Queries'
import {
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES,
  masteryPathsOption,
} from './constants'
import {nanoid} from 'nanoid'

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

const getAssetCode = (assetType, assetId) => {
  if (assetType === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.SECTION)
    return `course_section_${assetId}`
  if (assetType === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.GROUP) return `group_${assetId}`
  return masteryPathsOption.assetCode
}

const getAdhocAssetCode = studentOverride => `user_${studentOverride._id}`

const getAssignedList = override =>
  override.set.__typename === ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES.ADHOC
    ? override.set.students.map(getAdhocAssetCode)
    : [getAssetCode(override.set.__typename, override.set._id)]

export const buildDefaultAssignmentOverride = () => {
  return [
    {
      dueDateId: nanoid(),
      assignedList: [defaultEveryoneOption.assetCode],
      dueDate: '',
      availableFrom: '',
      availableUntil: '',
    },
  ]
}

export const buildAssignmentOverrides = assignment => {
  if (!assignment) return buildDefaultAssignmentOverride()

  const overrides =
    assignment?.assignmentOverrides?.nodes?.map(override => ({
      dueDateId: override.id,
      assignedList: getAssignedList(override),
      dueDate: override.dueAt,
      availableFrom: override.unlockAt,
      availableUntil: override.lockAt,
    })) || []

  // When this is true, then we do not have a everyone/everyone else option
  if (assignment.onlyVisibleToOverrides) return overrides

  overrides.push({
    dueDateId: nanoid(),
    assignedList:
      overrides.length > 0
        ? [defaultEveryoneElseOption.assetCode]
        : [defaultEveryoneOption.assetCode],
    dueDate: assignment.dueAt,
    availableFrom: assignment.unlockAt,
    availableUntil: assignment.lockAt,
  })

  return overrides.length > 0 ? overrides : buildDefaultAssignmentOverride()
}
