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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

import {formatNumber, scorePercentageToLetterGrade, getTotal, filteredAssignments} from '../utils'

const I18n = useI18nScope('grade_summary')

export const totalRow = (queryData, calculateOnlyGradedAssignments = false, courseLevelGrades) => {
  const applicableAssignments = filteredAssignments(queryData, calculateOnlyGradedAssignments)
  let total = getTotal(
    applicableAssignments,
    queryData?.assignmentGroupsConnection?.nodes,
    queryData?.gradingPeriodsConnection?.nodes,
    queryData?.applyGroupWeights
  )

  const courseLevelScore = courseLevelGrades?.score || 0
  const courseLevelPossible = courseLevelGrades?.possible || 0

  const percentageFromCourseLevelGrades = (courseLevelScore / courseLevelPossible) * 100

  if (total === ASSIGNMENT_NOT_APPLICABLE) {
    if (!calculateOnlyGradedAssignments || ENV.current_grading_period_id === '0') {
      total = 0
    }
  }
  const formattedTotal =
    total === ASSIGNMENT_NOT_APPLICABLE
      ? ASSIGNMENT_NOT_APPLICABLE
      : `${formatNumber(percentageFromCourseLevelGrades)}%`

  const letterGrade =
    total === ASSIGNMENT_NOT_APPLICABLE
      ? total
      : scorePercentageToLetterGrade(percentageFromCourseLevelGrades, queryData?.gradingStandard)

  const earnedPoints = formatNumber(courseLevelScore) || '-'
  const totalPoints = formatNumber(courseLevelPossible) || '-'
  const hasWeightedGradingPeriods = queryData?.gradingPeriodsConnection?.nodes?.some(
    gradingPeriod => {
      return gradingPeriod.weight != null && gradingPeriod.weight > 0
    }
  )

  return (
    <Table.Row data-testid="total_row">
      <Table.Cell textAlign="start" colSpan="3">
        <Text weight="bold">{I18n.t('Total')}</Text>
      </Table.Cell>
      <Table.Cell textAlign="center">
        <Text weight="bold">{ENV.restrict_quantitative_data ? letterGrade : formattedTotal}</Text>
      </Table.Cell>
      {!ENV.restrict_quantitative_data &&
        !hasWeightedGradingPeriods &&
        !queryData?.applyGroupWeights && (
          <Table.Cell textAlign="center">
            <Text weight="bold">{`${earnedPoints}/${totalPoints}`}</Text>
          </Table.Cell>
        )}
    </Table.Row>
  )
}
