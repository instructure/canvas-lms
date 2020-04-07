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
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {IconWarningLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import BulkDateInput from './BulkDateInput'
import {AssignmentShape} from './BulkAssignmentShape'

const DATE_INPUT_META = {
  due_at: {
    label: I18n.t('Due At'),
    fancyMidnight: true
  },
  unlock_at: {
    label: I18n.t('Available From'),
    fancyMidnight: false
  },
  lock_at: {
    label: I18n.t('Available Until'),
    fancyMidnight: true
  }
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
  const DATE_COLUMN_WIDTH_REMS = 14
  const NOTE_COLUMN_WIDTH_REMS = 3

  const createUpdateAssignmentFn = opts => newDate => {
    updateAssignmentDate({newDate, ...opts})
  }

  function renderDateInput(assignmentId, dateKey, dates, overrideId = null) {
    const label = DATE_INPUT_META[dateKey].label
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
        fancyMidnight={DATE_INPUT_META[dateKey].fancyMidnight}
        interaction={dates.can_edit ? 'enabled' : 'disabled'}
      />
    )
  }

  function renderAssignmentTitle(assignment) {
    return (
      <Tooltip renderTip={assignment.name}>
        <Text as="div" size="large">
          <div className="ellipsis">{assignment.name}</div>
        </Text>
      </Tooltip>
    )
  }

  function renderNoDefaultDates() {
    // The goal here is to create a cell that spans multiple columns. You can't do that with InstUI
    // yet, so we're going to fake it with a View that's as wide as the three date columns and
    // depend on the cell overflow as being visible. I think that's pretty safe since that's the
    // default overflow.
    return (
      <View as="div" minWidth={`${DATE_COLUMN_WIDTH_REMS * 3 + NOTE_COLUMN_WIDTH_REMS}rem`}>
        <Text size="medium" fontStyle="italic">
          {I18n.t('This assignment has no default dates.')}
        </Text>
      </View>
    )
  }

  function renderNote(assignment, dateSet) {
    if (!dateSet.can_edit) {
      let explanation
      if (dateSet.in_closed_grading_period) {
        explanation = I18n.t('In closed grading period')
      } else if (assignment.moderated_grading) {
        explanation = I18n.t('Only the moderator can edit this assignment')
      } else {
        explanation = I18n.t('You do not have permission to edit this assignment')
      }
      return (
        <Tooltip renderTip={explanation}>
          <IconWarningLine color="warning" title={explanation} />
        </Tooltip>
      )
    } else {
      return null
    }
  }

  function renderBaseRow(assignment) {
    const baseDates = assignment.all_dates.find(dates => dates.base === true)
    // It's a bit repetitive this way, but Table.Row borks if it has anything but Table.Cell children.
    if (baseDates) {
      return (
        <Table.Row key={`assignment_${assignment.id}`}>
          <Table.Cell>{renderAssignmentTitle(assignment)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'due_at', baseDates)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'unlock_at', baseDates)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'lock_at', baseDates)}</Table.Cell>
          <Table.Cell>{renderNote(assignment, baseDates)}</Table.Cell>
        </Table.Row>
      )
    } else {
      // Need all 4 Table.Cells or you get weird borders on this row
      return (
        <Table.Row key={`assignment_${assignment.id}`}>
          <Table.Cell>{renderAssignmentTitle(assignment)}</Table.Cell>
          <Table.Cell>{renderNoDefaultDates()}</Table.Cell>
          <Table.Cell />
          <Table.Cell />
          <Table.Cell />
        </Table.Row>
      )
    }
  }

  function renderOverrideRows(assignment) {
    const overrides = assignment.all_dates.filter(dates => !dates.base)
    return overrides.map(override => {
      return (
        <Table.Row key={`override_${override.id}`}>
          <Table.Cell>
            <View as="div" padding="0 0 0 xx-large">
              <Tooltip renderTip={override.title}>
                <Text as="div" size="medium">
                  <div className="ellipsis">{override.title}</div>
                </Text>
              </Tooltip>
            </View>
          </Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'due_at', override, override.id)}</Table.Cell>
          <Table.Cell>
            {renderDateInput(assignment.id, 'unlock_at', override, override.id)}
          </Table.Cell>
          <Table.Cell>
            {renderDateInput(assignment.id, 'lock_at', override, override.id)}
          </Table.Cell>
          <Table.Cell>{renderNote(assignment, override)}</Table.Cell>
        </Table.Row>
      )
    })
  }

  function renderAssignments() {
    const rows = []
    assignments.forEach(assignment => {
      rows.push(renderBaseRow(assignment))
      rows.push(...renderOverrideRows(assignment))
    })
    return rows
  }

  function renderTable(_props = {}, matches = []) {
    const widthProp = `${DATE_COLUMN_WIDTH_REMS}rem`
    const noteWidthProp = `${NOTE_COLUMN_WIDTH_REMS}rem`
    const layoutProp = matches.includes('small') ? 'stacked' : 'fixed'
    return (
      <Table caption={I18n.t('Assignment Dates')} hover layout={layoutProp}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="title">{I18n.t('Title')}</Table.ColHeader>
            <Table.ColHeader width={widthProp} id="due">
              {DATE_INPUT_META.due_at.label}
            </Table.ColHeader>
            <Table.ColHeader width={widthProp} id="unlock">
              {DATE_INPUT_META.unlock_at.label}
            </Table.ColHeader>
            <Table.ColHeader width={widthProp} id="lock">
              {DATE_INPUT_META.lock_at.label}
            </Table.ColHeader>
            <Table.ColHeader id="note" width={noteWidthProp}>
              <ScreenReaderContent>{I18n.t('Notes')}</ScreenReaderContent>
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
        query={{small: {maxWidth: `${5 * DATE_COLUMN_WIDTH_REMS + NOTE_COLUMN_WIDTH_REMS}rem`}}}
        render={renderTable}
      />
    )
  } else {
    return renderTable()
  }
}
