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
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '../../types/rollup'
import {TotalStudentText} from '../pagination/TotalStudentText'
import {StudentPerPageSelector} from '../pagination/StudentPerPageSelector'
import {DEFAULT_STUDENTS_PER_PAGE, STUDENTS_PER_PAGE_OPTIONS} from '../../utils/constants'

interface FilterWrapperProps {
  pagination?: Pagination
  onPerPageChange: (value: number) => void
}

export const FilterWrapper: React.FC<FilterWrapperProps> = ({pagination, onPerPageChange}) => {
  return (
    <Flex gap="small">
      {pagination && (
        <>
          <TotalStudentText totalCount={pagination.totalCount} />
          <StudentPerPageSelector
            options={STUDENTS_PER_PAGE_OPTIONS}
            value={pagination?.perPage ?? DEFAULT_STUDENTS_PER_PAGE}
            onChange={value => onPerPageChange(value)}
          />
        </>
      )}
    </Flex>
  )
}
