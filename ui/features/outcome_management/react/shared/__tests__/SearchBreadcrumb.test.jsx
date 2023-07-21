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
import {render} from '@testing-library/react'
import SearchBreadcrumb from '../SearchBreadcrumb'

describe('SearchBreadcrumb', () => {
  const defaultProps = (props = {}) => ({
    groupTitle: 'Outcome Group',
    searchString: '',
    loading: false,
    ...props,
  })

  it('renders component', () => {
    const {getByText} = render(<SearchBreadcrumb {...defaultProps()} />)
    expect(getByText('All Outcome Group Outcomes')).toBeInTheDocument()
  })

  it('displays spinning loader if search string provided and loading prop is true', () => {
    const {getByTestId} = render(
      <SearchBreadcrumb {...defaultProps({searchString: 'abc', loading: true})} />
    )
    expect(getByTestId('search-loading')).toBeInTheDocument()
  })

  it('displays group title and search string if search string provided', () => {
    const {getByText} = render(<SearchBreadcrumb {...defaultProps({searchString: 'abc'})} />)
    expect(getByText('Outcome Group')).toBeInTheDocument()
    expect(getByText('abc')).toBeInTheDocument()
  })

  it('displays right arrow icon with SR accessible title if search string provided', () => {
    const {getByTitle} = render(<SearchBreadcrumb {...defaultProps({searchString: 'abc'})} />)
    expect(getByTitle('search results for')).toBeInTheDocument()
  })
})
