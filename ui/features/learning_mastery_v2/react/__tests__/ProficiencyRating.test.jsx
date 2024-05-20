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
import ProficiencyRating from '../ProficiencyRating'
import {svgUrl} from '../icons'

jest.mock('../icons', () => ({
  svgUrl: jest.fn(() => 'http://test.com'),
}))

describe('ProficiencyRating', () => {
  const defaultProps = (props = {}) => {
    return {
      points: 5,
      masteryAt: 10,
      color: 'green',
      description: 'great',
      onClick: () => {},
      ...props,
    }
  }

  it('calls svgUrl to find the right icon', () => {
    const {points, masteryAt} = defaultProps()
    render(<ProficiencyRating {...defaultProps()} />)
    expect(svgUrl).toHaveBeenCalledWith(points, masteryAt)
  })

  it('shows a enabled_filter SVG only when the rating is enabled', () => {
    const {getByTestId, queryByTestId, getByText} = render(
      <ProficiencyRating {...defaultProps()} />
    )
    expect(getByTestId('enabled-filter')).toBeInTheDocument()
    fireEvent.click(getByText('great'))
    expect(queryByTestId('enabled-filter')).not.toBeInTheDocument()
  })
})
