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
import {Pagination} from '@instructure/ui-pagination'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Pagination as PaginationType} from '@canvas/outcomes/react/types/rollup'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface GradebookPaginationProps {
  pagination: PaginationType
  onPageChange: (page: number) => void
}

export const GradebookPagination: React.FC<GradebookPaginationProps> = ({
  pagination,
  onPageChange,
}) => {
  return (
    <Pagination
      as="nav"
      margin="small"
      variant="compact"
      labelNext={I18n.t('Next Page')}
      labelPrev={I18n.t('Previous Page')}
      currentPage={pagination.currentPage}
      totalPageNumber={pagination.totalPages}
      onPageChange={nextPage => onPageChange(nextPage)}
      showDisabledButtons
      siblingCount={4}
      data-testid="gradebook-pagination"
    />
  )
}
