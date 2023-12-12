/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import FilterBar from '../FilterBar'

describe('FilterBar', () => {
  const filterOptions = [
    {value: 'active', text: 'Active'},
    {value: 'completed', text: 'Completed'},
  ]

  it('renders', () => {
    const {getByRole} = render(
      <FilterBar onFilter={() => {}} onSearch={() => {}} filterOptions={[]} />
    )
    expect(getByRole('searchbox')).toBeInTheDocument()
  })

  it('always includes an "All" option', () => {
    const {getByRole} = render(
      <FilterBar onFilter={() => {}} onSearch={() => {}} filterOptions={[]} />
    )
    userEvent.click(getByRole('combobox', {name: 'Filter by'}))
    expect(getByRole('option', {name: 'All'})).toBeInTheDocument()
  })

  describe('when the filter dropdown changes', () => {
    it('calls onFilter', () => {
      const onFilter = jest.fn()
      const {getByRole} = render(
        <FilterBar onFilter={onFilter} onSearch={() => {}} filterOptions={filterOptions} />
      )
      userEvent.click(getByRole('combobox', {name: 'Filter by'}))
      userEvent.click(getByRole('option', {name: 'Active'}))
      expect(onFilter).toHaveBeenCalledWith('active')
    })
  })

  describe('when the search input changes', () => {
    const waitForDebounce = () => new Promise(resolve => setTimeout(resolve, 100))
    const delay = 50

    it('calls onSearch after debounce', async () => {
      const onSearch = jest.fn()
      const {getByRole} = render(
        <FilterBar
          onFilter={() => {}}
          onSearch={onSearch}
          filterOptions={[]}
          searchDebounceDelay={delay}
        />
      )
      userEvent.type(getByRole('searchbox'), 'hello')
      expect(onSearch).not.toHaveBeenCalled()
      await waitForDebounce()
      expect(onSearch).toHaveBeenCalledWith('hello')
    })

    it('ignores search queries with < 3 characters', async () => {
      const onSearch = jest.fn()
      const {getByRole} = render(
        <FilterBar
          onFilter={() => {}}
          onSearch={onSearch}
          filterOptions={[]}
          searchDebounceDelay={delay}
        />
      )
      userEvent.type(getByRole('searchbox'), 'h')
      await waitForDebounce()
      expect(onSearch).not.toHaveBeenCalled()
    })
  })

  describe('when cleared', () => {
    it('calls onFilter with "all"', () => {
      const onFilter = jest.fn()
      const {getByRole} = render(
        <FilterBar onFilter={onFilter} onSearch={() => {}} filterOptions={filterOptions} />
      )
      userEvent.click(getByRole('button', {name: 'Clear'}))
      expect(onFilter).toHaveBeenCalledWith('all')
    })

    it('calls onSearch with ""', () => {
      const onSearch = jest.fn()
      const {getByRole} = render(
        <FilterBar onFilter={() => {}} onSearch={onSearch} filterOptions={[]} />
      )
      userEvent.type(getByRole('searchbox'), 'hello')
      userEvent.click(getByRole('button', {name: 'Clear'}))
      expect(onSearch).toHaveBeenCalledWith('')
    })
  })

  describe('searchScreenReaderLabel', () => {
    it('uses default', () => {
      const {getByLabelText} = render(
        <FilterBar onFilter={() => {}} onSearch={() => {}} filterOptions={[]} />
      )

      expect(getByLabelText('Search')).toBeInTheDocument()
    })

    it('uses provided', () => {
      const label = "Uh oh! I'm a screen reader!"
      const {getByLabelText} = render(
        <FilterBar
          onFilter={() => {}}
          onSearch={() => {}}
          filterOptions={[]}
          searchScreenReaderLabel={label}
        />
      )

      expect(getByLabelText(label)).toBeInTheDocument()
    })
  })

  describe('searchPlaceholder', () => {
    it('uses default', () => {
      const {getByPlaceholderText} = render(
        <FilterBar onFilter={() => {}} onSearch={() => {}} filterOptions={[]} />
      )

      expect(getByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('uses provided', () => {
      const placeholder = "Uh oh! I'm a placeholder!"
      const {getByPlaceholderText} = render(
        <FilterBar
          onFilter={() => {}}
          onSearch={() => {}}
          filterOptions={[]}
          searchPlaceholder={placeholder}
        />
      )

      expect(getByPlaceholderText(placeholder)).toBeInTheDocument()
    })
  })
})
