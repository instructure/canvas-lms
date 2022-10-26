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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useCallback} from 'react'
import {arrayOf, func, string} from 'prop-types'
import {Checkbox} from '@instructure/ui-checkbox'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconWarningLine, IconXSolid} from '@instructure/ui-icons'
import BulkDateInput from './BulkDateInput'
import BulkEditOverrideTitle from './BulkEditOverrideTitle'
import {AssignmentShape} from './BulkAssignmentShape'
import {canEditAll, originalDateField} from './utils'

const I18n = useI18nScope('assignments_bulk_edit')

const DATE_INPUT_META = {
  due_at: {
    label: I18n.t('Due At'),
    fancyMidnight: true,
  },
  unlock_at: {
    label: I18n.t('Available From'),
    fancyMidnight: false,
  },
  lock_at: {
    label: I18n.t('Available Until'),
    fancyMidnight: true,
  },
}

BulkEditTable.propTypes = {
  assignments: arrayOf(AssignmentShape).isRequired,

  // ({
  //   dateKey: one of null, "due_at", "lock_at", or "unlock_at"
  //   newDate: iso8601 date string
  //   assignmentId: assignment id string
  //
  //   overrideId: override id string, if this is an override.
  //   - or -
  //   base: true if this is the base assignment dates
  // }) => {...}
  updateAssignmentDate: func.isRequired,

  // {assignmentId, overrideId or base: true}
  clearOverrideEdits: func.isRequired,

  setAssignmentSelected: func.isRequired, // (assignmentId, selected) => {}

  defaultDueTime: string, // e.g. "16:00:00"
}

