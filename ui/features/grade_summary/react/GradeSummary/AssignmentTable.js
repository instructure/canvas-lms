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

import {getGradingPeriodID} from './utils'

import {totalRow} from './AssignmentTableRows/TotalRow'
import {assignmentGroupRow} from './AssignmentTableRows/AssignmentGroupRow'
import {gradingPeriodRow} from './AssignmentTableRows/GradingPeriodRow'
import {assignmentRow} from './AssignmentTableRows/AssignmentRow'

const I18n = useI18nScope('grade_summary')

const headers = [
  {key: 'name', value: I18n.t('Name'), id: nanoid()},
  {key: 'dueAt', value: I18n.t('Due Date'), id: nanoid()},
  {key: 'status', value: I18n.t('Status'), id: nanoid()},
  {key: 'score', value: I18n.t('Score'), id: nanoid()},
]

const AssignmentTable = ({queryData, layout, setShowTray, setSelectedSubmission}) => {
  return (
    <Table caption={I18n.t('Student Grade Summary')} layout={layout}>
      <Table.Head>
        <Table.Row>
          {(headers || []).map(header => (
            <Table.ColHeader key={header?.key} id={header?.id}>
              {header?.value}
            </Table.ColHeader>
          ))}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {queryData?.assignmentsConnection?.nodes?.map(assignment => {
          return assignmentRow(assignment, queryData, setShowTray, setSelectedSubmission)
        })}
        {getGradingPeriodID() !== '0'
          ? queryData?.assignmentGroupsConnection?.nodes?.map(assignmentGroup => {
              return assignmentGroupRow(assignmentGroup, queryData)
            })
          : queryData?.gradingPeriodsConnection?.nodes?.map(gradingPeriod => {
              return gradingPeriodRow(gradingPeriod, queryData)
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
}

export default AssignmentTable
