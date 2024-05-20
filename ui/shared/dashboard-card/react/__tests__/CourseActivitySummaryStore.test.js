/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import CourseActivitySummaryStore from '../CourseActivitySummaryStore'
import wait from 'waait'
import fetchMock from 'fetch-mock'

describe('CourseActivitySummaryStore', () => {
  const stream = [
    {
      type: 'DiscussionTopic',
      unread_count: 2,
      count: 7,
    },
    {
      type: 'Conversation',
      unread_count: 0,
      count: 3,
    },
  ]
  beforeEach(() => {
    CourseActivitySummaryStore.setState({streams: {}})
  })

  describe('getStateForCourse', () => {
    it('should return root state object when no courseId is provided', () => {
      expect(CourseActivitySummaryStore.getStateForCourse().streams).toEqual({})
    })

    it('should return empty object for course id not already in state', () => {
      const spy = jest
        .spyOn(CourseActivitySummaryStore, '_fetchForCourse')
        .mockImplementation(() => {})
      expect(CourseActivitySummaryStore.getStateForCourse(1)).toEqual({})
      expect(spy).toHaveBeenCalled()
      CourseActivitySummaryStore.setState({streams: {1: {stream}}})
      expect(CourseActivitySummaryStore.getStateForCourse(1)).toEqual({stream})
    })
  })

  describe('_fetchForCourse', () => {
    it('populates state based on API response', async () => {
      expect(CourseActivitySummaryStore.getState().streams[1]).toBeUndefined() // precondition

      const spy = jest.spyOn(window, 'fetch').mockImplementation(() =>
        Promise.resolve().then(() => ({
          status: 200,
          clone: () => ({
            json: () => Promise.resolve().then(() => stream),
          }),
        }))
      )
      CourseActivitySummaryStore._fetchForCourse(1)
      await wait(1)
      expect(spy).toHaveBeenCalled()
      expect(CourseActivitySummaryStore.getState()).toEqual({streams: {1: {stream}}})
    })

    it('handes 401 errors correctly', async () => {
      expect(CourseActivitySummaryStore.getState().streams[1]).toBeUndefined() // precondition

      jest.spyOn(window, 'fetch').mockImplementation(() =>
        Promise.resolve().then(() => ({
          ok: true,
          status: 401,
          statusText: 'Unauthorized',
          json: () => {
            throw new Error('should never make it here')
          },
        }))
      )
      const errorFn = jest.fn()
      CourseActivitySummaryStore._fetchForCourse(1).catch(errorFn)
      await wait(1)
      expect(errorFn).toHaveBeenCalled()
      expect(CourseActivitySummaryStore.getState().streams[1]).toBeUndefined()
    })

    it('also handes 503 errors correctly ', async () => {
      expect(CourseActivitySummaryStore.getState().streams[1]).toBeUndefined() // precondition

      jest.spyOn(window, 'fetch').mockImplementation(() =>
        Promise.resolve().then(() => ({
          status: 503,
          statusText: 'Service Unavailable',
          json: () => {
            throw new Error('should never make it here')
          },
        }))
      )
      const errorFn = jest.fn()
      CourseActivitySummaryStore._fetchForCourse(1).catch(errorFn)
      await wait(1)
      expect(errorFn).toHaveBeenCalled()
      expect(CourseActivitySummaryStore.getState().streams[1]).toBeUndefined()
    })
  })
})
