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
import tinycolor from 'tinycolor2'
import {ColorIndicator, ColorMixer, ColorPreset} from '@instructure/ui-color-picker'
import {FormFieldGroup, type FormMessage} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput, type TextInputOwnProps} from '@instructure/ui-text-input'

type ColorPickerProps = {
  label: React.ReactNode
  disabled: boolean
  value: string
  onChange: (color: string) => void
}
const ColorPicker = ({label, disabled, value, onChange}: ColorPickerProps) => {
  const [typedColor, setTypedColor] = useState<string>(value)
  const [hexColor, setHexColor] = useState<string>(value)
  const [messages, setMessages] = useState<FormMessage[]>([])

  const setValidColor = useCallback(
    newcolor => {
      setTypedColor(newcolor)
      setHexColor(newcolor)
      setMessages([])
      onChange(newcolor)
    },
    [onChange]
  )

  const handleTextChange = useCallback(
    (_event: React.ChangeEvent<HTMLInputElement>, typedvalue: string) => {
      setTypedColor(typedvalue)
      const color = tinycolor(typedvalue)
      if (color.isValid(typedvalue)) {
        setMessages([{text: 'Hit enter to set this color', type: 'hint'}])
      } else {
        setMessages([{text: 'Not a valid color', type: 'error'}])
      }
    },
    []
  )

  const handleHexKey = useCallback(
    (event: React.KeyboardEvent<TextInputOwnProps>) => {
      if (event.key === 'Enter') {
        const color = tinycolor(typedColor)
        if (color.isValid(typedColor)) {
          const hex = color.toHex()
          setValidColor(hex)
        }
      }
    },
    [setValidColor, typedColor]
  )

  const handleColorChange = useCallback(
    (newcolor: string) => {
      setValidColor(newcolor)
    },
    [setValidColor]
  )

  return (
    <FormFieldGroup layout="stacked" description={label} rowSpacing="small">
      <TextInput
        renderLabel={<ScreenReaderContent>Custom color</ScreenReaderContent>}
        interaction={disabled ? 'disabled' : 'enabled'}
        value={typedColor}
        messages={messages}
        renderAfterInput={<ColorIndicator color={hexColor} />}
        width="12rem"
        onChange={handleTextChange}
        onKeyDown={handleHexKey}
      />
      <ColorPreset
        label="Choose a color"
        disabled={disabled}
        colors={[
          '#ffffff',
          '#0CBF94',
          '#0C89BF00',
          '#BF0C6D',
          '#BF8D0C',
          '#ff0000',
          '#576A66',
          '#35423A',
          '#35423F',
        ]}
        onSelect={handleColorChange}
      />
      <ColorMixer
        withAlpha={true}
        disabled={disabled}
        value={hexColor}
        onChange={handleColorChange}
        rgbRedInputScreenReaderLabel="Input field for red"
        rgbGreenInputScreenReaderLabel="Input field for green"
        rgbBlueInputScreenReaderLabel="Input field for blue"
        rgbAlphaInputScreenReaderLabel="Input field for alpha"
        colorSliderNavigationExplanationScreenReaderLabel={`You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`}
        alphaSliderNavigationExplanationScreenReaderLabel={`You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`}
        colorPaletteNavigationExplanationScreenReaderLabel={`You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively`}
      />
    </FormFieldGroup>
  )
}

export {ColorPicker}
