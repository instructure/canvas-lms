/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, type Node} from '@craftjs/core'
import {Menu} from '@instructure/ui-menu'
import {
  // getCloneTree,
  scrollIntoViewWithCallback,
  getScrollParent,
  getSectionLocation,
  type SectionLocation,
} from '../../utils'
import {type AddSectionPlacement} from './types'

function triggerScrollEvent() {
  const scrollingContainer = getScrollParent()
  const scrollEvent = new Event('scroll')
  scrollingContainer.dispatchEvent(scrollEvent)
}

export type SectionMenuProps = {
  onEditSection?: (node: Node) => void
  onAddSection: (placement: AddSectionPlacement) => void
  // onDuplicateSection?: (node: Node) => void
  onMoveUp?: (node: Node) => void
  onMoveDown?: (node: Node) => void
  onRemove?: (node: Node) => void
}
const SectionMenu = ({
  onEditSection,
  onAddSection,
  // onDuplicateSection,
  onMoveUp,
  onMoveDown,
  onRemove,
}: SectionMenuProps) => {
  const {actions, selected, query} = useEditor((state, qry) => {
    const [currentNodeId] = state.events.selected
    return {
      selected: qry.node(currentNodeId),
    }
  })
  const [sectionLocation, setSectionLocation] = useState<SectionLocation>(() => {
    if (selected.get()) {
      return getSectionLocation(selected.get(), query)
    }
    return 'middle'
  })

  useEffect(() => {
    if (selected.get()) {
      setSectionLocation(getSectionLocation(selected.get(), query))
    }
  }, [selected, query])

  const handleEditSection = useCallback(() => {
    if (onEditSection) {
      onEditSection(selected.get())
    }
  }, [onEditSection, selected])

  // const handleDuplicateSection = useCallback(() => {
  //   if (onDuplicateSection) {
  //     onDuplicateSection(selected.get())
  //   } else {
  //     const currentNode = selected.get()
  //     const parentId = currentNode.data.parent
  //     if (!parentId) return

  //     const newTree = getCloneTree(currentNode.id, query)
  //     const siblings = query.node(parentId).descendants()
  //     const myIndex = siblings.indexOf(currentNode.id)
  //     actions.addNodeTree(newTree, parentId, myIndex + 1)
  //     actions.selectNode(newTree.rootNodeId)
  //     requestAnimationFrame(() => {
  //       scrollIntoViewWithCallback(
  //         query.node(newTree.rootNodeId).get().dom,
  //         {block: 'nearest'},
  //         triggerScrollEvent
  //       )
  //     })
  //   }
  // }, [actions, onDuplicateSection, query, selected])

  const handleMoveUp = useCallback(() => {
    if (onMoveUp) {
      onMoveUp(selected.get())
    } else {
      const currentNode = selected.get()
      const parentId = currentNode.data.parent
      if (!parentId) return

      const siblings = query.node(parentId).descendants()
      const myIndex = siblings.indexOf(currentNode.id)
      if (myIndex === 0) return

      actions.move(currentNode.id, parentId, myIndex - 1)
      actions.selectNode(currentNode.id)
      requestAnimationFrame(() => {
        scrollIntoViewWithCallback(currentNode.dom, {block: 'nearest'}, triggerScrollEvent)
      })
    }
  }, [actions, onMoveUp, query, selected])

  const handleMoveDown = useCallback(() => {
    if (onMoveDown) {
      onMoveDown(selected.get())
    } else {
      const currentNode = selected.get()
      const parentId = currentNode.data.parent
      if (!parentId) return

      const siblings = query.node(parentId).descendants()
      const myIndex = siblings.indexOf(currentNode.id)
      if (myIndex === siblings.length + 1) return

      actions.move(currentNode.id, parentId, myIndex + 2)
      actions.selectNode(currentNode.id)
      requestAnimationFrame(() => {
        scrollIntoViewWithCallback(currentNode.dom, {block: 'nearest'}, triggerScrollEvent)
      })
    }
  }, [actions, onMoveDown, query, selected])

  const handleRemove = useCallback(() => {
    if (onRemove) {
      onRemove(selected.get())
    } else if (selected.get()?.id) {
      actions.delete(selected.get().id)
    }
  }, [actions, onRemove, selected])

  const handleAddSection = useCallback(
    (where: 'prepend' | 'append') => {
      onAddSection(where)
    },
    [onAddSection]
  )

  return (
    <Menu show={true} onToggle={() => {}}>
      {onEditSection ? <Menu.Item onSelect={handleEditSection}>EditSection</Menu.Item> : null}
      {/* <Menu.Item onSelect={handleDuplicateSection}>Duplicate</Menu.Item> */}
      <Menu.Item onSelect={handleAddSection.bind(null, 'prepend')}>+ Section Above</Menu.Item>
      <Menu.Item onSelect={handleAddSection.bind(null, 'append')}>+ Section Below</Menu.Item>
      <Menu.Item
        onSelect={handleMoveUp}
        disabled={sectionLocation === 'top' || sectionLocation === 'alone'}
      >
        Move Up
      </Menu.Item>
      <Menu.Item
        onSelect={handleMoveDown}
        disabled={sectionLocation === 'bottom' || sectionLocation === 'alone'}
      >
        Move Down
      </Menu.Item>
      <Menu.Item onSelect={handleRemove} disabled={!selected.isDeletable()}>
        Remove
      </Menu.Item>
    </Menu>
  )
}

export {SectionMenu}
