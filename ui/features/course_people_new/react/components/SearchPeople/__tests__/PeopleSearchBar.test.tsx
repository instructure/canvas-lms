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
import PeopleSearchBar from '../PeopleSearchBar'
import {screenreaderMessageHolderId} from '../../../../util/utils'

describe('PeopleSearchBar', () => {
  const defaultProps = {
    searchTerm: '',
    numberOfResults: 1,
    isLoading: false,
    onChangeHandler: jest.fn(),
    onClearHandler: jest.fn(),
  }

  const renderComponent = (props = {}) => {
    render(<PeopleSearchBar {...defaultProps} {...props} />)
  }

  const user = userEvent.setup()

  beforeEach(() => {
    jest.clearAllMocks()
    // Ensure the screenreader message holder exists
    const holder = document.createElement('div')
    holder.id = screenreaderMessageHolderId
    holder.setAttribute('role', 'alert')
    document.body.appendChild(holder)
  })

  afterEach(() => {
    // Clean up the screenreader message holder
    const holder = document.getElementById(screenreaderMessageHolderId)
    if (holder) {
      holder.remove()
    }
  })

  it('renders the search input with correct placeholder', () => {
    renderComponent()
    expect(screen.getByPlaceholderText('Search people...')).toBeInTheDocument()
  })

  it('displays search icon when search string is empty', () => {
    renderComponent()
    expect(screen.getByTestId('search-icon')).toBeInTheDocument()
  })

  it('displays clear icon when search string is not empty', () => {
    renderComponent({searchTerm: 'test search'})
    expect(screen.getByTestId('clear-search-icon')).toBeInTheDocument()
  })

  it('calls onChangeHandler when input value changes', async () => {
    renderComponent()
    const input = screen.getByPlaceholderText('Search people...')

    await user.type(input, 'test')
    expect(defaultProps.onChangeHandler).toHaveBeenCalled()
  })

  it('calls onClearHandler when clear button is clicked', async () => {
    renderComponent({searchTerm: 'test search'})

    const clearButton = screen.getByTestId('clear-search-icon').closest('button')
    if (clearButton) {
      await user.click(clearButton)
      expect(defaultProps.onClearHandler).toHaveBeenCalled()
    }
  })

  describe('screen reader messages', () => {
    it('does not show messages when loading', () => {
      renderComponent({isLoading: true})
      expect(document.getElementById(screenreaderMessageHolderId)).toBeEmptyDOMElement()
    })

    it('shows message when no search results', () => {
      renderComponent({numberOfResults: 0})
      expect(document.getElementById(screenreaderMessageHolderId)).toHaveTextContent(
        'No people found',
      )
    })

    it('shows message when one search result', () => {
      renderComponent({numberOfResults: 1})
      expect(document.getElementById(screenreaderMessageHolderId)).toHaveTextContent(
        '1 person found',
      )
    })

    it('shows pluralized message when more than one search result', () => {
      renderComponent({numberOfResults: 5})
      expect(document.getElementById(screenreaderMessageHolderId)).toHaveTextContent(
        '5 people found',
      )
    })
  })
})
