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

import {Container} from '../../blocks/Container'
import {ColumnsSectionToolbar} from './ColumnsSectionToolbar'
import {useClassNames, getContrastingColor} from '../../../../utils'
import {GroupBlock} from '../../blocks/GroupBlock'
import {type ColumnsSectionProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export type ColumnsSectionInnerProps = {
  children?: React.ReactNode
}

export const ColumnsSectionInner = ({children}: ColumnsSectionInnerProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, ['columns-section__inner'])

  return (
    <div ref={el => el && connect(el)} className={clazz} data-placeholder="Drop Groups here">
      {children}
    </div>
  )
}

ColumnsSectionInner.craft = {
  displayName: 'Columns Inner',
  rules: {
    canMoveIn: (incomingNodes: Node[]) =>
      incomingNodes.every(incomingNode => incomingNode.data.type === GroupBlock),
    canMoveOut: (outgoingNodes: Node[], currentNode: Node) => {
      return currentNode.data.nodes.length > outgoingNodes.length
    },
  },
  custom: {
    noToolbar: true,
  },
}

export const ColumnsSection = ({background, columns}: ColumnsSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const clazz = useClassNames(enabled, {empty: false}, [
    'section',
    'columns-section',
    `columns-${columns}`,
  ])

  // To me, it this makes more sense than to handle adding GroupBlock columns
  // in the toolbar, but from here it triggers a React warning about updating
  // a component while rendering it.
  // Interesting that it does not happen when building against the craft.js dev build.
  //
  // useEffect(() => {
  //   const innerid = query.node(node.id).linkedNodes()[0]
  //   const inner = query.node(innerid).get()

  //   const missingCols = columns - inner.data.nodes.length
  //   if (missingCols > 0) {
  //     for (let i = 0; i < missingCols; i++) {
  //       requestAnimationFrame(() => {
  //         const column = query
  //           .parseReactElement(<GroupBlock resizable={false} isColumn={true} />)
  //           .toNodeTree()
  //         actions.addNodeTree(column, inner.id)
  //       })
  //     }
  //   }
  // }, [actions, columns, node.id, query])

  const renderColumns = () => {
    const cols = []
    for (let i = 0; i < columns; i++) {
      cols.push(<GroupBlock key={i} resizable={false} isColumn={true} />)
    }
    return cols
  }

  const styl: React.CSSProperties = {}
  if (background) {
    styl.backgroundColor = background
    styl.color = getContrastingColor(background)
  } else {
    styl.backgroundColor = 'transparent'
  }

  return (
    <Container className={clazz} style={styl}>
      <Element id="columns__inner" is={ColumnsSectionInner} canvas={true}>
        {renderColumns()}
      </Element>
    </Container>
  )
}

ColumnsSection.craft = {
  displayName: I18n.t('Columns'),
  defaultProps: {
    columns: 1,
  },
  rules: {
    // canMoveIn: (nodes: Node[]) => !nodes.some(node => node.data.custom.isSection || node.data.name !== 'GroupBlock'),
    canMoveIn: () => false,
  },
  custom: {
    isSection: true,
  },
  related: {
    toolbar: ColumnsSectionToolbar,
  },
}
