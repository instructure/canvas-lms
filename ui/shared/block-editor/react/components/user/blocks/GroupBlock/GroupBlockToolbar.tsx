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
import {type GroupLayout, type GroupAlignment, type GroupBlockProps} from './types'
import {ToolbarColor} from '../../common/ToolbarColor'
import {ToolbarAlignment} from './toolbar/ToolbarAlignment'
import {useScope} from '@canvas/i18n'

const I18n = useScope('block-editor')

export const GroupBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode((node: Node) => ({
    props: node.data.props,
  }))

  const handleChangeColors = useCallback(
    (fgcolor: string, bgcolor: string) => {
      setProp((prps: GroupBlockProps) => {
        prps.color = fgcolor
        prps.background = bgcolor
      })
    },
    [setProp]
  )

  const handleSaveAlignment = useCallback(
    (layout: GroupLayout, alignment: GroupAlignment, verticalAlignment: GroupAlignment) => {
      setProp((prps: GroupBlockProps) => {
        prps.layout = layout
        prps.alignment = alignment
        prps.verticalAlignment = verticalAlignment
      })
    },
    [setProp]
  )

  const getCurrentColor = () => {
    if (props.color) return props.color
    return window
      .getComputedStyle(document.documentElement)
      .getPropertyValue('--ic-brand-font-color-dark')
  }

  const getCurrentBackgroundColor = () => {
    return props.background || '#00000000'
  }

  return (
    <Flex gap="small">
      <ToolbarColor
        fgcolorLabel={I18n.t('Group Color')}
        bgcolorLabel={I18n.t('Group Background')}
        fgcolor={getCurrentColor()}
        bgcolor={getCurrentBackgroundColor()}
        onChange={handleChangeColors}
      />

      <ToolbarAlignment
        layout={props.layout}
        alignment={props.alignment}
        verticalAlignment={props.verticalAlignment}
        onSave={handleSaveAlignment}
      />
    </Flex>
  )
}
