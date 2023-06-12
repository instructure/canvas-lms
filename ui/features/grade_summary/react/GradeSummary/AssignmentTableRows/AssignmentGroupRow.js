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

import React from 'react'
import {ASSIGNMENT_NOT_APPLICABLE} from '../constants'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

import {
  getAssignmentGroupPercentage,
  formatNumber,
  scorePercentageToLetterGrade,
  getAssignmentGroupEarnedPoints,
  getAssignmentGroupTotalPoints,
  filteredAssignments,
} from '../utils'

export const assignmentGroupRow = (assignmentGroup, queryData) => {
  const assignmentGroupPercentage = getAssignmentGroupPercentage(
    assignmentGroup,
    filteredAssignments(queryData),
    false
  )

  const formattedScore =
    assignmentGroupPercentage === ASSIGNMENT_NOT_APPLICABLE
      ? assignmentGroupPercentage
      : `${formatNumber(assignmentGroupPercentage)}%`

  const letterGrade =
    assignmentGroupPercentage === ASSIGNMENT_NOT_APPLICABLE
      ? assignmentGroupPercentage
      : scorePercentageToLetterGrade(assignmentGroupPercentage, queryData?.gradingStandard)

  return (
    <Table.Row key={assignmentGroup?._id} data-testid={`agtotal-${assignmentGroup?.name}`}>
      <Table.Cell textAlign="start" colSpan="3">
        <Text weight="bold">{assignmentGroup?.name}</Text>
      </Table.Cell>
      {!ENV.restrict_quantitative_data && (
        <Table.Cell textAlign="center">
          <Text weight="bold">{formattedScore}</Text>
        </Table.Cell>
      )}
      <Table.Cell textAlign="center">
        <Text weight="bold">
          {ENV.restrict_quantitative_data
            ? letterGrade
            : `${
                formatNumber(
                  getAssignmentGroupEarnedPoints(assignmentGroup, filteredAssignments(queryData))
                ) || '-'
              }/${
                formatNumber(
                  getAssignmentGroupTotalPoints(assignmentGroup, filteredAssignments(queryData))
                ) || '-'
              }`}
        </Text>
      </Table.Cell>
    </Table.Row>
  )
}
