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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import axios from '@canvas/axios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useRollups from '../useRollups'

jest.useFakeTimers()

jest.mock('@canvas/axios', () => ({
  get: jest.fn(),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('useRollups', () => {
  const mockedUsers = [
    {
      id: '1',
      name: 'Student 1',
      display_name: 'Student 1',
      avatar_url: 'url',
      status: 'active',
    },
    {
      id: '2',
      name: 'Student 2',
      display_name: 'Student 2',
      avatar_url: 'url',
      status: 'inactive',
    },
    {
      id: '3',
      name: 'Student 3',
      display_name: 'Student 3',
      avatar_url: 'url',
      status: 'concluded',
    },
  ]

  const mockedRatings = [
    {
      color: 'green',
      description: 'mastery!',
      mastery: true,
      points: 3,
    },
    {
      color: 'red',
      description: 'not great',
      mastery: false,
      points: 0,
    },
  ]

  const mockedOutcomes = [
    {
      id: '1',
      title: 'outcome 1',
      ratings: mockedRatings,
    },
  ]

  const mockedRollups = [
    {
      links: {
        user: '1',
        status: 'active',
      },
      scores: [
        {
          score: 4,
          links: {
            outcome: '1',
          },
        },
      ],
    },
    {
      links: {
        user: '2',
        status: 'inactive',
      },
      scores: [
        {
          score: 4,
          links: {
            outcome: '1',
          },
        },
      ],
    },
    {
      links: {
        user: '3',
        status: 'completed',
      },
      scores: [
        {
          score: 0,
          links: {
            outcome: '1',
          },
        },
      ],
    },
  ]

  beforeEach(() => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        linked: {
          users: mockedUsers,
          outcomes: mockedOutcomes,
        },
        rollups: mockedRollups,
      },
    })
    axios.get.mockResolvedValue(promise)
  })

  describe('useRollups hook', () => {
    it('returns defaults until the request finishes loading', async () => {
      const {result} = renderHook(() => useRollups({courseId: '1'}))
      const {isLoading, students, outcomes, rollups, gradebookFilters} = result.current
      expect(isLoading).toEqual(true)
      expect(students).toEqual([])
      expect(outcomes).toEqual([])
      expect(rollups).toEqual([])
      expect(gradebookFilters).toEqual([])
      await act(async () => jest.runAllTimers())
      expect(result.current.isLoading).toEqual(false)
    })

    it('returns the response after the request finishes', async () => {
      const {result} = renderHook(() => useRollups({courseId: '1'}))
      await act(async () => jest.runAllTimers())
      const {students, outcomes, rollups, gradebookFilters} = result.current
      expect(axios.get).toHaveBeenCalled()
      expect(students).toEqual(mockedUsers)
      expect(outcomes).toEqual(mockedOutcomes)
      expect(gradebookFilters).toEqual([])
      expect(rollups).toStrictEqual([
        {
          studentId: '1',
          outcomeRollups: [
            {outcomeId: '1', rating: {...mockedRatings[0], color: `#${mockedRatings[0].color}`}},
          ],
        },
        {
          studentId: '2',
          outcomeRollups: [
            {outcomeId: '1', rating: {...mockedRatings[0], color: `#${mockedRatings[0].color}`}},
          ],
        },
        {
          studentId: '3',
          outcomeRollups: [
            {outcomeId: '1', rating: {...mockedRatings[1], color: `#${mockedRatings[1].color}`}},
          ],
        },
      ])
    })

    it("correctly translates student status from 'completed' to 'concluded' when loading rollups", async () => {
      const {result} = renderHook(() => useRollups({courseId: '1'}))
      await act(async () => jest.runAllTimers())
      const {students} = result.current
      expect(axios.get).toHaveBeenCalled()
      expect(students[2]).toStrictEqual({
        id: '3',
        name: 'Student 3',
        display_name: 'Student 3',
        avatar_url: 'url',
        status: 'concluded',
      })
    })

    it('calls the /rollups URL with the right parameters', async () => {
      renderHook(() => useRollups({courseId: '1'}))
      await act(async () => jest.runAllTimers())
      const params = {
        params: {
          rating_percents: true,
          per_page: 20,
          exclude: [],
          include: ['outcomes', 'users', 'outcome_paths', 'alignments'],
          sort_by: 'student',
          add_defaults: true,
          page: 1,
        },
      }
      expect(axios.get).toHaveBeenCalledWith('/api/v1/courses/1/outcome_rollups', params)
    })

    it('renders a flashAlert if the request fails', async () => {
      axios.get.mockRejectedValue({})
      renderHook(() => useRollups({courseId: '1'}))
      await act(async () => jest.runAllTimers())
      expect(axios.get).toHaveBeenCalled()
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Error loading rollups',
        type: 'error',
      })
    })
  })
})
