/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useCallback} from 'react'
import {useSearchParams} from 'react-router-dom'

interface usePaginationParamReturn {
  page: number
  handlePageChange: (newPage: number) => void
}

export const usePaginationParam = (): usePaginationParamReturn => {
  const [searchParams, setSearchParams] = useSearchParams()
  const parsedPage = parseInt(searchParams.get('page') || '1', 10)
  const page = parsedPage > 0 ? parsedPage : 1

  const handlePageChange = useCallback(
    (newPage: number) => {
      setSearchParams(params => {
        const newParams = new URLSearchParams(params)
        newParams.set('page', String(newPage))
        return newParams
      })
    },
    [setSearchParams],
  )

  return {
    page,
    handlePageChange,
  }
}
