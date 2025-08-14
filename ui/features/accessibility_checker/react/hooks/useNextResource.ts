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

import {defaultNextResource, NextResource} from '../stores/AccessibilityCheckerStore'
import {AccessibilityData, ContentItem} from '../types'
import {TypeToKeyMap} from '../constants'

export const useNextResource = () => {
  const getNextResource = (items: ContentItem[], currentItem: ContentItem) => {
    if (!Array.isArray(items)) {
      return null
    }

    const nextResource: NextResource = defaultNextResource
    const currentIndex = items.findIndex(
      item => item.id === currentItem?.id && item.type === currentItem.type,
    )

    if (currentIndex === -1) {
      return null
    }
    const itemsBefore = items.slice(0, currentIndex)
    const itemsAfter = items.slice(currentIndex + 1)
    const orderedItems = itemsAfter.concat(itemsBefore)

    nextResource.item = orderedItems.find(item => item.count > 0)
    nextResource.index = items.findIndex(
      item => item.id === nextResource.item?.id && item.type === nextResource.item.type,
    )

    return nextResource
  }

  const updateCountPropertyForItem = (items: ContentItem[], item: ContentItem) => {
    return items.map(currentItem => {
      if (currentItem.id === item.id && currentItem.type === item.type) {
        return {...currentItem, count: 0}
      }
      return currentItem
    })
  }

  const getAccessibilityIssuesByItem = (issues: AccessibilityData, item: ContentItem) => {
    const typeKey = TypeToKeyMap[item.type]
    const contentNextItem = issues?.[typeKey]?.[item.id]
      ? structuredClone(issues[typeKey]?.[item.id])
      : undefined
    return contentNextItem?.issues || []
  }
  return {getNextResource, updateCountPropertyForItem, getAccessibilityIssuesByItem}
}
