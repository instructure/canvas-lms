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

import type {CheckboxTreeNode, ItemType} from '@canvas/content-migrations'
import type {Item} from './content_selection_modal'
import type {GenericItemResponse, Migrator, SelectiveDataRequest} from './types'

export const humanReadableSize = (size: number): string => {
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let i = 0
  while (size >= 1024) {
    size /= 1024
    ++i
  }
  return size.toFixed(1) + ' ' + units[i]
}

const compareStrings = (a: string | undefined, b: string | undefined): number => {
  const str1 = a || ''
  const str2 = b || ''
  return str1.localeCompare(str2)
}

export const compareMigrators = (a: Migrator, b: Migrator): number => {
  const higherPriority = ['course_copy_importer', 'canvas_cartridge_importer']
  if (higherPriority.includes(a.type) && higherPriority.includes(b.type)) {
    return compareStrings(a.name, b.name)
  }

  if (higherPriority.includes(a.type)) {
    return -1
  }

  if (higherPriority.includes(b.type)) {
    return 1
  }

  return compareStrings(a.name, b.name)
}

export const timeout = (delay: number) => {
  return new Promise(resolve => setTimeout(resolve, delay))
}

const adjustCheckboxTreeNodesByImportAsOneModuleItemState = (
  checkboxTreeNodes: Record<string, CheckboxTreeNode>,
): void => {
  const typesForRootNodeUncheck: Set<ItemType> = new Set<ItemType>()

  Object.values(checkboxTreeNodes).forEach(node => {
    // set parent checkbox state to false if the node importAsOneModuleItemState is set to
    // import as a standalone module, that was the previous UI's behaviour
    if (node.importAsOneModuleItemState === 'on' && node.parentId) {
      checkboxTreeNodes[node.parentId].checkboxState = 'unchecked'
      typesForRootNodeUncheck.add(node.type)
    }
  })

  Object.values(checkboxTreeNodes).forEach(node => {
    if (!node.parentId && typesForRootNodeUncheck.has(node.type)) {
      node.checkboxState = 'unchecked'
    }
  })
}

export const generateSelectiveDataResponse = (
  migrationId: string,
  userId: string,
  checkboxTreeNodes: Record<string, CheckboxTreeNode>,
): SelectiveDataRequest => {
  const nonRootElements: Record<string, Record<string, '1'>> = {}
  const rootElements: Record<string, '1'> = {}

  adjustCheckboxTreeNodesByImportAsOneModuleItemState(checkboxTreeNodes)

  Object.values(checkboxTreeNodes).forEach(node => {
    if (node.migrationId && node.checkboxState === 'checked') {
      nonRootElements[node.type] ||= {}
      nonRootElements[node.type][node.migrationId] = '1'
    }

    // These are the all_discussions, all_assignments, all_* elements
    if (!node.migrationId && node.checkboxState === 'checked') {
      const match = node.id.match(/\[(.*?)\]/)
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
    copy:
      Object.keys(nonRootElements).length > 0 || Object.keys(rootElements).length > 0
        ? {...rootElements, ...nonRootElements}
        : {},
  }
}

export const mapToCheckboxTreeNodes = (
  items: Item[],
  parentId?: string,
): Record<string, CheckboxTreeNode> => {
  const checkboxTreeNodes: Record<string, CheckboxTreeNode> = {}

  items.forEach(item => {
    const {id, label, type, children, linkedId, checkboxState, migrationId, isSubModule} = item
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
      checkboxTreeNodes[id].migrationId = `id_${migrationId}`
    }

    if (isSubModule) {
      checkboxTreeNodes[id].importAsOneModuleItemState = 'off'
    }

    if (children) {
      Object.assign(checkboxTreeNodes, mapToCheckboxTreeNodes(children, id))
    }
  })

  Object.values(checkboxTreeNodes).forEach(node => {
    if (node.importAsOneModuleItemState && node.parentId) {
      const parentNode = checkboxTreeNodes[node.parentId]
      if (parentNode && parentNode.importAsOneModuleItemState) {
        node.importAsOneModuleItemState = 'disabled'
      }
    }
  })

  return checkboxTreeNodes
}

export const responseToItem = (
  {
    type,
    title,
    property,
    sub_items,
    linked_resource,
    migration_id,
    submodule_count,
  }: GenericItemResponse,
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
    base.children = sub_items.map(sub_item => {
      const item = responseToItem(sub_item, translator)
      if (submodule_count && submodule_count > 0) {
        item.isSubModule = true
      }
      return item
    })
  }

  if (linked_resource) {
    base.linkedId = `copy[${linked_resource.type}][id_${linked_resource.migration_id}]`
  }

  return base
}

export {parseDateToISOString} from '@canvas/content-migrations'