export default function BulkEditTable({
  assignments,
  updateAssignmentDate,
  setAssignmentSelected,
  selectAllAssignments,
  clearOverrideEdits,
  defaultDueTime,
}) {
  const CHECKBOX_COLUMN_WIDTH_REMS = 2
  const DATE_COLUMN_WIDTH_REMS = 17
  const ACTION_COLUMN_WIDTH_REMS = 4
  const NOTE_COLUMN_WIDTH_REMS = 3

  const someAssignmentsSelected = assignments.some(a => a.selected)
  const allAssignmentsSelected =
    someAssignmentsSelected && assignments.every(a => a.selected || !canEditAll(a))

  function processErrors(errors, dateKey) {
    if (!errors || !errors.hasOwnProperty(dateKey)) {
      return []
    }
    return [{text: errors[dateKey], type: 'error'}]
  }

  function renderDateInput(assignmentId, dateKey, dates, overrideId = null) {
    const label = DATE_INPUT_META[dateKey].label
    const calculatedWidth = `${DATE_COLUMN_WIDTH_REMS - 1}rem`
    return (
      <BulkDateInput
        label={label}
        selectedDateString={dates[dateKey]}
        messages={processErrors(dates.errors, dateKey)}
        dateKey={dateKey}
        assignmentId={assignmentId}
        overrideId={overrideId}
        updateAssignmentDate={updateAssignmentDate}
        fancyMidnight={
          dateKey === 'due_at' && defaultDueTime ? false : DATE_INPUT_META[dateKey].fancyMidnight
        }
        defaultTime={dateKey === 'due_at' ? defaultDueTime : null}
        interaction={dates.can_edit ? 'enabled' : 'disabled'}
        width={calculatedWidth}
      />
    )
  }

  function renderOverrideTitle(assignment, override) {
    return (
      <BulkEditOverrideTitle
        assignmentName={assignment.name}
        overrideTitle={override.title}
        overrideBase={override.base}
      />
    )
  }

  function renderNoDefaultDates(hasTooManyDates) {
    // The goal here is to create a cell that spans multiple columns. You can't do that with InstUI
    // yet, so we're going to fake it with a View that's as wide as all the other columns and
    // depend on the cell overflow as being visible. I think that's pretty safe since that's the
    // default overflow.
    return (
      <View
        as="div"
        minWidth={`${
          DATE_COLUMN_WIDTH_REMS * 3 + ACTION_COLUMN_WIDTH_REMS + NOTE_COLUMN_WIDTH_REMS
        }rem`}
      >
        <Text size="medium" fontStyle="italic">
          {hasTooManyDates
            ? I18n.t('This assignment has too many dates to display.')
            : I18n.t('This assignment has no default dates.')}
        </Text>
      </View>
    )
  }

  function renderAssignmentCheckbox(assignment) {
    if (assignment.hasOwnProperty('all_dates_count')) {
      return null
    }

    return (
      <Checkbox
        label={
          <ScreenReaderContent>
            {I18n.t('Select assignment: %{title}', {title: assignment.name})}
          </ScreenReaderContent>
        }
        checked={!!assignment.selected}
        onChange={() => setAssignmentSelected(assignment.id, !assignment.selected)}
        disabled={!canEditAll(assignment)}
      />
    )
  }

  function renderActions(assignment, override) {
    const overrideHasBeenEdited = ['due_at', 'unlock_at', 'lock_at']
      .map(field => originalDateField(field))
      .some(originalField => override.hasOwnProperty(originalField))

    if (overrideHasBeenEdited) {
      return (
        <Tooltip renderTip={I18n.t('Revert date changes')}>
          <IconButton
            renderIcon={IconXSolid}
            screenReaderLabel={I18n.t('Revert date changes')}
            withBackground={false}
            withBorder={false}
            onClick={event => handleRevertClick(assignment, override, event)}
          />
        </Tooltip>
      )
    } else {
      return null
    }
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
    const baseOverride = assignment.all_dates.find(dates => dates.base === true)
    // It's a bit repetitive this way, but Table.Row borks if it has anything but Table.Cell children.
    if (baseOverride) {
      return (
        <Table.Row key={`assignment_${assignment.id}`}>
          <Table.Cell>{renderAssignmentCheckbox(assignment)}</Table.Cell>
          <Table.Cell>{renderOverrideTitle(assignment, baseOverride)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'due_at', baseOverride)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'unlock_at', baseOverride)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'lock_at', baseOverride)}</Table.Cell>
          <Table.Cell>{renderActions(assignment, baseOverride)}</Table.Cell>
          <Table.Cell>{renderNote(assignment, baseOverride)}</Table.Cell>
        </Table.Row>
      )
    } else {
      // Need all Table.Cells or you get weird borders on this row
      return (
        <Table.Row key={`assignment_${assignment.id}`}>
          <Table.Cell>{renderAssignmentCheckbox(assignment)}</Table.Cell>
          <Table.Cell>{renderOverrideTitle(assignment, {base: true})}</Table.Cell>
          <Table.Cell>
            {renderNoDefaultDates(assignment.hasOwnProperty('all_dates_count'))}
          </Table.Cell>
          <Table.Cell />
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
            <ScreenReaderContent>
              {assignment.selected
                ? I18n.t('parent assignment is selected')
                : I18n.t('parent assignment is not selected')}
            </ScreenReaderContent>
          </Table.Cell>
          <Table.Cell>{renderOverrideTitle(assignment, override)}</Table.Cell>
          <Table.Cell>{renderDateInput(assignment.id, 'due_at', override, override.id)}</Table.Cell>
          <Table.Cell>
            {renderDateInput(assignment.id, 'unlock_at', override, override.id)}
          </Table.Cell>
          <Table.Cell>
            {renderDateInput(assignment.id, 'lock_at', override, override.id)}
          </Table.Cell>
          <Table.Cell>{renderActions(assignment, override)}</Table.Cell>
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

  const handleSelectAllAssignments = useCallback(
    () => selectAllAssignments(!allAssignmentsSelected),
    [allAssignmentsSelected, selectAllAssignments]
  )

  const handleRevertClick = (assignment, override, event) => {
    // assuming the revert button is going away, so we reset focus to the prior input before that
    // happens.
    const tableRow = event.target.closest('tr')
    const rowInputs = tableRow.querySelectorAll('input')
    if (rowInputs.length) rowInputs[rowInputs.length - 1].focus()
    clearOverrideEdits({assignmentId: assignment.id, overrideId: override.id})
  }

  function renderTable(_props = {}, matches = []) {
    const checkboxWidthProp = `${CHECKBOX_COLUMN_WIDTH_REMS}rem`
    const widthProp = `${DATE_COLUMN_WIDTH_REMS}rem`
    const actionsWidthProp = `${ACTION_COLUMN_WIDTH_REMS}rem`
    const noteWidthProp = `${NOTE_COLUMN_WIDTH_REMS}rem`
    const layoutProp = matches.includes('small') ? 'stacked' : 'fixed'

    // The select all checkbox can't be in the table header because we don't want a SR to read it on
    // every row, and in a stacked layout it would appear on every row. But we want it to visually
    // be in the header in a fixed layout, so we're going to manually position it. Hard coding a
    // visual offset like this sucks and is brittle, but I'm not sure what else to do right now.
    const [selectAllStyles, selectAllLabel, selectedHeader] =
      layoutProp === 'stacked'
        ? [{}, I18n.t('Select all assignments'), I18n.t('Selected')]
        : [
            {
              position: 'absolute',
              top: '8px',
              left: '13px',
            },
            <ScreenReaderContent>{I18n.t('Select all assignments')}</ScreenReaderContent>,
            <ScreenReaderContent>{I18n.t('Selected')}</ScreenReaderContent>,
          ]

    return (
      <div style={{position: 'relative'}}>
        <div style={selectAllStyles}>
          <Checkbox
            label={selectAllLabel}
            checked={allAssignmentsSelected}
            indeterminate={!allAssignmentsSelected && someAssignmentsSelected}
            onChange={handleSelectAllAssignments}
          />
        </div>
        <Table caption={I18n.t('Assignment Dates')} hover={true} layout={layoutProp}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="select" width={checkboxWidthProp}>
                {selectedHeader}
              </Table.ColHeader>
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
              <Table.ColHeader id="actions" width={actionsWidthProp}>
                <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
              </Table.ColHeader>
              <Table.ColHeader id="note" width={noteWidthProp}>
                <ScreenReaderContent>{I18n.t('Notes')}</ScreenReaderContent>
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>{renderAssignments()}</Table.Body>
        </Table>
      </div>
    )
  }

  // For test environments that don't have matchMedia
  if (window.matchMedia) {
    return (
      <Responsive
        match="media"
        query={{
          small: {
            maxWidth: `${
              5 * DATE_COLUMN_WIDTH_REMS + ACTION_COLUMN_WIDTH_REMS + NOTE_COLUMN_WIDTH_REMS
            }rem`,
          },
        }}
        render={renderTable}
      />
    )
  } else {
    return renderTable()
  }
}
