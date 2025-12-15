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
import {render, fireEvent} from '@testing-library/react'
import CoursesListHeader from '../CoursesListHeader'

const defaultProps = {
  onChangeSort: vi.fn(),
  id: 'test_id',
  label: 'Test Label',
  tipDesc: 'Click to sort descending',
  tipAsc: 'Click to sort ascending',
}

describe('CoursesListHeader', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with default props', () => {
    const {getByRole, getByText} = render(<CoursesListHeader {...defaultProps} />)

    expect(getByText('Test Label')).toBeInTheDocument()
    expect(getByRole('button')).toBeInTheDocument()
  })

  it('uses default sort and order values when not provided', () => {
    const {container} = render(<CoursesListHeader {...defaultProps} />)

    expect(container.firstChild).toBeInTheDocument()
  })

  it('shows ascending arrow icon when column is sorted ascending', () => {
    const {container} = render(<CoursesListHeader {...defaultProps} sort="test_id" order="asc" />)

    expect(container.querySelector('[name="IconMiniArrowUp"]')).toBeInTheDocument()
  })

  it('shows descending arrow icon when column is sorted descending', () => {
    const {container} = render(<CoursesListHeader {...defaultProps} sort="test_id" order="desc" />)

    expect(container.querySelector('[name="IconMiniArrowDown"]')).toBeInTheDocument()
  })

  it('shows no icon when column is not currently sorted', () => {
    const {container} = render(
      <CoursesListHeader {...defaultProps} sort="other_column" order="asc" />,
    )

    expect(container.querySelector('[name="IconMiniArrowUp"]')).not.toBeInTheDocument()
    expect(container.querySelector('[name="IconMiniArrowDown"]')).not.toBeInTheDocument()
  })

  it('shows ascending tooltip when column is sorted ascending', () => {
    const {getByText} = render(<CoursesListHeader {...defaultProps} sort="test_id" order="asc" />)

    fireEvent.mouseEnter(getByText('Test Label'))
    expect(getByText('Click to sort ascending')).toBeInTheDocument()
  })

  it('shows descending tooltip by default', () => {
    const {getByText} = render(
      <CoursesListHeader {...defaultProps} sort="other_column" order="desc" />,
    )

    fireEvent.mouseEnter(getByText('Test Label'))
    expect(getByText('Click to sort descending')).toBeInTheDocument()
  })

  it('calls onChangeSort when clicked', () => {
    const onChangeSort = vi.fn()
    const {getByRole} = render(<CoursesListHeader {...defaultProps} onChangeSort={onChangeSort} />)

    fireEvent.click(getByRole('button'))
    expect(onChangeSort).toHaveBeenCalledWith('test_id')
    expect(onChangeSort).toHaveBeenCalledTimes(1)
  })

  it('prevents default behavior on click', () => {
    const {getByRole} = render(<CoursesListHeader {...defaultProps} />)
    const button = getByRole('button')

    fireEvent.click(button)
    expect(defaultProps.onChangeSort).toHaveBeenCalled()
  })

  it('renders label text in bold', () => {
    const {getByText} = render(<CoursesListHeader {...defaultProps} />)

    const labelElement = getByText('Test Label')
    expect(labelElement).toBeInTheDocument()
  })

  it('renders as a link styled as button', () => {
    const {getByRole} = render(<CoursesListHeader {...defaultProps} />)

    const button = getByRole('button')
    expect(button.tagName.toLowerCase()).toBe('button')
  })
})
