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

  it('does not allow negative values on decrement', () => {
    const mockSetPointsPossible = jest.fn()
    const {getByTestId} = render(
      <PointsPossible
        {...defaultProps}
        pointsPossible={0}
        setPointsPossible={mockSetPointsPossible}
      />
    )

    // Assuming your decrement button has a test id of 'decrement-button', adjust if necessary
    const input = getByTestId('points-possible-input')
    fireEvent.click(input)
    fireEvent.keyDown(input, {keyCode: 40})

    expect(mockSetPointsPossible).not.toHaveBeenCalledWith(-1)
    expect(mockSetPointsPossible).toHaveBeenCalledWith(0)
  })
})
