/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useEffect, useMemo, useRef} from 'react'

export default function useIncrementalLoading(options) {
  const {
    contextType,
    hasMore,
    isLoading,
    lastItemRef,
    sortBy,
    searchString,
    onLoadInitial,
    onLoadMore,
    records,
  } = options
  const recordCountRef = useRef(records.length)

  useEffect(() => {
    onLoadInitial()
  }, [sortBy.sort, sortBy.order, searchString, contextType]) // eslint-disable-line react-hooks/exhaustive-deps

  return useMemo(() => {
    const loader = {
      hasMore,
      isLoading,
      lastRecordsLoaded: records.length - recordCountRef.current,
      onLoadInitial,
      sortBy,
      searchString,
      contextType,

      onLoadMore() {
        if (lastItemRef.current) {
          lastItemRef.current.focus()
        }
        onLoadMore()
      },
    }

    recordCountRef.current = records.length

    return loader
  }, [
    sortBy,
    searchString,
    contextType,
    hasMore,
    isLoading,
    records.length,
    lastItemRef,
    onLoadInitial,
    onLoadMore,
  ])
}
