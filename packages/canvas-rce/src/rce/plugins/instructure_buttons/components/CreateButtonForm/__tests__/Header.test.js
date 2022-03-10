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
  it('changes the button name', async () => {
    const onChange = jest.fn()
    render(<Header settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = document.querySelector('#button-name')
    fireEvent.change(input, {target: {value: 'A b&i name'}})

    await waitFor(() => expect(onChange).toHaveBeenCalledWith({name: 'A b&i name'}))
  })

  it('changes the button alt text', async () => {
    const onChange = jest.fn()
    render(<Header settings={DEFAULT_SETTINGS} onChange={onChange} />)
    const input = document.querySelector('#button-alt-text')
    fireEvent.change(input, {target: {value: 'A descriptive text'}})

    await waitFor(() => expect(onChange).toHaveBeenCalledWith({alt: 'A descriptive text'}))
  })

  describe('when the name contains html entities', () => {
    let settings

    const subject = () => render(<Header settings={settings} onChange={() => {}} />)

    beforeEach(() => (settings = {...DEFAULT_SETTINGS, name: 'Button &amp; Icon'}))

    it('decodes the html entities', () => {
      const {getByTestId} = subject()
      expect(getByTestId('button-name').value).toEqual('Button & Icon')
    })
  })
})
