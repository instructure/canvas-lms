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
import {render} from '@testing-library/react'
import {NoResultsFound} from '../NoResultsFound'

jest.mock('@canvas/images/react/EmptyDesert', () => {
  return jest.fn(() => <div data-testid="empty-desert" />)
})

const mockFlashScreenReaderHolder = () => {
  const div = document.createElement('div')
  div.id = 'flash_screenreader_holder'
  div.setAttribute('role', 'alert')
  document.body.appendChild(div)
  return div
}

describe('NoResultsFound', () => {
  beforeEach(() => {
    mockFlashScreenReaderHolder()
  })

  afterEach(() => {
    const holder = document.getElementById('flash_screenreader_holder')
    if (holder) {
      holder.remove()
    }
  })

  it('renders the component with the given search term', () => {
    const {getAllByText, getByText, getByTestId} = render(
      <NoResultsFound searchTerm="test query" />,
    )

    const noResultsElements = getAllByText('No results found')
    expect(noResultsElements.length).toBeGreaterThan(0)

    expect(
      getByText('We could not find anything that matches "test query" in files.'),
    ).toBeInTheDocument()

    expect(getByTestId('empty-desert')).toBeInTheDocument()
  })

  it('renders the EmptyDesert component', () => {
    const {getByTestId} = render(<NoResultsFound searchTerm="test query" />)
    expect(getByTestId('empty-desert')).toBeInTheDocument()
  })

  it('includes a screen reader announcement', () => {
    render(<NoResultsFound searchTerm="test query" />)
    // Find the screenreader holder to check the alert content
    const holder = document.getElementById('flash_screenreader_holder')
    expect(holder).toBeTruthy()
    if (holder) {
      expect(holder.textContent).toContain('No results found')
    }
  })

  it('shows suggestions for improving search', () => {
    const {getByText} = render(<NoResultsFound searchTerm="test query" />)
    expect(getByText('Suggestions:')).toBeInTheDocument()
    expect(getByText('Check spelling')).toBeInTheDocument()
    expect(getByText('Try different keywords')).toBeInTheDocument()
    expect(getByText('Enter at least 3 letters in the search box')).toBeInTheDocument()
  })

  it('includes additional explanatory text', () => {
    const {getByText} = render(<NoResultsFound searchTerm="test query" />)
    expect(
      getByText('We could not find anything that matches "test query" in files.'),
    ).toBeInTheDocument()
  })
})
