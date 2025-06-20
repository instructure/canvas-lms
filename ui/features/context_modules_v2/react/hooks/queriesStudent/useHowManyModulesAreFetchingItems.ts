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

import {useEffect, useState} from 'react'
import {useIsFetching} from '@tanstack/react-query'

export function useHowManyModulesAreFetchingItems() {
  const [maxFetchingCount, setMaxFetchingCount] = useState(0)
  const [prevFetchCount, setPrevFetchCount] = useState(0)
  const moduleFetchingCount = useIsFetching({queryKey: ['moduleItemsStudent']})

  useEffect(() => {
    if (moduleFetchingCount > 0) {
      if (prevFetchCount === 0) {
        setMaxFetchingCount(moduleFetchingCount)
      } else {
        setMaxFetchingCount(Math.max(maxFetchingCount, moduleFetchingCount))
      }
    }
    if (moduleFetchingCount === 0 && prevFetchCount === 0) {
      setMaxFetchingCount(0)
    }
  }, [maxFetchingCount, moduleFetchingCount, prevFetchCount])

  useEffect(() => {
    setPrevFetchCount(moduleFetchingCount)
  }, [moduleFetchingCount])

  const fetchComplete = moduleFetchingCount === 0 && prevFetchCount > 0

  return {
    moduleFetchingCount,
    maxFetchingCount,
    fetchComplete,
  }
}
