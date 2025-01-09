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
import React, {
  forwardRef,
  type ForwardRefExoticComponent,
  type RefAttributes,
  type CSSProperties,
} from 'react'
import {useNode, type Node} from '@craftjs/core'
import {type ContainerProps} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type ContainerCraft = {
  displayName: string
  defaultProps: {
    className: string
    background: string
    style: CSSProperties
  }
}

interface ForwardRefContainerComponent
  extends ForwardRefExoticComponent<ContainerProps & RefAttributes<HTMLElement>> {
  craft: ContainerCraft
}
const Container = forwardRef<HTMLElement, ContainerProps>(
  (
    {id, className, background, style, onKeyDown, children, ...rest}: ContainerProps,
    ref: React.Ref<HTMLElement | null>,
  ) => {
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
        data-testid="container-block"
        data-placeholder={rest['data-placeholder'] || 'Drop blocks here'}
        ref={el => {
          if (el) connect(drag(el))
          if (typeof ref === 'function') ref(el)
          else if (ref) (ref as React.MutableRefObject<HTMLElement | null>).current = el
        }}
        style={{
          backgroundColor: background || Container.craft.defaultProps.background,
          ...style,
        }}
        tabIndex={-1}
        onKeyDown={onKeyDown}
      >
        {children}
      </div>
    )
  },
) as ForwardRefContainerComponent

Container.craft = {
  displayName: I18n.t('Container'),
  defaultProps: {
    className: '',
    background: 'transparent',
    style: {},
  },
}

export {Container}
