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

import React from 'react'
import {render, screen, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DifferentiationTagSearch from '../DifferentiationTagSearch'

describe('DifferentiationTagSearch', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.runOnlyPendingTimers()
    jest.useRealTimers()
  })

  it('renders the text input with the correct placeholder', () => {
    const onSearchMock = jest.fn()
    render(<DifferentiationTagSearch onSearch={onSearchMock} />)
    const inputElement = screen.getByPlaceholderText('Search for Tag')
    expect(inputElement).toBeInTheDocument()
  })

  it('calls onSearch with the updated input value after the debounce delay', async () => {
    const user = userEvent.setup({delay: null})
    const onSearchMock = jest.fn()
    render(<DifferentiationTagSearch onSearch={onSearchMock} delay={100} />)
    const inputElement = screen.getByPlaceholderText('Search for Tag')

    await user.type(inputElement, 'hello')

    // onSearch should not be called immediately due to debounce
    expect(onSearchMock).not.toHaveBeenCalled()

    act(() => {
      jest.advanceTimersByTime(100)
    })

    expect(onSearchMock).toHaveBeenCalledWith('hello')
  })

  it('cancels the debounced onSearch call on unmount', async () => {
    const user = userEvent.setup({delay: null})
    const onSearchMock = jest.fn()
    const {unmount} = render(<DifferentiationTagSearch onSearch={onSearchMock} delay={200} />)
    const inputElement = screen.getByPlaceholderText('Search for Tag')

    await user.type(inputElement, 'cancel')

    // Unmount the component before the debounce delay has passed
    unmount()

    act(() => {
      jest.advanceTimersByTime(200)
    })

    expect(onSearchMock).not.toHaveBeenCalled()
  })
})
