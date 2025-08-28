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

import {
  defaultNextResource,
  NextResource,
} from '../../../shared/react/stores/AccessibilityScansStore'
import {AccessibilityIssue, AccessibilityResourceScan} from '../../../shared/react/types'

export const useNextResource = () => {
  const getNextResource = (
    items: AccessibilityResourceScan[],
    currentItem: AccessibilityResourceScan,
  ) => {
    if (!Array.isArray(items)) {
      return null
    }

    const nextResource: NextResource = defaultNextResource
    const currentIndex = items.findIndex(
      item => item.id === currentItem?.id && item.resourceType === currentItem.resourceType,
    )

    if (currentIndex === -1) {
      return null
    }
    const itemsBefore = items.slice(0, currentIndex)
    const itemsAfter = items.slice(currentIndex + 1)
    const orderedItems = itemsAfter.concat(itemsBefore)

    nextResource.item = orderedItems.find(item => item.issueCount > 0)
    nextResource.index = items.findIndex(
      item =>
        item.id === nextResource.item?.id && item.resourceType === nextResource.item.resourceType,
    )

    return nextResource
  }

  const updateCountPropertyForItem = (
    items: AccessibilityResourceScan[],
    item: AccessibilityResourceScan,
  ) => {
    return items.map(currentItem => {
      if (currentItem.id === item.id && currentItem.resourceType === item.resourceType) {
        return {...currentItem, count: 0}
      }
      return currentItem
    })
  }

  const getAccessibilityIssuesByItem = (
    items: AccessibilityResourceScan[],
    item: AccessibilityResourceScan,
  ): AccessibilityIssue[] => {
    const foundScan = items.find(
      currentItem => currentItem.id === item.id && currentItem.resourceType === item.resourceType,
    )
    return foundScan?.issues ?? []
  }

  return {
    getNextResource,
    updateCountPropertyForItem,
    getAccessibilityIssuesByItem,
  }
}
