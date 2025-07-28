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
import { render, fireEvent } from '@testing-library/react'
import { FetchError } from '../utils/FetchError'

describe('FetchError', () => {
  it('renders the component', () => {
    const component = render(<FetchError retryCallback={jest.fn()} />)

    expect(component.getByText('Items failed to load')).toBeInTheDocument()
  })

  it('calls the callback on push the retry', () => {
    const mockRetryCallback = jest.fn()

    const component = render(<FetchError retryCallback={mockRetryCallback} />)

    fireEvent.click(component.getByTestId('retry-items-failed-to-load'))
    expect(mockRetryCallback).toHaveBeenCalledTimes(1)
  })
})
