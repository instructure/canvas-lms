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
import {nanoid} from 'nanoid'
import PropTypes from 'prop-types'

import {Table} from '@instructure/ui-table'

import {GradeSummaryContext} from './context'
import {getGradingPeriodID, sortAssignments, listDroppedAssignments} from './utils'

import {totalRow} from './AssignmentTableRows/TotalRow'
import {assignmentGroupRow} from './AssignmentTableRows/AssignmentGroupRow'
import {gradingPeriodRow} from './AssignmentTableRows/GradingPeriodRow'
import {assignmentRow} from './AssignmentTableRows/AssignmentRow'

const I18n = useI18nScope('grade_summary')

const headers = [
  {key: 'name', value: I18n.t('Name'), id: nanoid(), alignment: 'start', width: '30%'},
  {key: 'dueAt', value: I18n.t('Due Date'), id: nanoid(), alignment: 'start', width: '20%'},
  {key: 'status', value: I18n.t('Status'), id: nanoid(), alignment: 'center', width: '10%'},
  {key: 'score', value: I18n.t('Score'), id: nanoid(), alignment: 'center', width: '10%'},
]

const AssignmentTable = ({
  queryData,
  layout,
  setShowTray,
  setSelectedSubmission,
  handleReadStateChange,
}) => {
  const {assignmentSortBy} = React.useContext(GradeSummaryContext)
  const droppedAssignments = listDroppedAssignments(queryData, getGradingPeriodID() === '0')

  return (
    <Table caption={I18n.t('Student Grade Summary')} layout={layout} hover={true}>
      <Table.Head>
        <Table.Row>
          {(headers || []).map(header => (
            <Table.ColHeader
              key={header?.key}
              id={header?.id}
              textAlign={header?.alignment}
              width={header?.width}
            >
              {header?.value}
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {sortAssignments(assignmentSortBy, queryData?.assignmentsConnection?.nodes)?.map(
          assignment => {
            const modifiedAssignment = {
              ...assignment,
              dropped: droppedAssignments.includes(assignment),
            }

            return assignmentRow(
              modifiedAssignment,
              queryData,
              setShowTray,
              setSelectedSubmission,
              handleReadStateChange
            )
          }
        )}
        {getGradingPeriodID() !== '0'
          ? queryData?.assignmentGroupsConnection?.nodes?.map(assignmentGroup => {
              return assignmentGroupRow(assignmentGroup, queryData)
            })
          : queryData?.gradingPeriodsConnection?.nodes?.map(gradingPeriod => {
              return gradingPeriod.displayTotals ? gradingPeriodRow(gradingPeriod, queryData) : null
            })}
        {totalRow(queryData)}
      </Table.Body>
    </Table>
  )
}

AssignmentTable.propTypes = {
  queryData: PropTypes.object,
  layout: PropTypes.string,
  setShowTray: PropTypes.func,
  setSelectedSubmission: PropTypes.func,
  handleReadStateChange: PropTypes.func,
}

export default AssignmentTable
