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

import {useCallback, useEffect, useRef} from 'react'
import {QueryMethods, SerializedNodes} from '@craftjs/core'
import {QueryCallbacksFor} from '@craftjs/utils'

export interface PageEditorHandler {
  getContent: () => {
    blocks: SerializedNodes
  }
}

export const usePageEditorIntegration = (onInit: ((handler: PageEditorHandler) => void) | null) => {
  const queryRef = useRef<QueryCallbacksFor<typeof QueryMethods> | null>(null)

  useEffect(() => {
    const handler: PageEditorHandler = {
      getContent: () => ({
        blocks: queryRef.current ? JSON.parse(queryRef.current.serialize()) : null,
      }),
    }
    onInit?.(handler)
  }, [onInit])

  return useCallback((query: QueryCallbacksFor<typeof QueryMethods>) => {
    queryRef.current = query
  }, [])
}
