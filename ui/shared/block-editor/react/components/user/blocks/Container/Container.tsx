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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames} from '../../../../utils'
import {type ContainerProps} from './types'

export const Container = ({
  id,
  className,
  background,
  style,
  children,
  ...rest
}: ContainerProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  const clazz = useClassNames(enabled, {empty: !children}, [
    'container-block',
    className || Container.craft.defaultProps.className,
  ])

  return (
    <div
      id={id || `container-${node.id}`}
      className={clazz}
      data-placeholder={rest['data-placeholder'] || 'Drop blocks here'}
      ref={el => el && connect(drag(el))}
      style={{
        background: background || Container.craft.defaultProps.background,
        ...style,
      }}
    >
      {children}
    </div>
  )
}

Container.craft = {
  displayName: 'Container',
  defaultProps: {
    className: '',
    background: 'transparent',
    style: {},
  },
}
