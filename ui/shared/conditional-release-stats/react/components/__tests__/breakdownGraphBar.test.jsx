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
import userEvent from '@testing-library/user-event'
import BreakdownBarComponent from '../breakdown-graph-bar'

const defaultProps = {
  upperBound: '100',
  lowerBound: '70',
  rangeStudents: 50,
  totalStudents: 100,
  rangeIndex: 0,
  selectRange: jest.fn(),
  openSidebar: jest.fn(),
}

describe('Breakdown Stats Graph Bar', () => {
  it('renders the component with correct range bounds', () => {
    const {getByTestId} = render(<BreakdownBarComponent {...defaultProps} />)

    expect(getByTestId('range-bounds')).toHaveTextContent('70+ to 100')
  })

  it('displays correct student count information', () => {
    const {getByTestId} = render(<BreakdownBarComponent {...defaultProps} />)

    expect(getByTestId('student-counts')).toHaveTextContent('50 out of 100 students')
  })

  it('calls selectRange and openSidebar when clicking the student counts button', async () => {
    const user = userEvent.setup()
    const {getByTestId} = render(<BreakdownBarComponent {...defaultProps} />)

    await user.click(getByTestId('student-counts'))

    expect(defaultProps.selectRange).toHaveBeenCalledWith(0)
    expect(defaultProps.openSidebar).toHaveBeenCalled()
  })

  it('renders the progress bar with correct width based on student ratio', () => {
    const {container} = render(<BreakdownBarComponent {...defaultProps} />)

    const progressBar = container.querySelector('.crs-bar__horizontal-inside-fill')
    expect(progressBar).toHaveStyle({width: '50%'})
  })

  it('does not render progress bar when student count is 0', () => {
    const props = {...defaultProps, rangeStudents: 0}
    const {container} = render(<BreakdownBarComponent {...props} />)

    const progressBar = container.querySelector('.crs-bar__horizontal-inside-fill')
    expect(progressBar).toBeNull()
  })
})
