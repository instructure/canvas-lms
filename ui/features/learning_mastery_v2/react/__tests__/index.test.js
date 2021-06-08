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
import {render} from '@testing-library/react'
import LearningMastery from '../index'

describe('LearningMastery', () => {
  const ratings = [
    {
      color: 'blue',
      description: 'great!',
      mastery: false,
      points: 5
    },
    {
      color: 'green',
      description: 'mastery!',
      mastery: true,
      points: 3
    },
    {
      color: 'red',
      description: 'not great',
      mastery: false,
      points: 0
    }
  ]

  beforeEach(() => {
    window.ENV = {GRADEBOOK_OPTIONS: {outcome_proficiency: {ratings}}}
  })

  afterAll(() => {
    window.ENV = {}
  })

  it('renders each proficiency rating description specified in window.ENV', () => {
    const {getByText} = render(<LearningMastery />)
    ratings.forEach(rating => {
      expect(getByText(rating.description)).toBeInTheDocument()
    })
  })
})
