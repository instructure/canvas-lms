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

import React from 'react'
import {Element, useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames} from '../../../../utils'
import {type TabBlockProps} from './types'

// TabContent is a copy of NoSections with a canMoveIn rule
// preventing nested TabBlocks
export type TabContentProps = {
  className?: string
  children?: React.ReactNode
}

export const TabContent = ({className = '', children}: TabContentProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, [className])

  return (
    <div
      ref={el => el && connect(el)}
      className={clazz}
      data-placeholder="Drop a block to add it here"
    >
      {children}
    </div>
  )
}

TabContent.craft = {
  displayName: 'Tab Content',
  rules: {
    canMoveIn: (nodes: Node[]) => {
      return !nodes.some(node => node.data.custom.isSection || node.data.custom.notTabContent)
    },
  },
  custom: {
    noToolbar: true,
    notTabContent: true, // cannot be used as tab content
  },
}

const TabBlock = ({tabId}: TabBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const clazz = useClassNames(enabled, {empty: false}, ['block', 'tab-block'])
  return <Element id={tabId} is={TabContent} canvas={true} className={clazz} />
}

TabBlock.craft = {
  displayName: 'Tab',
  custom: {
    noToolbar: true,
    notTabContent: true,
  },
}

export {TabBlock}
