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

import React, {useEffect, useState} from 'react'
import {Element, useEditor, useNode, type Node} from '@craftjs/core'

import {NoSections} from '../../common'
import {Container} from '../Container/Container'
import {
  useClassNames,
  isNthChild,
  isTransparent,
  getContrastingColor,
  getEffectiveBackgroundColor,
} from '../../../../utils'
import {type GroupBlockProps, defaultAlignment} from './types'
import {GroupBlockToolbar} from './GroupBlockToolbar'
import {BlockResizer} from '../../../editor/BlockResizer'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const GroupBlock = (props: GroupBlockProps) => {
  const {
    alignment = GroupBlock.craft.defaultProps.alignment,
    verticalAlignment = GroupBlock.craft.defaultProps.verticalAlignment,
    layout = GroupBlock.craft.defaultProps.layout,
    resizable = GroupBlock.craft.defaultProps.resizable,
    background,
    borderColor,
    roundedCorners = GroupBlock.craft.defaultProps.roundedCorners,
    isColumn,
    width,
    height,
  } = props
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {actions, node} = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  const clazz = useClassNames(enabled, {empty: false}, [
    'block',
    'group-block',
    `${layout}-layout`,
    `${alignment}-align`,
    `${verticalAlignment}-valign`,
    `${roundedCorners ? 'rounded-corners' : ''}`,
  ])
  const [containerRef, setContainerRef] = useState<HTMLElement | null>(null)

  useEffect(() => {
    if (isColumn) {
      actions.setCustom((custom: any) => {
        custom.displayName = I18n.t('Column')
      })
    }
  }, [actions, isColumn])

  useEffect(() => {
    if (resizable !== node.data.custom.isResizable) {
      actions.setCustom((custom: object) => {
        // @ts-expect-error
        custom.isResizable = resizable
      })
    }
  }, [actions, node.data.custom.isResizable, resizable])

  const styl: React.CSSProperties = {}
  if (width) {
    styl.width = `${width}px`
  }
  if (height) {
    styl.height = `${height}px`
  }
  if (background && !isTransparent(background)) {
    styl.backgroundColor = background
    styl.color = getContrastingColor(background)
  } else if (containerRef) {
    const gbcolor = getEffectiveBackgroundColor(containerRef)
    styl.color = getContrastingColor(gbcolor)
  } else {
    styl.backgroundColor = 'transparent'
  }
  if (roundedCorners) {
    styl.borderRadius = '8px'
  }
  if (borderColor) {
    styl.borderColor = borderColor
  }

  return (
    <Container className={clazz} style={styl} ref={setContainerRef}>
      <Element id="group__inner" is={NoSections} canvas={true} className="group-block__inner" />
    </Container>
  )
}

GroupBlock.craft = {
  displayName: I18n.t('Group'),
  defaultProps: {
    layout: defaultAlignment.layout,
    alignment: defaultAlignment.alignment,
    verticalAlignment: defaultAlignment.verticalAlignment,
    roundedCorners: false,
    resizable: true,
  },
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      return !incomingNodes.some(
        (incomingNode: Node) =>
          incomingNode.data.custom.isSection || incomingNode.data.name === 'GroupBlock',
      )
    },
  },
  related: {
    toolbar: GroupBlockToolbar,
    resizer: BlockResizer,
  },
  custom: {
    isDeletable: (nodeId: string, query: any) => {
      const parentId = query.node(nodeId).get().data.parent
      const parent = query.node(parentId).get()
      let columnCount = 0
      if (parent) {
        if (parent.data.name === 'ColumnsSectionInner') {
          const colSect = query.node(parent.data.parent).get()
          columnCount = colSect.data.props.columns
          return (
            parent?.data.name !== 'ColumnsSectionInner' || !isNthChild(nodeId, query, columnCount)
          )
        } else {
          return true
        }
      }
      return false
    },
    isResizable: true,
    isBlock: true,
    isExpanded: false,
  },
}
