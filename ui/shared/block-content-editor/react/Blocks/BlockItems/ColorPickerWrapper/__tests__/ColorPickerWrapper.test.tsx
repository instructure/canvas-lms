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

import {render} from '@testing-library/react'
import {ColorPickerWrapper} from '../ColorPickerWrapper'

const mockColorPicker = jest.fn()
jest.mock('@instructure/ui-color-picker', () => ({
  ColorPicker: (props: any) => mockColorPicker(props),
}))

describe('ColorPickerWrapper', () => {
  const defaultProps = {
    label: 'Test Color Picker',
    value: '#FF0000',
    baseColor: '#FFFFFF',
    onChange: jest.fn(),
    baseColorLabel: 'Background Color',
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('passes correct props to ColorPicker', () => {
    render(<ColorPickerWrapper {...defaultProps} />)

    expect(mockColorPicker).toHaveBeenCalledWith({
      label: 'Test Color Picker',
      placeholderText: 'Enter HEX',
      value: '#FF0000',
      onChange: defaultProps.onChange,
      withAlpha: true,
      colorMixerSettings: {
        popoverAddButtonLabel: 'Apply',
        popoverCloseButtonLabel: 'Close',
        colorContrast: {
          firstColor: '#FFFFFF',
          label: 'Contrast Ratio',
          successLabel: 'PASS',
          failureLabel: 'FAIL',
          normalTextLabel: 'Normal text',
          largeTextLabel: 'Large text',
          graphicsTextLabel: 'Graphics text',
          firstColorLabel: 'Background Color',
          secondColorLabel: 'Test Color Picker',
        },
        colorMixer: {
          withAlpha: true,
          rgbRedInputScreenReaderLabel: 'Input field for red',
          rgbGreenInputScreenReaderLabel: 'Input field for green',
          rgbBlueInputScreenReaderLabel: 'Input field for blue',
          rgbAlphaInputScreenReaderLabel: 'Input field for alpha',
          colorSliderNavigationExplanationScreenReaderLabel: `You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          alphaSliderNavigationExplanationScreenReaderLabel: `You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          colorPaletteNavigationExplanationScreenReaderLabel: `You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively`,
        },
      },
    })
  })

  it('calls onChange when ColorPicker onChange is triggered', () => {
    const mockOnChange = jest.fn()
    render(<ColorPickerWrapper {...defaultProps} onChange={mockOnChange} />)

    const colorPickerProps = mockColorPicker.mock.calls[0][0]
    colorPickerProps.onChange('#00FF00')

    expect(mockOnChange).toHaveBeenCalledWith('#00FF00')
  })

  it('uses different baseColor for contrast checking', () => {
    const propsWithDifferentBaseColor = {
      ...defaultProps,
      baseColor: '#000000',
    }

    render(<ColorPickerWrapper {...propsWithDifferentBaseColor} />)

    const colorPickerProps = mockColorPicker.mock.calls[0][0]
    expect(colorPickerProps.colorMixerSettings.colorContrast.firstColor).toBe('#000000')
  })

  it('uses custom baseColorLabel', () => {
    const propsWithCustomLabel = {
      ...defaultProps,
      baseColorLabel: 'Custom Base Label',
    }

    render(<ColorPickerWrapper {...propsWithCustomLabel} />)

    const colorPickerProps = mockColorPicker.mock.calls[0][0]
    expect(colorPickerProps.colorMixerSettings.colorContrast.firstColorLabel).toBe(
      'Custom Base Label',
    )
  })
})
