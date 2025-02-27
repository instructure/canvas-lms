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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MemoryRouter, Route, Routes, useNavigate} from 'react-router-dom'
import SearchBar from '../SearchBar'

jest.useFakeTimers()

const navigateMock = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}))

const defaultProps = {
  initialValue: '',
}

const renderComponent = (props?: any) => {
  return render(
    <MemoryRouter
      initialEntries={[`/search?search_term=${props?.initialValue || defaultProps.initialValue}`]}
    >
      <Routes>
        <Route path="/" element={<SearchBar {...defaultProps} {...props} />} />
        <Route path="/search" element={<SearchBar {...defaultProps} {...props} />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('SearchBar', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(useNavigate as jest.Mock).mockReturnValue(navigateMock)
  })

  it('renders with initial value', () => {
    renderComponent({initialValue: 'test'})
    const input = screen.getByPlaceholderText('Search files...')
    expect(input).toHaveValue('test')
  })

  it('updates the search value and triggers the search', async () => {
    const user = userEvent.setup({delay: null})
    renderComponent()
    const input = screen.getByPlaceholderText('Search files...')
    await user.type(input, 'searchTerm')
    jest.runAllTimers()
    expect(input).toHaveValue('searchTerm')
    expect(navigateMock).toHaveBeenCalledWith('/search?search_term=searchTerm')
  })

  it('clears the search value', async () => {
    const user = userEvent.setup({delay: null})
    renderComponent({initialValue: 'test'})
    const input = screen.getByPlaceholderText('Search files...')
    const clearButton = screen.getByRole('button', {name: 'Clear search'})
    await user.click(clearButton)
    jest.runAllTimers()
    expect(input).toHaveValue('')
    expect(navigateMock).toHaveBeenCalledWith('/')
  })

  it('navigates to root when search value is completely cleared', async () => {
    const user = userEvent.setup({delay: null})
    renderComponent({initialValue: 'test'})
    const input = screen.getByPlaceholderText('Search files...')
    await user.clear(input)
    jest.runAllTimers()
    expect(input).toHaveValue('')
    expect(navigateMock).toHaveBeenCalledWith('/')
  })
})
