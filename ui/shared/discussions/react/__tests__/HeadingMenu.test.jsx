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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {HeadingMenu} from '../components/HeadingMenu'
import { DEFAULT_SEARCH_DELAY } from '../utils/constants'

const defaultProps = () => ({
  name: 'Discussion Filter',
  filters: {
    all: 'All Discussions',
    unread: 'Unread Discussions'
  },
  defaultSelectedFilter: 'all',
  onSelectFilter: () => {},
})

jest.mock('lodash', () => ({
  debounce: fn => {
    fn.cancel = jest.fn()
    return fn
  },
}))

describe('Heading Menu', () => {
  it('renders a Heading menu', () => {
    const {queryByTestId} = render(<HeadingMenu {...defaultProps()} />)
    const headingMenu = queryByTestId('heading-menu')
    expect(headingMenu).toBeInTheDocument()
  })

  it('calls onSelectFilter when a filter is clicked', async () => {
    const onSelectFilterMock = jest.fn()

    const {queryByTestId, getByTestId} = render(
      <HeadingMenu {...defaultProps()} onSelectFilter={onSelectFilterMock} />
    )

    const filterMenu = queryByTestId('filter-menu')
    // Check that the filter menu is initially closed
    expect(filterMenu).not.toBeInTheDocument()

    // Click the toggle button to open the filter menu
    const toggleButton = getByTestId('toggle-filter-menu')
    fireEvent.click(toggleButton)

    // Check that the filter menu is open
    expect(getByTestId('filter-menu')).toBeInTheDocument()

    const filterElement = queryByTestId('menu-filter-all')
    fireEvent.click(filterElement)
    await waitFor(
      () => {
        expect(onSelectFilterMock).toHaveBeenCalledWith({id: 'all', value: 'all'})
      },
      {timeout: DEFAULT_SEARCH_DELAY}
    )
  })
})
