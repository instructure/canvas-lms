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
import React, {useState, useMemo} from 'react'
import PaginatedTable from './PaginatedTable'
import {Header} from './SimpleTable'
import {InsightsTableProps} from './InsightsTable'

const SortableTable: React.FC<InsightsTableProps> = ({caption, headers, rows, perPage}) => {
  const [sortBy, setSortBy] = useState<Header['id'] | undefined>(undefined)
  const [ascending, setAscending] = useState(true)

  const sortedRows = useMemo(() => {
    if (!sortBy) return rows
    const sorted = [...rows].sort((a, b) => {
      return (a[sortBy] as string).localeCompare(b[sortBy] as string)
    })

    return ascending ? sorted : sorted.reverse()
  }, [sortBy, ascending, rows])

  const handleSort = (id: Header['id']) => {
    if (id === sortBy) {
      setAscending(!ascending)
    } else {
      setSortBy(id)
      setAscending(true)
    }
  }

  return (
    <PaginatedTable
      caption={caption}
      headers={headers}
      rows={sortedRows}
      onSort={handleSort}
      sortBy={sortBy}
      ascending={ascending}
      perPage={perPage}
    />
  )
}

export default SortableTable
