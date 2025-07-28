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

import SimpleTable, {Header, BaseTableProps} from './SimpleTable'

type SortableTableProps = BaseTableProps & {
  perPage: number
  page: number
}

const SortableTable: React.FC<SortableTableProps> = ({caption, headers, rows, perPage, page}) => {
  const [sortBy, setSortBy] = useState<Header['id'] | undefined>(undefined)
  const [ascending, setAscending] = useState(true)

  const sortedRows = useMemo(() => {
    if (!sortBy) return rows

    const sortTypes: Record<string, (a: any, b: any) => number> = {
      relevance: (a, b) => {
        const relevanceOrder = {relevant: 1, needs_review: 2, irrelevant: 3}
        return (
          relevanceOrder[a[sortBy] as keyof typeof relevanceOrder] -
          relevanceOrder[b[sortBy] as keyof typeof relevanceOrder]
        )
      },
      date: (a, b) => (a[sortBy] as string).localeCompare(b[sortBy] as string),
      name: (a, b) => (a[sortBy] as string).localeCompare(b[sortBy] as string),
    }
    const sorted = [...rows].sort(sortTypes[sortBy])

    return ascending ? sorted : sorted.reverse()
  }, [sortBy, ascending, rows])

  const startIndex = page * perPage
  const slicedRows = sortedRows.slice(startIndex, startIndex + perPage)

  const handleSort = (id: Header['id']) => {
    if (id === sortBy) {
      setAscending(!ascending)
    } else {
      setSortBy(id)
      setAscending(true)
    }
  }

  return (
    <SimpleTable
      caption={caption}
      headers={headers}
      rows={slicedRows}
      onSort={handleSort}
      sortBy={sortBy}
      ascending={ascending}
    />
  )
}

export default SortableTable
