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
import {useClassNames} from '../../../../utils'
import {SectionMenu} from '../../../editor/SectionMenu'
import {GroupBlock} from '../../blocks/GroupBlock'
import {type ColumnsSectionProps} from './types'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/columns-section')

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
  displayName: 'Columns',
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

export const ColumnsSection = (_props: ColumnsSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {id, node} = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  const clazz = useClassNames(enabled, {empty: false}, [
    'section',
    'columns-section',
    `columns-${node.data.props.columns}`,
  ])

  return (
    <Container className={clazz}>
      <Element id={`columns-${id}__inner`} is={ColumnsSectionInner} canvas={true}>
        <Element id={`columns-${id}-1`} is={GroupBlock} canvas={true} resizable={false} />
        <Element id={`columns-${id}-2`} is={GroupBlock} canvas={true} resizable={false} />
      </Element>
    </Container>
  )
}

ColumnsSection.craft = {
  displayName: I18n.t('Blank Section'),
  defaultProps: {
    columns: 2,
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
    sectionMenu: SectionMenu,
  },
}
