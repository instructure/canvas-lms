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
import ProficiencyFilter from '../ProficiencyFilter'

describe('ProficiencyFilter', () => {
  const ratings = [
    {
      color: 'blue',
      description: 'great!',
      masteryAt: 1,
      points: 2,
    },
    {
      color: 'green',
      description: 'mastery!',
      masteryAt: 1,
      points: 1,
    },
    {
      color: 'red',
      description: 'not great',
      masteryAt: 1,
      points: 0,
    },
  ]

  let visibleRatings
  let setVisibleRatings

  const defaultProps = (props = {}) => {
    return {
      ratings,
      visibleRatings,
      setVisibleRatings,
      ...props,
    }
  }

  beforeEach(() => {
    visibleRatings = [true, true, true, true]
    setVisibleRatings = jest.fn(newVisibleRatings => (visibleRatings = newVisibleRatings))
  })

  it('renders each proficiency rating provided as a prop', () => {
    const {getByText} = render(<ProficiencyFilter {...defaultProps()} />)
    ratings.forEach(rating => {
      expect(getByText(rating.description)).toBeInTheDocument()
    })
  })

  it('calls onClick method and sets rating to invisible', () => {
    const {getByText} = render(<ProficiencyFilter {...defaultProps()} />)
    expect(visibleRatings).toStrictEqual([true, true, true, true])
    fireEvent.click(getByText('mastery!'))
    expect(visibleRatings).toStrictEqual([true, true, false, true])
  })
})
