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
import {render, act} from '@testing-library/react'
import LearningMastery from '../index'
import useRollups from '../hooks/useRollups'

jest.mock('../hooks/useRollups')

jest.useFakeTimers()

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

  const users = [
    {
      id: '1',
      name: 'Student 1',
      display_name: 'Student 1',
      avatar_url: 'url'
    }
  ]

  const outcomes = [
    {
      id: '1',
      title: 'outcome 1',
      ratings
    }
  ]

  const rollups = [
    {
      studentId: '1',
      outcomeRollups: [
        {
          outcomeId: '1',
          rating: {
            points: 3,
            color: 'green',
            description: 'rating description!'
          }
        }
      ]
    }
  ]

  const defaultProps = (props = {}) => {
    return {
      courseId: '1',
      ...props
    }
  }

  beforeEach(() => {
    useRollups.mockReturnValue({isLoading: false, students: users, outcomes, rollups})
    window.ENV = {GRADEBOOK_OPTIONS: {outcome_proficiency: {ratings}}}
  })

  afterAll(() => {
    window.ENV = {}
  })

  it('renders each proficiency rating description specified in window.ENV', async () => {
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    ratings.forEach(rating => {
      expect(getByText(rating.description)).toBeInTheDocument()
    })
  })

  it('renders a loading spinner when useRollups.isLoading is true', async () => {
    useRollups.mockReturnValue({isLoading: true})
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('renders each student, outcome, rollup from the response', async () => {
    useRollups.mockReturnValue({isLoading: false, students: users, outcomes, rollups})
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Student 1')).toBeInTheDocument()
    expect(getByText('outcome 1')).toBeInTheDocument()
    expect(getByText('rating description!')).toBeInTheDocument()
  })

  it('calls useRollups with the provided courseId', () => {
    const props = defaultProps()
    render(<LearningMastery {...props} />)
    expect(useRollups).toHaveBeenCalledWith({courseId: props.courseId})
  })
})
