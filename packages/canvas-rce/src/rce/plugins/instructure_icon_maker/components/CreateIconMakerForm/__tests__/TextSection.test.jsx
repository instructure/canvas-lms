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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {TextSection} from '../TextSection'

const selectOption = async (button, option) => {
  await userEvent.click(
    screen.getByRole('combobox', {
      name: button,
    })
  )
  await userEvent.click(
    screen.getByRole('option', {
      name: option,
    })
  )
}

describe('<TextSection />', () => {
  it('changes the icon text', async () => {
    const onChange = jest.fn()
    const {container} = render(<TextSection settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = container.querySelector('#icon-text')
    fireEvent.change(input, {target: {value: 'Hello World!'}})

    await waitFor(() => expect(onChange).toHaveBeenCalledWith({text: 'Hello World!'}))
  })

  it("doesn't change the icon text when reaches the limit when typing", async () => {
    const onChange = jest.fn()
    const {container} = render(
      <TextSection
        settings={{...DEFAULT_SETTINGS, text: 'Hello World!Hello World!Hello!12'}}
        onChange={onChange}
      />
    )
    const input = container.querySelector('#icon-text')
    fireEvent.change(input, {target: {value: 'Hello World!Hello World!Hello!123'}})

    await waitFor(() => expect(onChange).not.toHaveBeenCalled())
  })

  it("doesn't change the icon text when reaches the limit when pasting", async () => {
    const onChange = jest.fn()
    const {container} = render(
      <TextSection settings={{...DEFAULT_SETTINGS, text: 'Hello World!'}} onChange={onChange} />
    )
    const input = container.querySelector('#icon-text')
    fireEvent.change(input, {
      target: {value: 'Hello World!Hello World!Hello World!Hello World!Hello World!'},
    })

    await waitFor(() =>
      expect(onChange).toHaveBeenCalledWith({text: 'Hello World!Hello World!Hello Wo'})
    )
  })

  it('changes the icon text size', async () => {
    const onChange = jest.fn()
    render(<TextSection settings={{...DEFAULT_SETTINGS}} onChange={onChange} />)
    await selectOption(/text size/i, /medium/i)
    expect(onChange).toHaveBeenCalledWith({textSize: 'medium'})
  })

  it('changes the icon text color', () => {
    const onChange = jest.fn()
    render(<TextSection settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = screen.getByRole('textbox', {name: /text color/i})
    fireEvent.change(input, {target: {value: '#f00'}})
    expect(onChange).toHaveBeenCalledWith({textColor: '#f00'})
  })

  it('changes the icon text background color', () => {
    const onChange = jest.fn()
    render(<TextSection settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = screen.getByRole('textbox', {name: /text background color/i})
    fireEvent.change(input, {target: {value: '#0f0'}})
    expect(onChange).toHaveBeenCalledWith({textBackgroundColor: '#0f0'})
  })

  it('changes the icon text position', async () => {
    const onChange = jest.fn()
    render(<TextSection settings={{...DEFAULT_SETTINGS}} onChange={onChange} />)
    await selectOption(/text position/i, /bottom third/i)
    expect(onChange).toHaveBeenCalledWith({textPosition: 'bottom-third'})
  })
})
