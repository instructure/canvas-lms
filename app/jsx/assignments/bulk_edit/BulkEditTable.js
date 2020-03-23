/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_bulk_edit'
import React from 'react'
import {arrayOf, func} from 'prop-types'
import tz from 'timezone'
import {Table} from '@instructure/ui-table'
import {Responsive} from '@instructure/ui-layout'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {IconAssignmentLine, IconMiniArrowEndLine} from '@instructure/ui-icons'
import BulkDateInput from './BulkDateInput'
import {AssignmentShape} from './BulkAssignmentShape'

const DATE_INPUT_LABELS = {
  due_at: I18n.t('Due At'),
  unlock_at: I18n.t('Available From'),
  lock_at: I18n.t('Available Until')
}

BulkEditTable.propTypes = {
  assignments: arrayOf(AssignmentShape),

  // ({
  //   dateKey: one of null, "due_at", "lock_at", or "unlock_at"
  //   newDate: iso8601 date string
  //   assignmentId: assignment id string
  //
  //   overrideId: override id string, if this is an override.
  //   - or -
  //   base: true if this is the base assignment dates
  // }) => {...}
  updateAssignmentDate: func
}

export default function BulkEditTable({assignments, updateAssignmentDate}) {
  const createUpdateAssignmentFn = opts => newDate => {
    updateAssignmentDate({newDate, ...opts})
  }

  function renderDateInput(assignmentId, dateKey, dates, overrideId = null) {
    const label = DATE_INPUT_LABELS[dateKey]
    const handleSelectedDateChange = createUpdateAssignmentFn({
      dateKey,
      assignmentId,
      overrideId,
      base: overrideId === null
    })
    return (
      <BulkDateInput
        label={label}
        selectedDate={tz.parse(dates[dateKey])}
        onSelectedDateChange={handleSelectedDateChange}
      />
    )
  }

  function renderAssignments() {
    const rows = []
    assignments.forEach(assignment => {
      const baseDates = assignment.all_dates.find(dates => dates.base === true)
      const overrides = assignment.all_dates.filter(dates => !dates.base)
      rows.push(
        <Table.Row key={`assignment_${assignment.id}`}>
          <Table.Cell>
            <Tooltip renderTip={assignment.name}>
              <div className="ellipsis">
                <IconAssignmentLine /> {assignment.name}
              </div>
            </Tooltip>
          </Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'due_at', baseDates)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'unlock_at', baseDates)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'lock_at', baseDates)}</Table.Cell>
        </Table.Row>
      )
      rows.push(
        ...overrides.map(override => {
          return (
            <Table.Row key={`override_${override.id}`}>
              <Table.Cell>
                <View as="div" padding="0 0 0 medium">
                  <Tooltip renderTip={override.title}>
                    <div className="ellipsis">
                      <IconMiniArrowEndLine /> {override.title}
                    </div>
                  </Tooltip>
                </View>
              </Table.Cell>
              <Table.Cell>
                {renderDateInput(assignment.id, 'due_at', override, override.id)}
              </Table.Cell>
              <Table.Cell>
                {renderDateInput(assignment.id, 'unlock_at', override, override.id)}
              </Table.Cell>
              <Table.Cell>
                {renderDateInput(assignment.id, 'lock_at', override, override.id)}
              </Table.Cell>
            </Table.Row>
          )
        })
      )
    })
    return rows
  }

  const COLUMN_WIDTH_REMS = 14

  function renderTable(_props = {}, matches = []) {
    const widthProp = `${COLUMN_WIDTH_REMS}rem`
    const layoutProp = matches.includes('small') ? 'stacked' : 'fixed'
    return (
      <Table caption={I18n.t('Assignment Dates')} hover layout={layoutProp}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="title">{I18n.t('Title')}</Table.ColHeader>
            <Table.ColHeader width={widthProp} id="due">
              {DATE_INPUT_LABELS.due_at}
            </Table.ColHeader>
            <Table.ColHeader width={widthProp} id="unlock">
              {DATE_INPUT_LABELS.unlock_at}
            </Table.ColHeader>
            <Table.ColHeader width={widthProp} id="lock">
              {DATE_INPUT_LABELS.lock_at}
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>{renderAssignments()}</Table.Body>
      </Table>
    )
  }

  // For test environments that don't have matchMedia
  if (window.matchMedia) {
    return (
      <Responsive
        match="media"
        query={{small: {maxWidth: `${5 * COLUMN_WIDTH_REMS}rem`}}}
        render={renderTable}
      />
    )
  } else {
    return renderTable()
  }
}
