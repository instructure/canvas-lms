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
import StudentSearchInput from '../components/StudentSearchInput'

describe('StudentSearchInput', () => {
  it('renders label', () => {
    const students = []
    const {getByLabelText} = render(<StudentSearchInput students={students} onChange={() => {}} />)
    const input = getByLabelText(/Student Names/)
    expect(input).toBeInTheDocument()
  })

  it('readonly', () => {
    const {getByLabelText} = render(<StudentSearchInput readonly onChange={() => {}} />)
    const input = getByLabelText(/Student Names/)
    expect(input).toHaveAttribute('readonly')
  })

  it('enabled', () => {
    const {getByLabelText} = render(<StudentSearchInput readonly={false} onChange={() => {}} />)
    const input = getByLabelText(/Student Names/)
    expect(input).not.toHaveAttribute('readonly')
  })

  it('triggers onChange upon input', () => {
    const mockOnChange = jest.fn()
    const students = [{id: 1, name: 'John Doe'}]
    const {getByLabelText} = render(
      <StudentSearchInput students={students} onChange={mockOnChange} />
    )
    const input = getByLabelText(/Student Names/)
    expect(input).toBeInTheDocument()
    fireEvent.change(input, {target: {value: 'John'}})
    expect(mockOnChange).toHaveBeenCalledWith('John')
  })
})
