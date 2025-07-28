/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'

import {PointsPossible} from '../PointsPossible'

const defaultProps = {
  pointsPossible: 10,
  setPointsPossible: () => {},
  pointsPossibleLabel: 'Points Possible',
  pointsPossibleDataTestId: 'points-possible-input',
}

const renderPointsPossible = () => {
  return render(<PointsPossible {...defaultProps} />)
}
describe('PointsPossible', () => {
  it('renders', () => {
    const {getByText} = renderPointsPossible()
    expect(getByText('Points Possible')).toBeInTheDocument()
  })

  it('parses float number', () => {
    const mockSetPointsPossible = jest.fn()
    const {getByTestId} = render(
      <PointsPossible
        {...defaultProps}
        pointsPossible={0}
        setPointsPossible={mockSetPointsPossible}
      />,
    )

    const input = getByTestId('points-possible-input')
    fireEvent.change(input, {target: {value: '10.5'}})

    expect(mockSetPointsPossible).toHaveBeenCalledWith('10.5')
  })

  it('ignores invalid number', () => {
    const mockSetPointsPossible = jest.fn()
    const {getByTestId} = render(
      <PointsPossible
        {...defaultProps}
        pointsPossible={0}
        setPointsPossible={mockSetPointsPossible}
      />,
    )

    const input = getByTestId('points-possible-input')

    input.value = '15asd'
    fireEvent.blur(input)

    expect(mockSetPointsPossible).toHaveBeenCalledWith(0)

    input.value = '15.'
    fireEvent.blur(input)

    expect(mockSetPointsPossible).toHaveBeenCalledWith(0)
  })

  it('cuts the number to 2 decimal points', () => {
    const mockSetPointsPossible = jest.fn()
    const {getByTestId} = render(
      <PointsPossible
        {...defaultProps}
        pointsPossible={0}
        setPointsPossible={mockSetPointsPossible}
      />,
    )

    const input = getByTestId('points-possible-input')
    input.value = '10.551234'
    fireEvent.blur(input)

    expect(mockSetPointsPossible).toHaveBeenCalledWith(10.55)
  })
})
