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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {SearchField} from '../components/SearchField'
import '@testing-library/jest-dom/extend-expect'
import {DEFAULT_SEARCH_DELAY} from '../utils/constants'

jest.mock('lodash', () => ({
  debounce: fn => {
    fn.cancel = jest.fn()
    return fn
  },
}))

jest.mock('@instructure/ui-a11y-content', () => ({
  ScreenReaderContent: ({children}) => <div>{children}</div>,
}))

jest.mock('@instructure/ui-icons', () => ({
  IconSearchLine: () => <div>Icon</div>,
}))

jest.mock('@instructure/ui-text-input', () => ({
  TextInput: React.forwardRef((props, ref) => {
    const {onSearchEvent, searchInputRef, renderLabel, renderBeforeInput, ...rest} = props
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
    const {getByPlaceholderText} = render(<SearchField onSearchEvent={jest.fn()} />)
    const inputElement = getByPlaceholderText('Search...')
    expect(inputElement).toBeInTheDocument()
  })

  it('calls onSearchEvent with the correct value after debounce', async () => {
    const onSearchEventMock = jest.fn()
    const {getByPlaceholderText} = render(
      <SearchField onSearchEvent={onSearchEventMock} searchInputRef={jest.fn()} />
    )
    const inputElement = getByPlaceholderText('Search...')

    fireEvent.change(inputElement, {target: {value: 'test'}})

    await waitFor(
      () => {
        expect(onSearchEventMock).toHaveBeenCalledWith({searchTerm: 'test'})
      },
      {timeout: DEFAULT_SEARCH_DELAY}
    )
  })
})
