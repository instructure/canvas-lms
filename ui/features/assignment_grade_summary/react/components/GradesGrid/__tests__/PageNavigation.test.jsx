/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent, screen} from '@testing-library/react'
import PageNavigation from '../PageNavigation'

describe('GradeSummary PageNavigation', () => {
  let props

  beforeEach(() => {
    props = {
      currentPage: 1,
      onPageClick: jest.fn(),
      pageCount: 10,
    }
  })

  test('adds a button for each page', () => {
    render(<PageNavigation {...props} />)
    expect(screen.getAllByRole('button')).toHaveLength(6)
  })

  test('includes a button for "Next Page" when not on the last page', () => {
    render(<PageNavigation {...props} />)
    expect(screen.getAllByText('Next Page')[0]).toBeInTheDocument()
  })

  test('excludes the button for "Next Page" when on the last page', () => {
    render(<PageNavigation {...{...props, ...{currentPage: 10}}} />)
    expect(screen.queryByText('Next Page')).not.toBeInTheDocument()
  })

  test('includes a button for "Previous Page" when not on the first page', () => {
    render(<PageNavigation {...{...props, ...{currentPage: 5}}} />)
    expect(screen.getAllByText('Previous Page')[0]).toBeInTheDocument()
  })

  test('excludes the button for "Previous Page" when on the first page', () => {
    render(<PageNavigation {...props} />)
    expect(screen.queryByText('Previous Page')).not.toBeInTheDocument()
  })

  test('calls onPageClick when a page button is clicked', () => {
    render(<PageNavigation {...props} />)
    fireEvent.click(screen.getByText('3'))
    expect(props.onPageClick).toHaveBeenCalledWith(3)
  })

  test('calls onPageClick when the "Next Page" button is clicked', () => {
    props.currentPage = 3
    render(<PageNavigation {...props} />)
    fireEvent.click(screen.getAllByText('Next Page')[0])
    expect(props.onPageClick).toHaveBeenCalledWith(4)
  })

  test('calls onPageClick when the "Previous Page" button is clicked', () => {
    props.currentPage = 3
    render(<PageNavigation {...props} />)
    fireEvent.click(screen.getAllByText('Previous Page')[0])
    expect(props.onPageClick).toHaveBeenCalledWith(2)
  })
})
