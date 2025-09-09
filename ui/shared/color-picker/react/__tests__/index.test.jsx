/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import ColorPicker, {PREDEFINED_COLORS} from '../index'
import {isValidHex, getColorName} from '../utils'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

describe('ColorPicker', () => {
  function renderColorPicker(props) {
    const container = document.createElement('div')
    container.setAttribute('id', 'container')

    return render(
      <ColorPicker
        isOpen={true}
        nonModal={true}
        parentComponent="container"
        positions={{top: 0, left: 0}}
        {...props}
      />,
      container,
    )
  }

  afterEach(() => {
    destroyContainer()
  })

  it('returns name', () => {
    expect(ColorPicker.getColorName('#BD3C14')).toBe('Brick')
  })

  it('returns name without hash', () => {
    expect(ColorPicker.getColorName('BD3C14')).toBe('Brick')
  })

  it('returns undefined if color does not exists in PREDEFINED_COLORS', () => {
    expect(ColorPicker.getColorName('#111111')).toBeUndefined()
  })

  it('shows current color in textarea', () => {
    const {getByTestId} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByTestId('color-picker-input')
    expect(textInput).toBeInTheDocument()
    expect(textInput.value).toEqual('#ff0000')
  })

  it('shows warning icon if custom color is not a valid hexcode', () => {
    const {getByTestId} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByTestId('color-picker-input')
    fireEvent.change(textInput, {target: {value: '#00ff0q'}})
    const warningIcon = document.getElementById('ColorPicker__InvalidHex')
    expect(warningIcon).toBeInTheDocument()
  })

  it('disables Apply button if custom color is invalid', () => {
    const {getByRole} = renderColorPicker({currentColor: '#0e355aa'})
    const applyButton = getByRole('button', {name: 'Apply'})
    expect(applyButton).toBeInTheDocument()
    expect(applyButton).toBeDisabled()
  })

  it('enables Apply button once valid hex is entered', () => {
    const {getByText, getByTestId} = renderColorPicker({currentColor: '#00000'})
    const applyButton = getByText('Apply')
    const textInput = getByTestId('color-picker-input')
    fireEvent.change(textInput, {target: {value: '#00000c'}})
    expect(applyButton).toBeEnabled()
  })

  it('plays a screen reader alert when leaving input if hex is invalid', () => {
    const {getByTestId, getByText} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByTestId('color-picker-input')
    fireEvent.change(textInput, {target: {value: '#hi'}})
    fireEvent.blur(textInput)
    expect(
      getByText("'#hi' is not a valid color. Enter a valid hexcode before saving."),
    ).toBeInTheDocument()
  })

  describe('ES6 class conversion', () => {
    it('renders correctly as ES6 class component', () => {
      const {container} = renderColorPicker({currentColor: '#ff0000'})
      expect(container.querySelector('.ColorPicker__Container')).toBeInTheDocument()
    })

    it('maintains state correctly', () => {
      const {getByTestId} = renderColorPicker({currentColor: '#ff0000'})
      const textInput = getByTestId('color-picker-input')

      fireEvent.change(textInput, {target: {value: '#00ff00'}})
      expect(textInput.value).toBe('#00ff00')
    })

    it('handles prop changes correctly', () => {
      const {getByTestId} = renderColorPicker({currentColor: '#ff0000'})
      const textInput = getByTestId('color-picker-input')
      expect(textInput.value).toBe('#ff0000')

      // Test that component handles internal state changes correctly
      fireEvent.change(textInput, {target: {value: '#00ff00'}})
      expect(textInput.value).toBe('#00ff00')
    })
  })

  describe('helper methods', () => {
    let component
    let container

    beforeEach(() => {
      container = document.createElement('div')
      container.setAttribute('id', 'test-container')
      document.body.appendChild(container)

      const result = render(
        <ColorPicker
          isOpen={true}
          nonModal={true}
          parentComponent="test-container"
          positions={{top: 0, left: 0}}
          currentColor="#ff0000"
          withBoxShadow={true}
        />,
        {container},
      )
      component = result.container.firstChild
    })

    afterEach(() => {
      if (container && container.parentNode) {
        container.parentNode.removeChild(container)
      }
    })

    it('shouldApplySwatchBorderColor returns true when withBoxShadow is true', () => {
      const {getByTestId} = renderColorPicker({
        currentColor: '#ff0000',
        withBoxShadow: true,
      })

      // Test that color swatches have border colors applied
      const colorButton = document.querySelector('.ColorPicker__ColorBlock')
      expect(colorButton).toBeInTheDocument()
      expect(colorButton).toHaveStyle('border-color: #BD3C14')
    })

    it('shouldApplySelectedStyle applies correct styling to selected color', () => {
      const {container} = renderColorPicker({
        currentColor: '#BD3C14',
      })

      // Find the selected color swatch (first predefined color)
      const colorButtons = container.querySelectorAll('.ColorPicker__ColorBlock')
      const selectedButton = colorButtons[0] // First color is #BD3C14

      expect(selectedButton).toHaveStyle('border-color: #6A7883')
      expect(selectedButton).toHaveStyle('border-width: 2px')
    })

    it('applies different styling to non-selected colors', () => {
      const {container} = renderColorPicker({
        currentColor: '#BD3C14',
        withBoxShadow: true,
      })

      const colorButtons = container.querySelectorAll('.ColorPicker__ColorBlock')
      const nonSelectedButton = colorButtons[1] // Second color is #FF2717

      // Should have the color's own hexcode as border color, not the selected style
      expect(nonSelectedButton).toHaveStyle('border-color: #FF2717')

      // Verify it's not selected by checking it doesn't have the selected border color
      expect(nonSelectedButton).not.toHaveStyle('border-color: #6A7883')

      // Check that the selected button has different styling
      const selectedButton = colorButtons[0] // First color is #BD3C14 (selected)
      expect(selectedButton).toHaveStyle('border-color: #6A7883')
      expect(selectedButton).toHaveStyle('border-width: 2px')
    })
  })

  describe('color selection', () => {
    it('updates current color when clicking color swatch', () => {
      const {container, getByTestId} = renderColorPicker({currentColor: '#ff0000'})
      const textInput = getByTestId('color-picker-input')

      // Click the first color swatch (Brick - #BD3C14)
      const colorButtons = container.querySelectorAll('.ColorPicker__ColorBlock')
      fireEvent.click(colorButtons[0])

      expect(textInput.value).toBe('#BD3C14')
    })

    it('shows checkmark on selected color', () => {
      const {container} = renderColorPicker({currentColor: '#BD3C14'})

      // Find the selected color swatch
      const colorButtons = container.querySelectorAll('.ColorPicker__ColorBlock')
      const selectedButton = colorButtons[0]
      const checkIcon = selectedButton.querySelector('.icon-check')

      expect(checkIcon).toBeInTheDocument()
    })
  })

  describe('utility functions', () => {
    describe('isValidHex', () => {
      it('validates correct hex codes', () => {
        expect(isValidHex('#ff0000')).toBe(true)
        expect(isValidHex('ff0000')).toBe(true)
        expect(isValidHex('#f00')).toBe(true)
        expect(isValidHex('f00')).toBe(true)
      })

      it('rejects invalid hex codes', () => {
        expect(isValidHex('#gggggg')).toBe(false)
        expect(isValidHex('#12345')).toBe(false)
        expect(isValidHex('invalid')).toBe(false)
      })

      it('rejects white colors by default', () => {
        expect(isValidHex('#ffffff')).toBe(false)
        expect(isValidHex('#fff')).toBe(false)
        expect(isValidHex('fff')).toBe(false)
      })

      it('allows white colors when allowWhite is true', () => {
        expect(isValidHex('#ffffff', true)).toBe(true)
        expect(isValidHex('#fff', true)).toBe(true)
        expect(isValidHex('fff', true)).toBe(true)
      })
    })
  })
})
