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
import React, {useState} from 'react'
import {Pagination} from '@instructure/ui-pagination'
import {Flex} from '@instructure/ui-flex'
import SimpleTable, {SimpleTableProps, Header} from './SimpleTable'

type PaginatedTableProps = SimpleTableProps & {
  perPage: number
}

const PaginatedTable: React.FC<PaginatedTableProps> = ({
  caption,
  headers,
  rows,
  onSort,
  sortBy,
  ascending,
  perPage,
}) => {
  const [page, setPage] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)

  const handleSort = (id: Header['id']) => {
    setPage(0)
    onSort(id)
  }

  const startIndex = page * perPage
  const slicedRows = rows.slice(startIndex, startIndex + perPage)
  const pageCount = perPage && Math.ceil(rows.length / perPage)

  const handlePageChange = (nextPage: number) => {
    setCurrentPage(nextPage)
    setPage(nextPage - 1)
  }

  return (
    <Flex width="100%" direction="row" wrap="wrap" justifyItems="end">
      <SimpleTable
        caption={caption}
        headers={headers}
        rows={slicedRows}
        onSort={handleSort}
        sortBy={sortBy}
        ascending={ascending}
      />
      {pageCount > 1 && (
        <Flex.Item>
          <Pagination
            as="nav"
            variant="input"
            labelNext="Next Page"
            labelPrev="Previous Page"
            margin="small"
            currentPage={currentPage}
            onPageChange={handlePageChange}
            totalPageNumber={pageCount}
          />
        </Flex.Item>
      )}
    </Flex>
  )
}

export default PaginatedTable
