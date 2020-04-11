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
import React, {useState} from 'react'
// import {func, string} from 'prop-types'
import tz from 'timezone'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import CanvasDateInput from 'jsx/shared/components/CanvasDateInput'

export default function BulkEditTable({assignments}) {
  // Temporary so we can test the behavior of the new CanvasDateInput
  const [selectedDate, setSelectedDate] = useState(tz.parse(assignments[0].due_at))

  function renderDateInput(dateStr) {
    const date = tz.parse(dateStr)
    return tz.format(date, 'date.formats.medium_with_weekday')
  }

  function renderTableRows() {
    return assignments.map((assignment, index) => (
      <Table.Row key={assignment.id}>
        <Table.Cell>{assignment.name}</Table.Cell>
        <Table.Cell>
          {index === 0 ? (
            <CanvasDateInput
              selectedDate={selectedDate}
              onSelectedDateChange={setSelectedDate}
              renderLabel={<ScreenReaderContent>{I18n.t('Choose a due date')}</ScreenReaderContent>}
              formatDate={date => tz.format(date, 'date.formats.medium_with_weekday')}
            />
          ) : (
            renderDateInput(assignment.due_at)
          )}
        </Table.Cell>
        <Table.Cell>{renderDateInput(assignment.unlock_at)}</Table.Cell>
        <Table.Cell>{renderDateInput(assignment.lock_at)}</Table.Cell>
      </Table.Row>
    ))
  }

  return (
    <Table caption={I18n.t('Assignment Dates')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="title">{I18n.t('Title')}</Table.ColHeader>
          <Table.ColHeader id="due">{I18n.t('Due At')}</Table.ColHeader>
          <Table.ColHeader id="unlock">{I18n.t('Unlock At')}</Table.ColHeader>
          <Table.ColHeader id="lock">{I18n.t('Lock At')}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>{renderTableRows()}</Table.Body>
    </Table>
  )
}
