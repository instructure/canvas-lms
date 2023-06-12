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
  formatNumber,
  scorePercentageToLetterGrade,
  getGradingPeriodTotalPoints,
  getGradingPeriodPercentage,
  getGradingPeriodEarnedPoints,
  filteredAssignments,
} from '../utils'

export const gradingPeriodRow = (gradingPeriod, queryData) => {
  const filterByGradingPeriod = filteredAssignments(queryData).filter(assignment => {
    return assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === gradingPeriod?._id
  })

  const periodPercentage = getGradingPeriodPercentage(
    gradingPeriod,
    filterByGradingPeriod,
    queryData?.assignmentGroupsConnection?.nodes,
    queryData?.applyGroupWeights
  )

  const letterGrade =
    periodPercentage === ASSIGNMENT_NOT_APPLICABLE
      ? periodPercentage
      : scorePercentageToLetterGrade(periodPercentage, queryData?.gradingStandard)

  const formattedScore = `${
    formatNumber(getGradingPeriodEarnedPoints(gradingPeriod, filterByGradingPeriod)) || '-'
  }/${formatNumber(getGradingPeriodTotalPoints(gradingPeriod, filterByGradingPeriod)) || '-'}`

  return (
    <Table.Row key={gradingPeriod._id}>
      <Table.Cell textAlign="start" colSpan="3">
        <Text weight="bold">{gradingPeriod.title}</Text>
      </Table.Cell>
      {!ENV.restrict_quantitative_data && (
        <Table.Cell textAlign="center">
          <Text weight="bold">
            {Number.isNaN(Number.parseFloat(periodPercentage)) ||
            periodPercentage === ASSIGNMENT_NOT_APPLICABLE
              ? ASSIGNMENT_NOT_APPLICABLE
              : `${formatNumber(periodPercentage)}%`}
          </Text>
        </Table.Cell>
      )}
      <Table.Cell textAlign="center">
        <Text weight="bold">{ENV.restrict_quantitative_data ? letterGrade : formattedScore}</Text>
      </Table.Cell>
    </Table.Row>
  )
}
