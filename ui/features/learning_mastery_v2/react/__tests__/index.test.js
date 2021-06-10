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
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import axios from '@canvas/axios'
import LearningMastery from '../index'

jest.useFakeTimers()

describe('LearningMastery', () => {
  let axiosMock
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
          ]
        }
      }
    })
    axiosMock = jest.spyOn(axios, 'get').mockResolvedValue(promise)
  })

  afterAll(() => {
    window.ENV = {}
  })

  it('renders each proficiency rating description specified in window.ENV', () => {
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    ratings.forEach(rating => {
      expect(getByText(rating.description)).toBeInTheDocument()
    })
  })

  it('renders a loading spinner', () => {
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('calls the /rollups url', () => {
    render(<LearningMastery {...defaultProps()} />)
    const params = {
      params: {
        rating_percents: true,
        per_page: 20,
        include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
        page: 1
      }
    }
    expect(axiosMock).toHaveBeenCalledWith('/api/v1/courses/1/outcome_rollups', params)
  })

  it('renders each student', async () => {
    const {getByText} = render(<LearningMastery {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Student 1')).toBeInTheDocument()
  })

  describe('when the rollup request is not successful', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get').mockRejectedValue({})
    })

    it("displays a flash alert if the rollups couldn't be fetched", async () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      render(<LearningMastery {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Error loading rollups',
        type: 'error'
      })
    })
  })
})
