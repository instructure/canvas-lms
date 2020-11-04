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
import ColorPicker from '../ColorPicker'
import $ from 'jquery'

describe('ColorPicker', () => {
  function renderColorPicker(props) {
    const container = document.createElement('div')
    container.setAttribute('id', 'container')

    return render(
      <ColorPicker
        isOpen
        nonModal
        parentComponent="container"
        positions={{top: 0, left: 0}}
        {...props}
      />,
      container
    )
  }

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
    const {getByLabelText} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByLabelText('Enter a hexcode here to use a custom color.')
    expect(textInput).toBeInTheDocument()
    expect(textInput.value).toEqual('#ff0000')
  })

  it('shows warning icon if custom color is not a valid hexcode', () => {
    const {getByLabelText} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByLabelText('Enter a hexcode here to use a custom color.')
    fireEvent.change(textInput, {target: {value: '#00ff0q'}})
    const warningIcon = document.getElementById('ColorPicker__InvalidHex')
    expect(warningIcon).toBeInTheDocument()
  })

  it('disables Apply button if custom color is invalid', () => {
    const {getByText} = renderColorPicker({currentColor: '#0e355aa'})
    const applyButton = getByText('Apply')
    expect(applyButton).toBeInTheDocument()
    expect(applyButton).toBeDisabled()
  })

  it('enables Apply button once valid hex is entered', () => {
    const {getByText, getByLabelText} = renderColorPicker({currentColor: '#00000'})
    const applyButton = getByText('Apply')
    const textInput = getByLabelText(
      'Invalid hexcode. Enter a valid hexcode here to use a custom color.'
    )
    fireEvent.change(textInput, {target: {value: '#00000c'}})
    expect(applyButton).toBeEnabled()
  })

  it('shows a screenReaderFlashMessage when leaving input if hex is invalid', () => {
    const {getByLabelText} = renderColorPicker({currentColor: '#ff0000'})
    const textInput = getByLabelText('Enter a hexcode here to use a custom color.')
    $.screenReaderFlashMessage = jest.fn()
    fireEvent.change(textInput, {target: {value: '#hi'}})
    fireEvent.blur(textInput)
    expect($.screenReaderFlashMessage).toHaveBeenCalledWith(
      "'#hi' is not a valid color. Enter a valid hexcode before saving."
    )
  })
})
