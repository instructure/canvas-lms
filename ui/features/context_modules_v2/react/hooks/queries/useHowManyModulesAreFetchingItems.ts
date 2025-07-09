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
import {MODULE_ITEMS_MAP, TEACHER} from '../../utils/constants'

export function useHowManyModulesAreFetchingItems(view: string = TEACHER) {
  const [maxFetchingCount, setMaxFetchingCount] = useState(0)
  const [prevFetchCount, setPrevFetchCount] = useState(0)
  const [fetchComplete, setFetchComplete] = useState(false)
  const moduleFetchingCount = useIsFetching({queryKey: [MODULE_ITEMS_MAP[view]]})

  useEffect(() => {
    if (moduleFetchingCount > 0) {
      setFetchComplete(false)
      if (prevFetchCount === 0) {
        setMaxFetchingCount(moduleFetchingCount)
      } else {
        setMaxFetchingCount(Math.max(maxFetchingCount, moduleFetchingCount))
      }
    }
  }, [maxFetchingCount, moduleFetchingCount, prevFetchCount])

  useEffect(() => {
    setPrevFetchCount(moduleFetchingCount)
  }, [moduleFetchingCount])

  useEffect(() => {
    if (moduleFetchingCount === 0 && prevFetchCount > 0) {
      setFetchComplete(true)
    }
  }, [moduleFetchingCount, prevFetchCount])

  return {
    moduleFetchingCount,
    maxFetchingCount,
    fetchComplete,
  }
}
