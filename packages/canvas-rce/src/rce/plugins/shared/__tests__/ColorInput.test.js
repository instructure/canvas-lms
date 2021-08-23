/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import {ColorInput} from '../ColorInput'

describe('<ColorInput />', () => {
  const defaults = {
    color: '#212121',
    onChange: jest.fn(),
    label: 'Some color input',
    name: 'some-color'
  }

  beforeEach(() => jest.clearAllMocks())

  it('renders the selected color preview', () => {
    render(<ColorInput {...defaults} />)
    const preview = screen.getByTestId(`colorPreview-${defaults.color}`)
    expect(preview.style.background).toBe('rgb(33, 33, 33)')
  })

  it('renders no background when no color is selected', () => {
    render(<ColorInput {...defaults} color={null} />)
    const preview = screen.getByTestId('colorPreview-null')
    // js dom does not support linear gradient yet
    expect(preview.style.background).toBe('')
  })

  it('changes the color by typing', () => {
    render(<ColorInput {...defaults} />)
    const input = screen.getByRole('textbox', {
      name: /some color input/i
    })
    fireEvent.change(input, {target: {value: ''}})
    expect(defaults.onChange).toHaveBeenCalledWith(null)
    fireEvent.change(input, {target: {value: '#fff'}})
    expect(defaults.onChange).toHaveBeenCalledWith('#fff')
  })

  it('changes the color using the predefined colors', () => {
    render(<ColorInput {...defaults} />)
    fireEvent.click(screen.getByText(/view predefined colors/i))
    fireEvent.click(screen.getByTestId('colorPreview-#06A3B7'))
    expect(defaults.onChange).toHaveBeenCalledWith('#06A3B7')
    fireEvent.click(screen.getByTestId('colorPreview-null'))
    expect(defaults.onChange).toHaveBeenCalledWith(null)
  })
})
