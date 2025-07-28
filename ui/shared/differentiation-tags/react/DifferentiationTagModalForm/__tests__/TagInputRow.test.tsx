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
import TagInputRow, {TagInputRowProps} from '../TagInputRow'
import '@testing-library/jest-dom'

describe('TagInputRow', () => {
  const onChangeMock = jest.fn()
  const onRemoveMock = jest.fn()
  const inputRefMock = jest.fn()

  const defaultProps: TagInputRowProps = {
    tag: {id: 100, name: 'Test Tag'},
    index: 0,
    totalTags: 2,
    onChange: onChangeMock,
    onRemove: onRemoveMock,
    inputRef: inputRefMock,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders an input with variant label when totalTags > 1', () => {
    render(<TagInputRow {...defaultProps} />)
    expect(screen.getByText('Tag Name (Variant 1)')).toBeInTheDocument()
    const input = screen.getByDisplayValue('Test Tag')
    const removeTagButton = screen.queryByTestId('remove-tag')

    expect(input).toBeInTheDocument()
    expect(removeTagButton).toBeInTheDocument()
  })

  it('renders an input with single tag label when totalTags is 1', () => {
    const props: TagInputRowProps = {...defaultProps, totalTags: 1}
    render(<TagInputRow {...props} />)
    expect(screen.getByText('Tag Name')).toBeInTheDocument()
  })

  it('calls onChange when input value changes', async () => {
    render(<TagInputRow {...defaultProps} />)
    const input = screen.getByDisplayValue('Test Tag')
    await userEvent.clear(input)
    await userEvent.type(input, 'Updated Tag')
    expect(onChangeMock).toHaveBeenCalled()
  })

  it('calls onRemove when remove button is clicked', async () => {
    render(<TagInputRow {...defaultProps} />)
    const removeButton = screen.getByTestId('remove-tag')
    await userEvent.click(removeButton)
    expect(onRemoveMock).toHaveBeenCalledWith(100)
  })

  it('does not render remove button when totalTags is 1', () => {
    const props: TagInputRowProps = {...defaultProps, totalTags: 1}
    render(<TagInputRow {...props} />)

    expect(screen.queryByTestId('remove-tag')).not.toBeInTheDocument()
  })
})
