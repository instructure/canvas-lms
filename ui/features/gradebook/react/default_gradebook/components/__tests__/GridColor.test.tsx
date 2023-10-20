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

import React from 'react'
import {darken} from '../../constants/colors'
import {render} from '@testing-library/react'
import GridColor from '../GridColor'

const colors = {
  dropped: '#FEF0E5',
  excused: '#FEF7E5',
  extended: '#F0E8EF',
  late: '#ffff00',
  missing: '#FFE8E5',
  resubmitted: '#E5F7E5',
}

const customStatuses = [
  {
    color: '#00ffff',
    id: '4',
    name: 'new status',
  },
  {
    color: '#ff00ff',
    id: '5',
    name: 'new status 2',
  },
]

describe('GridColor', () => {
  it('renders custom status colors and concatenates multiple of them', () => {
    render(<GridColor colors={colors} customStatuses={customStatuses} />)
    const {getByTestId} = render(
      <>
        <div className="even">
          <div className="gradebook-cell custom-grade-status-4" data-testid="grid-color-even" />
        </div>
        <div className="odd">
          <div className="gradebook-cell custom-grade-status-4" data-testid="grid-color-odd" />
        </div>
        <div className="slick-cell editable">
          <div className="gradebook-cell custom-grade-status-4" data-testid="grid-color-editable" />
        </div>
        <div className="even">
          <div className="gradebook-cell custom-grade-status-5" data-testid="grid-color-even-2" />
        </div>
        <div className="odd">
          <div className="gradebook-cell custom-grade-status-5" data-testid="grid-color-odd-2" />
        </div>
        <div className="slick-cell editable">
          <div
            className="gradebook-cell custom-grade-status-5"
            data-testid="grid-color-editable-2"
          />
        </div>
      </>
    )

    expect(getByTestId('grid-color-even')).toHaveStyle('background-color: #00ffff')
    expect(getByTestId('grid-color-odd')).toHaveStyle(`background-color: ${darken('#00ffff', 5)}`)
    expect(getByTestId('grid-color-editable')).toHaveStyle('background-color: white')
    expect(getByTestId('grid-color-even-2')).toHaveStyle('background-color: #ff00ff')
    expect(getByTestId('grid-color-odd-2')).toHaveStyle(`background-color: ${darken('#ff00ff', 5)}`)
    expect(getByTestId('grid-color-editable-2')).toHaveStyle('background-color: white')
  })

  it('renders with blank custom status and standard status colors', () => {
    const {getByTestId} = render(<GridColor statuses={[]} colors={colors} customStatuses={[]} />)
    const styleTag = getByTestId('grid-color')
    expect(styleTag).toHaveTextContent('')
  })

  it('renders with blank custom statuses if no prop is passed in', () => {
    const {getByTestId} = render(<GridColor statuses={[]} colors={colors} />)
    const styleTag = getByTestId('grid-color')
    expect(styleTag).toHaveTextContent('')
  })
})
