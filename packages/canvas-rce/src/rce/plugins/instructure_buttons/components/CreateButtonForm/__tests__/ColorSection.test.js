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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {ColorSection} from '../ColorSection'

function selectOption(button, option) {
  userEvent.click(
    screen.getByRole('button', {
      name: button
    })
  )
  userEvent.click(
    screen.getByRole('option', {
      name: option
    })
  )
}

describe('<ColorSection />', () => {
  it('changes the button color', () => {
    const onChange = jest.fn()
    render(<ColorSection settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = screen.getByRole('textbox', {name: /button color/i})
    fireEvent.change(input, {target: {value: '#fff'}})
    expect(onChange).toHaveBeenCalledWith({color: '#fff'})
  })

  it('changes the outline color', () => {
    const onChange = jest.fn()
    render(<ColorSection settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = screen.getByRole('textbox', {name: /button outline/i})
    fireEvent.change(input, {target: {value: '#000'}})
    expect(onChange).toHaveBeenCalledWith({outlineColor: '#000'})
  })

  it('changes the button outline size', () => {
    const onChange = jest.fn()
    render(
      <ColorSection settings={{...DEFAULT_SETTINGS, outlineSize: 'medium'}} onChange={onChange} />
    )
    selectOption(/button outline size/i, /small/i)
    expect(onChange).toHaveBeenCalledWith({outlineSize: 'small'})
    selectOption(/button outline size/i, /none/i)
    expect(onChange).toHaveBeenCalledWith({outlineSize: 'none'})
  })
})
