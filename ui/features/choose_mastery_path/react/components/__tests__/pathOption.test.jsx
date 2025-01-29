/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PathOption from '../path-option'

const defaultProps = () => ({
  assignments: [
    {
      name: 'Ch 2 Quiz',
      type: 'quiz',
      points: 10,
      points_possible: 10,
      due_at: new Date(),
      itemId: 1,
      category: {
        id: 'other',
        label: 'Other',
      },
    },
    {
      name: 'Ch 2 Review',
      type: 'assignment',
      points: 10,
      points_possible: 10,
      due_at: new Date(),
      itemId: 1,
      category: {
        id: 'other',
        label: 'Other',
      },
    },
  ],
  setId: 1,
  optionIndex: 0,
  selectedOption: null,
  selectOption: jest.fn(),
})

describe('PathOption', () => {
  it('renders the component with basic structure', () => {
    const props = defaultProps()
    const {container} = render(<PathOption {...props} />)

    const option = container.querySelector('.cmp-option')
    expect(option).toBeInTheDocument()
  })

  it('displays all assignments in the option', () => {
    const props = defaultProps()
    const {container} = render(<PathOption {...props} />)

    const assignments = container.querySelectorAll('.cmp-assignment')
    expect(assignments).toHaveLength(2)
  })

  it('shows assignment details correctly', () => {
    const props = defaultProps()
    const {getByText} = render(<PathOption {...props} />)

    expect(getByText('Ch 2 Quiz')).toBeInTheDocument()
    expect(getByText('Ch 2 Review')).toBeInTheDocument()
  })

  it('applies selected styling when option is selected', () => {
    const props = defaultProps()
    props.selectedOption = 1
    const {container} = render(<PathOption {...props} />)

    const selectedOption = container.querySelector('.cmp-option__selected')
    expect(selectedOption).toBeInTheDocument()
  })

  it('applies disabled styling when another option is selected', () => {
    const props = defaultProps()
    props.selectedOption = 2
    const {container} = render(<PathOption {...props} />)

    const disabledOption = container.querySelector('.cmp-option__disabled')
    expect(disabledOption).toBeInTheDocument()
  })

  it('shows points for each assignment', () => {
    const props = defaultProps()
    const {getAllByText} = render(<PathOption {...props} />)

    const pointsElements = getAllByText('10 pts')
    expect(pointsElements).toHaveLength(2)
  })

  it('shows assignment titles correctly', () => {
    const props = defaultProps()
    const {getByText} = render(<PathOption {...props} />)

    expect(getByText('Ch 2 Quiz')).toBeInTheDocument()
    expect(getByText('Ch 2 Review')).toBeInTheDocument()
  })

  it('shows option number correctly', () => {
    const props = defaultProps()
    const {getByText} = render(<PathOption {...props} />)

    expect(getByText('Option 1')).toBeInTheDocument()
  })

  it('has a select button', () => {
    const props = defaultProps()
    const {getByRole} = render(<PathOption {...props} />)

    expect(getByRole('button', {name: 'Select'})).toBeInTheDocument()
  })
})
