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
import {useNode} from '@craftjs/core'
import {ColorPicker} from '@instructure/ui-color-picker'
import {View} from '@instructure/ui-view'

const ContainerSettings = () => {
  const {
    background,
    actions: {setProp},
  } = useNode(node => ({
    background: node.data.props.background,
  }))

  const handleColorChange = useCallback(
    (value: string) => {
      setProp((props: any) => (props.background = value))
    },
    [setProp]
  )

  return (
    <View as="div" maxWidth="235px">
      <ColorPicker
        label="Custom Color"
        tooltip="Set the button's background color"
        placeholderText="Enter HEX"
        popoverButtonScreenReaderLabel="Open color mixer"
        withAlpha={true}
        colorMixerSettings={{
          popoverAddButtonLabel: 'Set',
          popoverCloseButtonLabel: 'Cancel',
          colorMixer: {
            withAlpha: false,
            rgbRedInputScreenReaderLabel: 'Input field for red',
            rgbGreenInputScreenReaderLabel: 'Input field for green',
            rgbBlueInputScreenReaderLabel: 'Input field for blue',
            rgbAlphaInputScreenReaderLabel: 'Input field for alpha',
            colorSliderNavigationExplanationScreenReaderLabel: `You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
            alphaSliderNavigationExplanationScreenReaderLabel: `You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
            colorPaletteNavigationExplanationScreenReaderLabel: `You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively`,
          },
          colorPreset: {
            label: 'Choose a nice color',
            colors: [
              '#ffffff',
              '#0CBF94',
              '#0C89BF00',
              '#BF0C6D',
              '#BF8D0C',
              '#ff0000',
              '#576A66',
              '#35423A',
              '#35423F',
            ],
          },
        }}
        onChange={handleColorChange}
        value={background}
      />
    </View>
  )
}

export {ContainerSettings}
