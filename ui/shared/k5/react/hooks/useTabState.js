/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useEffect, useRef, useState} from 'react'
import qs from 'qs'
import {TAB_IDS} from '../utils'

export const getInitialTab = defaultTab => {
  if (window.location.hash) {
    const newTab = window.location.hash.replace('#', 'tab-')
    if (Object.values(TAB_IDS).includes(newTab)) {
      return newTab
    }
  }
  return defaultTab
}

/**
 * @typedef  {Object} useTabStateReturnVal
 * @property {string} currentTab - The currently selected tab.
 * @property {React.MutableRefObject<string>} activeTab - A ref to the currently selected tab
 *           that isn't scoped to the closures of the effects in this hook.
 * @property {function(string)} handleTabChange - A callback function that receives the id of the
 *           tab that was just selected.
 */

/**
 * A hook for setting up state to be used in conjunction with {@link app/jsx/dashboard/K5Tabs.js}.
 * Manages synchronization of the currently selected tab with the window location hash, including
 * handling returning to the appropriate tab when navigating backward. Returns the currently
 * selected tab id, including a handler function for selecting a new tab by id.
 *
 * @param   {string} defaultTab - The id of the tab that should start selected.
 * @returns {useTabStateReturnVal} - See {@link useTabStateReturnVal}
 */
export default function useTabState(defaultTab) {
  // This ref is used to pass the current tab to the planner's getActiveApp()
  // function-- we can't use currentTab directly because that gets stuck in
  // a stale closure within the effect where it is referenced.
  const activeTab = useRef()
  const [currentTab, setCurrentTab] = useState(() => getInitialTab(defaultTab))

  useEffect(() => {
    activeTab.current = currentTab
  }, [currentTab])

  const handleTabChange = (id, focusTarget = '') => {
    setCurrentTab(id)
    const {protocol, host, pathname, search} = window.location
    if (window.history.replaceState) {
      const queryParams = qs.parse(search.substring(1))
      queryParams.focusTarget = focusTarget || undefined
      let query = qs.stringify(queryParams)
      query = query ? `?${query}` : ''
      const newUrl = `${protocol}//${host}${pathname}${query}#${id.replace('tab-', '')}`
      window.history.replaceState({id}, null, newUrl)
    }
  }

  return {currentTab, activeTab, handleTabChange}
}
