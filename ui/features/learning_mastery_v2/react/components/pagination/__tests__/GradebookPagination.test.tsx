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
import {GradebookPagination, GradebookPaginationProps} from '../GradebookPagination'

const mockPagination = {
  currentPage: 2,
  totalPages: 6,
  totalCount: 101,
  perPage: 20,
}

const makeProps = (props = {}): GradebookPaginationProps => ({
  pagination: mockPagination,
  onPageChange: vi.fn(),
  ...props,
})

describe('GradebookPagination', () => {
  it('renders the Pagination component with correct props', () => {
    const {getByTestId} = render(<GradebookPagination {...makeProps()} />)
    const pagination = getByTestId('gradebook-pagination')
    expect(pagination).toBeInTheDocument()
  })

  it('displays the correct current page', () => {
    const {getByText} = render(<GradebookPagination {...makeProps()} />)
    expect(getByText('2')).toBeInTheDocument()
  })

  it('calls onPageChange when a page is changed', () => {
    const props = makeProps()
    const {getByText} = render(<GradebookPagination {...props} />)
    const page3Button = getByText('3')
    page3Button.click()
    expect(props.onPageChange).toHaveBeenCalledWith(3)
  })

  it('disables previous button on first page', () => {
    const {container} = render(
      <GradebookPagination {...makeProps({pagination: {...mockPagination, currentPage: 1}})} />,
    )
    const prevButtonIcon = container.querySelector(`svg[name="IconArrowOpenStart"]`)
    expect(prevButtonIcon).toBeInTheDocument()
    const prevButton = prevButtonIcon!.closest('button')
    expect(prevButton).toBeDisabled()
  })

  it('disables next button on last page', () => {
    const {container} = render(
      <GradebookPagination {...makeProps({pagination: {...mockPagination, currentPage: 6}})} />,
    )
    const nextButtonIcon = container.querySelector(`svg[name="IconArrowOpenEnd"]`)
    expect(nextButtonIcon).toBeInTheDocument()
    const nextButton = nextButtonIcon!.closest('button')
    expect(nextButton).toBeDisabled()
  })
})
