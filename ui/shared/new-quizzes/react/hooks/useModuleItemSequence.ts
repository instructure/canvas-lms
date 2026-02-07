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
import doFetchApi from '@canvas/do-fetch-api-effect'

interface ModuleItem {
  html_url: string
  title: string
  type: string
}

interface ModuleItemSequenceResponse {
  items: Array<{
    prev: ModuleItem | null
    current: ModuleItem | null
    next: ModuleItem | null
  }>
  modules: Array<{id: number; name: string}>
}

interface ModuleNavigation {
  onPreviousItem?: () => void
  onNextItem?: () => void
}

/**
 * Fetches module item sequence data from Canvas API and returns
 * navigation callbacks for previous/next module items.
 *
 * This replicates the logic from the jQuery ModuleSequenceFooter
 * (ui/shared/module-sequence-footer) as a React hook for use with
 * New Quizzes module federation integration.
 */
export function useModuleItemSequence(
  courseId: string | undefined,
  moduleItemId: string | undefined,
): ModuleNavigation {
  const [navigation, setNavigation] = useState<ModuleNavigation>({})

  useEffect(() => {
    if (!courseId || !moduleItemId) {
      return
    }

    const params = new URLSearchParams({
      asset_type: 'ModuleItem',
      asset_id: moduleItemId,
      frame_external_urls: 'true',
    })

    doFetchApi<ModuleItemSequenceResponse>({
      path: `/api/v1/courses/${courseId}/module_item_sequence?${params.toString()}`,
      method: 'GET',
    })
      .then(({json}) => {
        if (!json?.items?.length || json.items.length !== 1) {
          return
        }

        const item = json.items[0]
        const nav: ModuleNavigation = {}

        if (item.prev?.html_url) {
          nav.onPreviousItem = () => {
            window.location.href = item.prev!.html_url
          }
        }

        if (item.next?.html_url) {
          nav.onNextItem = () => {
            window.location.href = item.next!.html_url
          }
        }

        setNavigation(nav)
      })
      .catch(() => {})
  }, [courseId, moduleItemId])

  return navigation
}
