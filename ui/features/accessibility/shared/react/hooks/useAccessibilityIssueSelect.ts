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

import {useCallback} from 'react'
import {useNextResource} from '../hooks/useNextResource'
import {useAccessibilityCheckerContext} from './useAccessibilityCheckerContext'
import {useAccessibilityScansStore} from '../stores/AccessibilityScansStore'
import {findById} from '../utils/apiData'
import {AccessibilityResourceScan} from '../types'
import {useShallow} from 'zustand/react/shallow'

export function useAccessibilityIssueSelect() {
  const {setSelectedItem, setIsTrayOpen} = useAccessibilityCheckerContext()

  const {getNextResource} = useNextResource()

  const [accessibilityScans, setNextResource] = useAccessibilityScansStore(
    useShallow(state => [state.accessibilityScans, state.setNextResource]),
  )

  const selectIssue = useCallback(
    (item: AccessibilityResourceScan, openTray: boolean = true) => {
      const originalItem = findById(accessibilityScans, item.id)
      const updatedItem: AccessibilityResourceScan = {
        ...item,
        issues: originalItem?.issues || [],
      }

      setSelectedItem(updatedItem)

      if (openTray) {
        setIsTrayOpen(true)
      }

      if (accessibilityScans) {
        const nextResource = getNextResource(accessibilityScans, updatedItem)
        if (nextResource) {
          setNextResource(nextResource)
        }
      }

      return updatedItem
    },
    [accessibilityScans, setNextResource, setSelectedItem, setIsTrayOpen, getNextResource],
  )

  return {selectIssue}
}
