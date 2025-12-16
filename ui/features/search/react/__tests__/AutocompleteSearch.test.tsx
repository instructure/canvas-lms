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

import {fireEvent, render, waitFor} from '@testing-library/react'
import AutocompleteSearch from '../AutocompleteSearch'
import userEvent from '@testing-library/user-event'

const options = ['graphs', 'graphs and charts', 'calculators', 'computational geometry']

const props = {
  onInputChange: jest.fn(),
  setInputRef: jest.fn(),
  options,
  defaultValue: '',
}

describe('AutocompleteSearch', () => {
  it('renders initially with no options shown', () => {
    const {getByTestId, queryByTestId} = render(<AutocompleteSearch {...props} />)

    expect(getByTestId('search-input')).toBeInTheDocument()
    expect(queryByTestId(`option-${options[0]}`)).toBeNull()
    expect(queryByTestId(`option-${options[1]}`)).toBeNull()
    expect(queryByTestId(`option-${options[2]}`)).toBeNull()
    expect(queryByTestId(`option-${options[3]}`)).toBeNull()
  })

  it('shows options when input is focused', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<AutocompleteSearch {...props} />)

    const input = getByTestId('search-input')
    await user.click(input)

    await waitFor(() => {
      expect(getByTestId(`option-${options[0]}`)).toBeInTheDocument()
      expect(getByTestId(`option-${options[1]}`)).toBeInTheDocument()
      expect(getByTestId(`option-${options[2]}`)).toBeInTheDocument()
      expect(getByTestId(`option-${options[3]}`)).toBeInTheDocument()
    })
  })

  it('filters options based on input value', async () => {
    const user = userEvent.setup()
    const {getByTestId, queryByTestId} = render(<AutocompleteSearch {...props} />)

    const input = getByTestId('search-input')
    await user.click(input)
    fireEvent.change(input, {target: {value: 'gra'}})

    await waitFor(() => {
      expect(getByTestId(`option-${options[0]}`)).toBeInTheDocument()
      expect(getByTestId(`option-${options[1]}`)).toBeInTheDocument()
      expect(queryByTestId(`option-${options[2]}`)).toBeNull()
      expect(queryByTestId(`option-${options[3]}`)).toBeNull()
    })
  })
})
