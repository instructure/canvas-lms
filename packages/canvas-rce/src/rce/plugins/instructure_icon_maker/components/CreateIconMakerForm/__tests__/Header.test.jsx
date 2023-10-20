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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {Header} from '../Header'

describe('<Header />', () => {
  it('changes the icon name', async () => {
    const onChange = jest.fn()
    render(<Header settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = document.querySelector('#icon-name')
    fireEvent.change(input, {target: {value: 'An IM name'}})

    await waitFor(() => expect(onChange).toHaveBeenCalledWith({name: 'An IM name'}))
  })

  it('changes the icon alt text', async () => {
    const onChange = jest.fn()
    render(<Header settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = document.querySelector('#icon-alt-text')
    fireEvent.change(input, {target: {value: 'A descriptive text'}})

    await waitFor(() => expect(onChange).toHaveBeenCalledWith({alt: 'A descriptive text'}))
  })

  describe('when the decorative icon box is checked', () => {
    it('changes the icon isDecorative field', async () => {
      const onChange = jest.fn()
      const {getByRole} = render(<Header settings={DEFAULT_SETTINGS} onChange={onChange} />)
      const checkBox = getByRole('checkbox', {name: /Decorative Icon/})
      fireEvent.click(checkBox)
      await waitFor(() => expect(onChange).toHaveBeenCalledWith({isDecorative: true}))
    })
  })

  describe('when the isDecorative setting is true', () => {
    let settings

    beforeAll(() => (settings = {...DEFAULT_SETTINGS, isDecorative: true}))

    it('disables the alt text input', () => {
      const header = <Header settings={settings} onChange={jest.fn()} />
      const {container} = render(header)
      const textArea = container.querySelector('#icon-alt-text')
      expect(textArea).toBeDisabled()
    })
  })

  describe('when the name contains html entities', () => {
    let settings

    const subject = () => render(<Header settings={settings} onChange={() => {}} />)

    beforeEach(() => (settings = {...DEFAULT_SETTINGS, name: 'Icon &amp; Maker'}))

    it('decodes the html entities', () => {
      const {getByTestId} = subject()
      expect(getByTestId('icon-name').value).toEqual('Icon & Maker')
    })
  })
})
