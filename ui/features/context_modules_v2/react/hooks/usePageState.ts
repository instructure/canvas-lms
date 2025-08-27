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

import {useState, useEffect, useCallback} from 'react'
import {ModuleItemsStore} from '@canvas/context-modules/utils/ModuleItemsStore'

export function usePageState(moduleId: string) {
  const [pageIndex, setPageIndexState] = useState(1)
  const [store] = useState(() => {
    const courseId = ENV.course_id || ''
    const accountId = ENV.ACCOUNT_ID || ''
    const userId = ENV.current_user_id || ''
    return new ModuleItemsStore(courseId, accountId, userId)
  })

  useEffect(() => {
    const initialPage = parseInt(store.getPageNumber(moduleId), 10)
    setPageIndexState(initialPage)
  }, [moduleId, store])

  const setPageIndex = useCallback(
    (page: number) => {
      setPageIndexState(page)
      store.setPageNumber(moduleId, page)
    },
    [moduleId, store],
  )

  return [pageIndex, setPageIndex] as const
}
