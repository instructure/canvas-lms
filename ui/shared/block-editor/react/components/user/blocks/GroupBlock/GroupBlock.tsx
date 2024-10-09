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

import React, {useEffect} from 'react'
import {Element, useEditor, useNode, type Node} from '@craftjs/core'

import {NoSections} from '../../common'
import {Container} from '../Container/Container'
import {useClassNames, isNthChild} from '../../../../utils'
import {type GroupBlockProps} from './types'
import {GroupBlockToolbar} from './GroupBlockToolbar'
import {BlockResizer} from '../../../editor/BlockResizer'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

export const GroupBlock = (props: GroupBlockProps) => {
  const {
    alignment = GroupBlock.craft.defaultProps.alignment,
    verticalAlignment = GroupBlock.craft.defaultProps.verticalAlignment,
    layout = GroupBlock.craft.defaultProps.layout,
    resizable = GroupBlock.craft.defaultProps.resizable,
  } = props
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const clazz = useClassNames(enabled, {empty: false}, [
    'block',
    'group-block',
    `${layout}-layout`,
    `${alignment}-align`,
    `${verticalAlignment}-valign`,
  ])
  const {actions, node} = useNode((n: Node) => {
    return {
      node: n,
    }
  })

  useEffect(() => {
    if (props.isColumn) {
      actions.setCustom((custom: any) => {
        custom.displayName = I18n.t('Column')
      })
    }
  }, [actions, props.isColumn])

  useEffect(() => {
    if (resizable !== node.data.custom.isResizable) {
      actions.setCustom((custom: Object) => {
        // @ts-expect-error
        custom.isResizable = resizable
      })
    }
  }, [actions, node.data.custom.isResizable, resizable])

  const styl: React.CSSProperties = {}
  if (node.data.props.width) {
    styl.width = `${node.data.props.width}px`
  }
  if (node.data.props.height) {
    styl.height = `${node.data.props.height}px`
  }

  return (
    <Container className={clazz} id={`group-${node.id}`} style={styl}>
      <Element id="group__inner" is={NoSections} canvas={true} className="group-block__inner" />
    </Container>
  )
}

GroupBlock.craft = {
  displayName: I18n.t('Group'),
  defaultProps: {
    alignment: 'start',
    verticalAlignment: 'start',
    layout: 'column',
    resizable: true,
  },
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      return !incomingNodes.some(
        (incomingNode: Node) =>
          incomingNode.data.custom.isSection || incomingNode.data.name === 'GroupBlock'
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
          return !isNthChild(nodeId, query, 1)
        }
      }
      return false
    },
    isResizable: true,
    isBlock: true,
    isExpanded: false,
  },
}
