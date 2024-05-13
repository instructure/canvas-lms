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

import React, {useCallback, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {ColorPicker} from '@instructure/ui-color-picker'
import {View} from '@instructure/ui-view'
import {isInstuiButtonColor} from './common'

type LinkModalProps = {
  open: boolean
  color: string
  onClose: () => void
  onSubmit: (color: string) => void
}

const ColorModal = ({open, color, onClose, onSubmit}: LinkModalProps) => {
  const [currColor, setCurrColor] = useState(color)

  const handleColorChange = useCallback((newColor: string) => {
    setCurrColor(newColor)
  }, [])

  const handleButtonColorChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      handleColorChange(value)
    },
    [handleColorChange]
  )

  const handleSubmit = useCallback(() => {
    onSubmit(currColor)
    onClose()
  }, [onSubmit, currColor, onClose])

  return (
    <Modal open={open} onDismiss={onClose} label="Link" size="medium">
      <Modal.Header>
        <Heading level="h2">Select an Button Color</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium">
        <View as="div" margin="small">
          <RadioInputGroup
            name="color"
            defaultValue={isInstuiButtonColor(currColor) ? currColor : 'custom'}
            description="Color"
            onChange={handleButtonColorChange}
          >
            <RadioInput value="primary" label="Primary" />
            <RadioInput value="secondary" label="Secondary" />
            <RadioInput value="success" label="Success" />
            <RadioInput value="danger" label="Danger" />
            <RadioInput value="primary-inverse" label="Primary Inverse" />
            <RadioInput value="custom" label="Custom" />
          </RadioInputGroup>
        </View>

        {!isInstuiButtonColor(currColor) && (
          <View as="div" margin="small">
            <ColorPicker
              label="Custom Color"
              tooltip="Set the button's background color"
              placeholderText="Enter HEX"
              popoverButtonScreenReaderLabel="Open color mixer"
              withAlpha={false}
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
              value={currColor}
            />
          </View>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button color="primary" onClick={handleSubmit} margin="0 0 0 small">
          Submit
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {ColorModal}
