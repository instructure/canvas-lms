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
import StatisticsCard from '../StatisticsCard'

describe('StatisticsCard', () => {
  const defaultProps = {
    count: 5,
    label: 'Test Label',
    backgroundColor: '#E0EBF5',
  }

  it('renders with provided props', () => {
    render(<StatisticsCard {...defaultProps} />)
    expect(screen.getByText('5')).toBeInTheDocument()
    expect(screen.getByText('Test Label')).toBeInTheDocument()
  })

  it('renders with zero count', () => {
    render(<StatisticsCard {...defaultProps} count={0} />)
    expect(screen.getByText('0')).toBeInTheDocument()
  })

  it('applies correct background color through theme override', () => {
    const {container} = render(<StatisticsCard {...defaultProps} backgroundColor="#FCE4E5" />)
    const cardElement = container.firstChild as HTMLElement
    expect(cardElement).toHaveStyle('background-color: #FCE4E5')
  })
})
