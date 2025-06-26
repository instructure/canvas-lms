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

import {BasicPaginationLayout} from './BasicPaginationLayout'
import {BasicPaginationButton} from './BasicPaginationButton'
import {getI18nPaginationInfo} from './utils'

export type BasicPaginationProps = {
  labelNext: string
  labelPrev: string
  currentPage: number
  perPage: number
  totalItems: number
  onNext: () => void
  onPrev: () => void
}

export const BasicPagination = ({
  labelNext,
  labelPrev,
  currentPage,
  perPage,
  totalItems,
  onNext,
  onPrev,
}: BasicPaginationProps) => {
  const totalPages = Math.ceil(totalItems / perPage)
  return (
    <BasicPaginationLayout
      prevButton={
        <BasicPaginationButton
          variant="prev"
          screenReaderLabel={labelPrev}
          onClick={onPrev}
          disabled={currentPage <= 1}
        />
      }
      nextButton={
        <BasicPaginationButton
          variant="next"
          screenReaderLabel={labelNext}
          onClick={onNext}
          disabled={currentPage >= totalPages}
        />
      }
      pageInfo={getI18nPaginationInfo(currentPage, totalItems, perPage)}
    />
  )
}
