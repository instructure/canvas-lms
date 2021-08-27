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
import {render, fireEvent} from '@testing-library/react'
import TextSearchInput from '../components/TextSearchInput'

describe('TextSearchInput', () => {
  it('renders label', () => {
    const students = []
    const {getByLabelText} = render(
      <TextSearchInput students={students} label="label" readonly={false} onChange={() => {}} />
    )
    const input = getByLabelText(/label/)
    expect(input).toBeInTheDocument()
  })

  it('readonly', () => {
    const {getByLabelText} = render(<TextSearchInput label="label" readonly onChange={() => {}} />)
    const input = getByLabelText(/label/)
    expect(input).toHaveAttribute('readonly')
  })

  it('enabled', () => {
    const {getByLabelText} = render(
      <TextSearchInput label="label" readonly={false} onChange={() => {}} />
    )
    const input = getByLabelText(/label/)
    expect(input).not.toHaveAttribute('readonly')
  })

  it('triggers onChange upon input', () => {
    const mockOnChange = jest.fn()
    const students = [{id: 1, name: 'John Doe'}]
    const {getByLabelText} = render(
      <TextSearchInput students={students} label="label" readonly={false} onChange={mockOnChange} />
    )
    const input = getByLabelText(/label/)
    expect(input).toBeInTheDocument()
    fireEvent.change(input, {target: {value: 'John'}})
    expect(mockOnChange).toHaveBeenCalledWith('John')
  })

  it('placeholder', () => {
    const {getByPlaceholderText} = render(
      <TextSearchInput
        label="label"
        readonly={false}
        onChange={() => {}}
        placeholder="placeholder text"
      />
    )
    const searchField = getByPlaceholderText(/placeholder text/)
    expect(searchField).toBeInTheDocument()
  })
})
