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

import {useState, useCallback} from 'react'
import {useMutation} from '@tanstack/react-query'
import type {TabId} from '../types'
import {TAB_IDS, UPDATE_LEARNER_DASHBOARD_TAB_SELECTION} from '../constants'
import {executeQuery} from '@canvas/graphql'

interface UpdateTabSelectionResponse {
  updateLearnerDashboardTabSelection?: {
    tab: string
    errors?: Array<{message: string}>
  }
}

export function useTabState(defaultTab: TabId = TAB_IDS.DASHBOARD) {
  const [currentTab, setCurrentTab] = useState<TabId>(defaultTab)

  const updateTabMutation = useMutation({
    mutationFn: async (tab: TabId) => {
      const result = await executeQuery<UpdateTabSelectionResponse>(
        UPDATE_LEARNER_DASHBOARD_TAB_SELECTION,
        {tab},
      )
      return result
    },
  })

  const handleTabChange = useCallback(
    (tabId: TabId) => {
      // Optimistic update
      setCurrentTab(tabId)

      // Persist to backend (fire and forget)
      updateTabMutation.mutate(tabId)
    },
    [updateTabMutation.mutate],
  )

  return {
    currentTab,
    handleTabChange,
  }
}
