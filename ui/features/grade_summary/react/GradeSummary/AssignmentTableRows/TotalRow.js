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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

import {formatNumber, scorePercentageToLetterGrade, getTotal, filteredAssignments} from '../utils'

const I18n = useI18nScope('grade_summary')

export const totalRow = queryData => {
  const formattedTotal = formatNumber(
    getTotal(
      filteredAssignments(queryData),
      queryData?.assignmentGroupsConnection?.nodes,
      queryData?.gradingPeriodsConnection?.nodes,
      queryData?.applyGroupWeights
    )
  )
  return (
    <Table.Row>
      <Table.Cell textAlign="start" colSpan="3">
        <Text weight="bold">{I18n.t('Total')}</Text>
      </Table.Cell>
      <Table.Cell textAlign="start">
        <Text weight="bold">
          {ENV.restrict_quantitative_data
            ? scorePercentageToLetterGrade(formattedTotal, queryData?.gradingStandard)
            : `${formattedTotal}%`}
        </Text>
      </Table.Cell>
    </Table.Row>
  )
}
