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
import {render, act, waitFor} from '@testing-library/react'
import axios from '@canvas/axios'
import LearningMastery from '../index'

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

  const defaultProps = (props = {}) => {
    return {
      courseId: '1',
      ...props
    }
  }

  beforeEach(() => {
    window.ENV = {GRADEBOOK_OPTIONS: {outcome_proficiency: {ratings}}}
    const promise = Promise.resolve({
      status: 200,
      data: {
        linked: {
          users: [
            {
              id: '1',
              name: 'Student 1',
              display_name: 'Student 1',
              avatar_url: 'url'
            }
          ],
          outcomes: [
            {
              id: '1',
              title: 'outcome 1'
            }
          ]
        }
      }
    })
    jest.spyOn(axios, 'get').mockResolvedValue(promise)
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

  it('renders a loading spinner until loading is finished', async () => {
    const {queryByText, getByText} = render(<LearningMastery {...defaultProps()} />)
    expect(getByText('Loading')).toBeInTheDocument()
    expect(await waitFor(() => queryByText('Loading'))).not.toBeInTheDocument()
  })

  it('renders each student, outcome from the response', async () => {
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Student 1')).toBeInTheDocument()
    expect(getByText('outcome 1')).toBeInTheDocument()
  })
})
