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

//
// ******************************************************************
// this version has code to change the selected section
// but it causes the page to fail to render
// It seems to simply be the presence of the Menu.Items.
// I don't understand, and will get back to this later.
//
// there's some other weird stuff going on with FooterSecdtionIcon too
// something is very wrong at a fundamental level of the block editor
// that we need to figure out
// ******************************************************************

import React, {useCallback} from 'react'
import {useEditor, type Node} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {getCloneTree, scrollIntoViewWithCallback, getScrollParent, getNodeIndex} from '../../utils'

import {ResourcesSection, ResourcesSectionIcon} from '../user/sections/ResourcesSection'
import {ColumnsSection, ColumnsSectionIcon} from '../user/sections/ColumnsSection'
import {HeroSection, HeroSectionIcon} from '../user/sections/HeroSection'
import {NavigationSection, NavigationSectionIcon} from '../user/sections/NavigationSection'
import {AboutSection, AboutSectionIcon} from '../user/sections/AboutSection'
import {QuizSection, QuizSectionIcon} from '../user/sections/QuizSection'
// import {FooterSection} from '../user/sections/FooterSection'
import {BlankSection, BlankSectionIcon} from '../user/sections/BlankSection'

// TODO: for some reason, when I import FooterSectionIcon, the page fails to render
//       even though it's defined exactly the same way as here
import {IconHeaderLine} from '@instructure/ui-icons/es/svg'

const FooterSectionIcon = IconHeaderLine.src

function triggerScrollEvent() {
  const scrollingContainer = getScrollParent()
  const scrollEvent = new Event('scroll')
  scrollingContainer.dispatchEvent(scrollEvent)
}

type SectionMenuProps = {
  onEditSection?: (node: Node, newSectionId: string) => void
  onDuplicateSection?: (node: Node) => void
  onMoveUp?: (node: Node) => void
  onMoveDown?: (node: Node) => void
  onRemove?: (node: Node) => void
}
const SectionMenu = ({
  onEditSection,
  onDuplicateSection,
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

  const handleEditSection = useCallback(() => {
    if (onEditSection) {
      onEditSection(selected.get())
    }
  }, [onEditSection, selected])

  const handleDuplicateSection = useCallback(() => {
    if (onDuplicateSection) {
      onDuplicateSection(selected.get())
    } else {
      const currentNode = selected.get()
      const parentId = currentNode.data.parent
      if (!parentId) return

      const newTree = getCloneTree(currentNode.id, query)
      const siblings = query.node(parentId).descendants()
      const myIndex = siblings.indexOf(currentNode.id)
      actions.addNodeTree(newTree, parentId, myIndex + 1)
      actions.selectNode(newTree.rootNodeId)
      requestAnimationFrame(() => {
        scrollIntoViewWithCallback(
          query.node(newTree.rootNodeId).get().dom,
          {block: 'nearest'},
          triggerScrollEvent
        )
      })
    }
  }, [actions, onDuplicateSection, query, selected])

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
      window.setTimeout(() => {
        actions.delete(selected.get().id)
      }, 0)
    }
  }, [actions, onRemove, selected])

  const handleChangeSection = useCallback(
    (
      e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      if (onEditSection) {
        return onEditSection(selected.get(), value as string)
      }
      // let nodeTree
      // switch (value) {
      //   case 'BlankSection':
      //     nodeTree = query.parseReactElement(<BlankSection />).toNodeTree()
      //     break
      //   case 'HeroSection':
      //     nodeTree = query.parseReactElement(<HeroSection />).toNodeTree()
      //     break
      //   case 'NavigationSection':
      //     nodeTree = query.parseReactElement(<NavigationSection />).toNodeTree()
      //     break
      //   case 'AboutSection':
      //     nodeTree = query.parseReactElement(<AboutSection />).toNodeTree()
      //     break
      //   case 'ResourcesSection':
      //     nodeTree = query.parseReactElement(<ResourcesSection />).toNodeTree()
      //     break
      //   case 'ColumnsSection':
      //     nodeTree = query
      //       .parseReactElement(<ColumnsSection columns={2} variant="fixed" />)
      //       .toNodeTree()
      //     break
      //   // case 'FooterSection':
      //   //   nodeTree = query.parseReactElement(<FooterSection />).toNodeTree()
      //   //   break
      //   case 'QuizSection':
      //     nodeTree = query.parseReactElement(<QuizSection />).toNodeTree()
      //     break
      // }
      // if (nodeTree) {
      //   const myIndex = getNodeIndex(selected.get(), query)
      //   actions.addNodeTree(nodeTree, 'ROOT', myIndex)
      //   handleRemove()
      // }
    },
    [onEditSection, selected]
  )

  const renderSectionMenuItem = (label: string, value: string, icon: string) => {
    return (
      <Menu.Item value={value} type="checkbox" selected={selected.get().data.name === value}>
        <Flex gap="x-small" wrap="no-wrap">
          <SVGIcon src={icon} color="inherit" />
          {label}
        </Flex>
      </Menu.Item>
    )
  }

  return (
    <Menu show={true} onToggle={() => {}}>
      <Menu label="Edit Section" onSelect={handleChangeSection}>
        {renderSectionMenuItem('Blank', 'BlankSection', BlankSectionIcon)}
        {renderSectionMenuItem('Hero', 'HeroSection', HeroSectionIcon)}
        {renderSectionMenuItem('Navigation', 'NavigationSection', NavigationSectionIcon)}
        {renderSectionMenuItem('About', 'AboutSection', AboutSectionIcon)}
        {renderSectionMenuItem('Resources', 'ResourcesSection', ResourcesSectionIcon)}
        {renderSectionMenuItem('Columns', 'ColumnsSection', ColumnsSectionIcon)}
        {/* {renderSectionMenuItem('Footer', 'FooterSection', FooterSectionIcon)} */}
        {renderSectionMenuItem('Quiz', 'QuizSection', QuizSectionIcon)}
      </Menu>
      <Menu.Item onSelect={handleDuplicateSection}>Duplicate</Menu.Item>
      <Menu.Item onSelect={handleMoveUp}>Move Up</Menu.Item>
      <Menu.Item onSelect={handleMoveDown}>Move Down</Menu.Item>
      <Menu.Item onSelect={handleRemove} disabled={!selected.isDeletable()}>
        Remove
      </Menu.Item>
    </Menu>
  )
}

export {SectionMenu}
