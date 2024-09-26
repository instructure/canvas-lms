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
import {useNode, type Node} from '@craftjs/core'
import {type ContainerProps} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

export const Container = ({
  id,
  className,
  background,
  style,
  onKeyDown,
  children,
  ...rest
}: ContainerProps) => {
  const {
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  return (
    <div
      role="treeitem"
      aria-label={node.data.displayName}
      aria-selected={node.events.selected}
      aria-expanded={!!node.data.custom?.isExpanded}
      id={id || `container-${node.id}`}
      className={`container-block ${className}`}
      data-placeholder={rest['data-placeholder'] || 'Drop blocks here'}
      ref={el => el && connect(drag(el))}
      style={{
        background: background || Container.craft.defaultProps.background,
        ...style,
      }}
      tabIndex={-1}
      onKeyDown={onKeyDown}
    >
      {children}
    </div>
  )
}

Container.craft = {
  displayName: I18n.t('Container'),
  defaultProps: {
    className: '',
    background: 'transparent',
    style: {},
  },
}
