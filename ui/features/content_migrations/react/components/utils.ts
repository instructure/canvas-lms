/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {CheckboxTreeNode} from '@canvas/content-migrations'
import type {Item} from './content_selection_modal'
import type {GenericItemResponse, SelectiveDataRequest} from './types'

export const humanReadableSize = (size: number): string => {
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let i = 0
  while (size >= 1024) {
    size /= 1024
    ++i
  }
  return size.toFixed(1) + ' ' + units[i]
}

export const timeout = (delay: number) => {
  return new Promise(resolve => setTimeout(resolve, delay))
}

export const generateSelectiveDataResponse = (
  migrationId: string,
  userId: string,
  checkboxTreeNodes: Record<string, CheckboxTreeNode>,
): SelectiveDataRequest => {
  const nonRootElements: Record<string, Record<string, '1'>> = {}
  const rootElements: Record<string, '1'> = {}

  Object.values(checkboxTreeNodes).forEach(item => {
    if (
      item.migrationId &&
      (item.checkboxState === 'indeterminate' || item.checkboxState === 'checked')
    ) {
      nonRootElements[item.type] ||= {}
      nonRootElements[item.type][item.migrationId] = '1'
    }

    // These are the all_discussions, all_assignments, all_* elements
    if (!item.migrationId && item.checkboxState === 'checked') {
      const match = item.id.match(/\[(.*?)\]/)
      const value = match ? match[1] : null
      if (value) {
        rootElements[value] = '1'
      }
    }
  })

  return {
    id: migrationId,
    user_id: userId,
    workflow_state: 'waiting_for_select',
    copy: {...rootElements, ...nonRootElements},
  }
}

export const mapToCheckboxTreeNodes = (
  items: Item[],
  parentId?: string,
): Record<string, CheckboxTreeNode> => {
  const checkboxTreeNodes: Record<string, CheckboxTreeNode> = {}

  items.forEach(item => {
    const {id, label, type, children, linkedId, checkboxState, migrationId} = item
    checkboxTreeNodes[id] = {
      id,
      label,
      type,
      checkboxState,
      childrenIds: children ? children.map(child => child.id) : [],
    }

    if (linkedId) {
      checkboxTreeNodes[id].linkedId = linkedId
    }

    if (parentId) {
      checkboxTreeNodes[id].parentId = parentId
    }

    if (migrationId) {
      checkboxTreeNodes[id].migrationId = migrationId
    }

    if (children) {
      Object.assign(checkboxTreeNodes, mapToCheckboxTreeNodes(children, id))
    }
  })

  return checkboxTreeNodes
}

export const responseToItem = (
  {type, title, property, sub_items, linked_resource, migration_id}: GenericItemResponse,
  translator: {t: Function},
): Item => {
  const base: Item = {
    id: property,
    label:
      sub_items && sub_items.length > 0
        ? translator.t('%{title} (%{count})', {title, count: sub_items.length})
        : title,
    checkboxState: 'unchecked',
    migrationId: migration_id,
    type,
  }

  if (sub_items && sub_items.length > 0) {
    base.children = sub_items.map(sub_item => responseToItem(sub_item, translator))
  }

  if (linked_resource) {
    base.linkedId = `copy[${linked_resource.type}][id_${linked_resource.migration_id}]`
  }

  return base
}

export {parseDateToISOString} from '@canvas/content-migrations'
