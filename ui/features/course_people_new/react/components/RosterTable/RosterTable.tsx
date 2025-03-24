/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, type FC, type SyntheticEvent} from 'react'
import {Table} from '@instructure/ui-table'
import RosterTableHeader from './RosterTableHeader'
import RosterTableRow from './RosterTableRow'
import {useScope as createI18nScope} from '@canvas/i18n'
import {User, SortField, SortDirection} from '../../../types'

const I18n = createI18nScope('course_people')

interface RosterTableProps {
  users: User[] | undefined
  handleSort: (event: SyntheticEvent<Element, Event>, {id}: {id: string}) => void
  sortField: SortField
  sortDirection: SortDirection
}

const RosterTable: FC<RosterTableProps> = ({
  users,
  handleSort,
  sortField,
  sortDirection
}) => {
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const userIds = (users || []).map(user => user._id)

  const handleSelectAll = (allSelected: boolean) =>
    setSelected(allSelected ? new Set() : new Set(userIds))

  const handleSelectRow = (rowSelected: boolean, userId: string) => {
    const copy = new Set(selected)
    if (rowSelected) {
      copy.delete(userId)
    } else {
      copy.add(userId)
    }
    setSelected(copy)
  }

  const allSelected =
    selected.size > 0 && userIds.every(id => selected.has(id))
  const someSelected = selected.size > 0 && !allSelected

  const renderRows = () => (users || []).map(user => (
    <RosterTableRow
      key={`user-id-${user._id}`}
      user={user}
      isSelected={selected.has(user._id)}
      handleSelectRow={handleSelectRow}
    />
  ))

  return (
    <Table caption={I18n.t('Course Roster')} data-testid="roster-table">
      <RosterTableHeader
        allSelected={allSelected}
        someSelected={someSelected}
        handleSelectAll={handleSelectAll}
        handleSort={handleSort}
        sortField={sortField}
        sortDirection={sortDirection}
      />
      <Table.Body>
        {renderRows()}
      </Table.Body>
    </Table>
  )
}

export default RosterTable
