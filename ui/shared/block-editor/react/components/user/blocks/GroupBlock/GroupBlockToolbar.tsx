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

import React, {useCallback} from 'react'
import {useNode, type Node} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {
  type GroupLayout,
  type GroupAlignment,
  type GroupHorizontalAlignment,
  type GroupBlockProps,
} from './types'
import {ToolbarColor, type ColorSpec} from '../../common/ToolbarColor'
import {ToolbarAlignment} from './toolbar/ToolbarAlignment'
import {ToolbarCorners} from './toolbar/ToolbarCorners'
import {getEffectiveBackgroundColor} from '@canvas/block-editor/react/utils'

export const GroupBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props,
  }))

  const handleChangeColors = useCallback(
    ({bgcolor, bordercolor}: ColorSpec) => {
      setProp((prps: GroupBlockProps) => {
        prps.background = bgcolor
        prps.borderColor = bordercolor
      })
    },
    [setProp],
  )

  const handleSaveAlignment = useCallback(
    (
      layout: GroupLayout,
      alignment: GroupHorizontalAlignment,
      verticalAlignment: GroupAlignment,
    ) => {
      setProp((prps: GroupBlockProps) => {
        prps.layout = layout
        prps.alignment = alignment
        prps.verticalAlignment = verticalAlignment
      })
    },
    [setProp],
  )

  const handleSaveCorners = useCallback(
    (rounded: boolean) => {
      setProp((prps: GroupBlockProps) => {
        prps.roundedCorners = rounded
      })
    },
    [setProp],
  )

  const getCurrentBorderColor = () => {
    return props.borderColor || '#00000000'
  }

  const getCurrentBackgroundColor = () => {
    return props.background || '#00000000'
  }

  return (
    <Flex gap="small">
      <ToolbarColor
        tabs={{
          background: {
            color: getCurrentBackgroundColor(),
            default: '#00000000',
          },
          border: {
            color: getCurrentBorderColor(),
            default: '#00000000',
          },
          effectiveBgColor: getEffectiveBackgroundColor(node.dom),
        }}
        onChange={handleChangeColors}
      />

      <ToolbarCorners rounded={props.roundedCorners} onSave={handleSaveCorners} />

      <ToolbarAlignment
        layout={props.layout}
        alignment={props.alignment}
        verticalAlignment={props.verticalAlignment}
        onSave={handleSaveAlignment}
      />
    </Flex>
  )
}
