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
import SubTableContent from '../SubTableContent'

describe('SubTableContent', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading spinner when isLoading is true', () => {
    const {getByText} = render(<SubTableContent isLoading={true} isEmpty={false} searchString="" />)
    expect(getByText('Loading data')).toBeInTheDocument()
  })

  it('renders NoResultsFound when isEmpty is true and searchString is provided', () => {
    const {getAllByText} = render(
      <SubTableContent isLoading={false} isEmpty={true} searchString="test query" />,
    )

    const noResultsElements = getAllByText('No results found')
    expect(noResultsElements.length).toBeGreaterThan(0)
    expect(screen.getAllByText(/test query/)).toBeTruthy()
  })

  it('renders nothing when not loading and not empty', () => {
    const {container} = render(
      <SubTableContent isLoading={false} isEmpty={false} searchString="" />,
    )
    expect(container.firstChild).toBeNull()
  })

  it('renders nothing when isEmpty is true but searchString is empty', () => {
    const {container} = render(<SubTableContent isLoading={false} isEmpty={true} searchString="" />)
    expect(container.firstChild).toBeNull()
  })
})
