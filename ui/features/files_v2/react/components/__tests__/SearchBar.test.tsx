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
import {setupFilesEnv} from '../../../fixtures/fakeFilesEnv'
import SearchBar from '../SearchBar'

const navigateMock = jest.fn()
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
}))

jest.mock('@canvas/util/globalUtils', () => ({
  windowPathname: () => '/files/folder/users_1',
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

  it('clears the search value', async () => {
    const user = userEvent.setup()
    renderComponent({initialValue: 'test'})
    const input = screen.getByPlaceholderText('Search files...')
    const clearButton = screen.getByRole('button', {name: 'Clear search'})
    await user.click(clearButton)
    expect(input).toHaveValue('')
  })

  it('does not search on click when empty input', async () => {
    const user = userEvent.setup()
    renderComponent()
    const searchButton = screen.getByRole('button', {name: 'Search'})
    await user.click(searchButton)
    expect(navigateMock).not.toHaveBeenCalled()
  })

  it('does not search on enter press when empty input', async () => {
    const user = userEvent.setup()
    renderComponent()
    const searchButton = screen.getByRole('button', {name: 'Search'})
    await user.type(searchButton, '{enter}')
    expect(navigateMock).not.toHaveBeenCalled()
  })

  describe('when showing all contexts', () => {
    beforeAll(() => {
      setupFilesEnv(true)
    })

    it('searches on click', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByPlaceholderText('Search files...')
      await user.type(input, 'searchTerm')
      const searchButton = screen.getByRole('button', {name: 'Search'})
      await user.click(searchButton)
      expect(navigateMock).toHaveBeenCalledWith('/folder/users_1/search?search_term=searchTerm')
    })

    it('searches on enter press', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByPlaceholderText('Search files...')
      await user.type(input, 'searchTerm')
      await user.keyboard('{enter}')
      expect(navigateMock).toHaveBeenCalledWith('/folder/users_1/search?search_term=searchTerm')
    })
  })

  describe('when not showing all contexts', () => {
    beforeAll(() => {
      setupFilesEnv(false)
    })

    it('searches on click', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByPlaceholderText('Search files...')
      await user.type(input, 'searchTerm')
      const searchButton = screen.getByRole('button', {name: 'Search'})
      await user.click(searchButton)
      expect(navigateMock).toHaveBeenCalledWith('/search?search_term=searchTerm')
    })

    it('searches on enter press', async () => {
      const user = userEvent.setup()
      renderComponent()
      const input = screen.getByPlaceholderText('Search files...')
      await user.type(input, 'searchTerm')
      await user.keyboard('{enter}')
      expect(navigateMock).toHaveBeenCalledWith('/search?search_term=searchTerm')
    })
  })
})
