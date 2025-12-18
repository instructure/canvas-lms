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
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react'
import {render, waitFor} from '@testing-library/react'
import {SearchField} from '../components/SearchField'
import {DEFAULT_SEARCH_DELAY} from '../utils/constants'
import userEvent from '@testing-library/user-event'

vi.mock('es-toolkit/compat', () => ({
  debounce: fn => {
    fn.cancel = vi.fn()
    return fn
  },
}))

vi.mock('@instructure/ui-text-input', () => ({
  TextInput: React.forwardRef((props, ref) => {
    const {onSearchEvent, renderLabel, renderBeforeInput, ...rest} = props

    return (
      <div>
        {renderLabel}
        {renderBeforeInput}
        <input ref={ref} {...rest} placeholder="Search..." data-testid="text-input" />
      </div>
    )
  }),
}))

describe('SearchField Component', () => {
  it('renders correctly', () => {
    const {getByPlaceholderText} = render(
      <SearchField id="search-field" name="search" onSearchEvent={vi.fn()} />,
    )
    const inputElement = getByPlaceholderText('Search...')
    expect(inputElement).toBeInTheDocument()
  })

  it('calls onSearchEvent with the correct value after debounce', async () => {
    const onSearchEventMock = vi.fn()
    const {getByPlaceholderText} = render(
      <SearchField
        id="search-field"
        name="search"
        onSearchEvent={onSearchEventMock}
        searchInputRef={vi.fn()}
      />,
    )
    const inputElement = getByPlaceholderText('Search...')

    await userEvent.type(inputElement, 'test')

    await waitFor(
      () => {
        expect(onSearchEventMock).toHaveBeenCalledWith({searchTerm: 'test'})
      },
      {timeout: DEFAULT_SEARCH_DELAY},
    )
  })
})
