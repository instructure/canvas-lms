/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {useNode} from '@craftjs/core'
import {ButtonBlockIndividualButtonSettings} from './ButtonBlockIndividualButtonSettings'
import {ButtonBlockGeneralButtonSettings} from './ButtonBlockGeneralButtonSettings'
import {ButtonBlockProps, ButtonData, ButtonAlignment, ButtonLayout} from './ButtonBlock'

export const ButtonBlockSettings = () => {
  const {
    actions: {setProp},
    alignment,
    layout,
    isFullWidth,
    buttons,
  } = useNode(node => ({
    alignment: node.data.props.settings.alignment,
    layout: node.data.props.settings.layout,
    isFullWidth: node.data.props.settings.isFullWidth,
    buttons: node.data.props.settings.buttons,
  }))

  const handleAlignmentChange = (alignment: ButtonAlignment) => {
    setProp((props: ButtonBlockProps) => {
      props.settings.alignment = alignment
    })
  }

  const handleLayoutChange = (layout: ButtonLayout) => {
    setProp((props: ButtonBlockProps) => {
      props.settings.layout = layout
    })
  }

  const handleIsFullWidthChange = (isFullWidth: boolean) => {
    setProp((props: ButtonBlockProps) => {
      props.settings.isFullWidth = isFullWidth
    })
  }

  const handleButtonsChange = (buttons: ButtonData[]) => {
    setProp((props: ButtonBlockProps) => {
      props.settings.buttons = buttons
    })
  }

  return (
    <View as="div">
      <ButtonBlockGeneralButtonSettings
        alignment={alignment}
        layout={layout}
        isFullWidth={isFullWidth}
        onAlignmentChange={handleAlignmentChange}
        onLayoutChange={handleLayoutChange}
        onIsFullWidthChange={handleIsFullWidthChange}
      />

      <ButtonBlockIndividualButtonSettings
        initialButtons={buttons}
        onButtonsChange={handleButtonsChange}
      />
    </View>
  )
}
