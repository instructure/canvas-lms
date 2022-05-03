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

import fetchMock from 'fetch-mock'
import {screen, waitFor} from '@testing-library/react'

import {actions as uiActions} from '../ui'
import {coursePaceActions, PUBLISH_STATUS_POLLING_MS} from '../course_paces'
import {
  BLACKOUT_DATES,
  DEFAULT_BLACKOUT_DATE_STATE,
  COURSE,
  DEFAULT_STORE_STATE,
  PRIMARY_PACE,
  PROGRESS_FAILED,
  PROGRESS_RUNNING
} from '../../__tests__/fixtures'
import {SyncState} from '../../shared/types'

const CREATE_API = `/api/v1/courses/${COURSE.id}/course_pacing`
const UPDATE_API = `/api/v1/courses/${COURSE.id}/course_pacing/${PRIMARY_PACE.id}`
const PROGRESS_API = `/api/v1/progress/${PROGRESS_RUNNING.id}`
const COMPRESS_API = `/api/v1/courses/${COURSE.id}/course_pacing/compress_dates`

const dispatch = jest.fn()

const mockGetState =
  (
    pace,
    originalPace,
    blackoutDates = DEFAULT_BLACKOUT_DATE_STATE,
    originalBlackoutDates = BLACKOUT_DATES
  ) =>
  () => ({
    ...DEFAULT_STORE_STATE,
    coursePace: {...pace},
    blackoutDates,
    original: {
      coursePace: originalPace,
      blackoutDates: originalBlackoutDates
    }
  })

beforeEach(() => {
  jest.useFakeTimers()
  jest.spyOn(global, 'setTimeout')
})

afterEach(() => {
  jest.clearAllMocks()
  jest.useRealTimers()
  fetchMock.restore()
})

describe('Course paces actions', () => {
  describe('publishPace', () => {
    it('Updates pace, manages loading state, and starts polling for publish status', async () => {
      const updatedPace = {...PRIMARY_PACE, excludeWeekends: false}
      const getState = mockGetState(updatedPace, PRIMARY_PACE)
      fetchMock.put(UPDATE_API, {
        course_pace: updatedPace,
        progress: PROGRESS_RUNNING
      })

      const thunkedAction = coursePaceActions.publishPace()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([uiActions.startSyncing()])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('publish')])
      expect(dispatch.mock.calls[2]).toEqual([coursePaceActions.saveCoursePace(updatedPace)])
      expect(dispatch.mock.calls[3]).toEqual([coursePaceActions.setProgress(PROGRESS_RUNNING)])
      // Compare dispatched functions by name since they won't be directly equal
      expect(JSON.stringify(dispatch.mock.calls[4])).toEqual(
        JSON.stringify([coursePaceActions.pollForPublishStatus()])
      )
      expect(dispatch.mock.calls[5]).toEqual([uiActions.syncingCompleted()])
      expect(fetchMock.called(UPDATE_API, 'PUT')).toBe(true)
    })

    it('Calls create API when an ID is not present', async () => {
      fetchMock.post(CREATE_API, {course_pace: {...PRIMARY_PACE}, progress: PROGRESS_RUNNING})
      const paceToCreate = {...PRIMARY_PACE, id: undefined}
      const getState = mockGetState(paceToCreate, paceToCreate)

      const thunkedAction = coursePaceActions.publishPace()
      await thunkedAction(dispatch, getState)

      expect(fetchMock.called(CREATE_API, 'POST')).toBe(true)
    })

    it('Sets an error message if the pace update fails', async () => {
      const updatedPace = {...PRIMARY_PACE, excludeWeekends: false}
      const error = new Error("You don't actually want to publish this")
      const getState = mockGetState(updatedPace, PRIMARY_PACE)
      fetchMock.put(UPDATE_API, {
        throws: error
      })

      const thunkedAction = coursePaceActions.publishPace()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.startSyncing()],
        [uiActions.clearCategoryError('publish')],
        [uiActions.setCategoryError('publish', error.toString())],
        [uiActions.syncingCompleted()]
      ])
    })
  })

  describe('pollForPublishState', () => {
    it('does nothing without a progress or for progresses in terminal statuses', () => {
      const getStateNoProgress = () => ({...DEFAULT_STORE_STATE})
      coursePaceActions.pollForPublishStatus()(dispatch, getStateNoProgress)

      const getStateFailed = () => ({
        ...DEFAULT_STORE_STATE,
        coursePace: {publishingProgress: PROGRESS_FAILED}
      })
      coursePaceActions.pollForPublishStatus()(dispatch, getStateFailed)

      const getStateCompleted = () => ({
        ...DEFAULT_STORE_STATE,
        coursePace: {publishingProgress: {...PROGRESS_FAILED, workflow_state: 'completed'}}
      })
      coursePaceActions.pollForPublishStatus()(dispatch, getStateCompleted)

      expect(dispatch).not.toHaveBeenCalled()
    })

    it('sets a timeout that updates progress status and clears when a terminal status is reached', async () => {
      const getState = () => ({
        ...DEFAULT_STORE_STATE,
        coursePace: {publishingProgress: {...PROGRESS_RUNNING}}
      })
      const progressUpdated = {...PROGRESS_RUNNING, completion: 60}
      fetchMock.get(PROGRESS_API, progressUpdated)

      await coursePaceActions.pollForPublishStatus()(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([coursePaceActions.setProgress(progressUpdated)])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('checkPublishStatus')])
      expect(setTimeout).toHaveBeenCalledTimes(1)

      const progressCompleted = {...PROGRESS_RUNNING, completion: 100, workflow_state: 'completed'}
      fetchMock.get(PROGRESS_API, progressCompleted, {overwriteRoutes: true})

      jest.advanceTimersByTime(PUBLISH_STATUS_POLLING_MS)

      await waitFor(() => {
        expect(dispatch.mock.calls.length).toBe(5)
        expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('checkPublishStatus')])
        expect(dispatch.mock.calls[2]).toEqual([coursePaceActions.setProgress(undefined)])
        expect(dispatch.mock.calls[4]).toEqual([
          coursePaceActions.coursePaceSaved(getState().coursePace)
        ])
        expect(screen.getByText('Finished publishing pace')).toBeInTheDocument()
      })
    })

    it('stops polling and displays an error message if checking the progress API fails', async () => {
      const getState = () => ({
        ...DEFAULT_STORE_STATE,
        coursePace: {publishingProgress: {...PROGRESS_RUNNING}}
      })
      const error = new Error('Progress? What progress?')
      fetchMock.get(PROGRESS_API, {throws: error})

      await coursePaceActions.pollForPublishStatus()(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.setCategoryError('checkPublishStatus', error?.toString())]
      ])
      expect(setTimeout).not.toHaveBeenCalled()
    })
  })

  describe('compressDates', () => {
    it('Updates pace and manages loading state', async () => {
      const updatedPace = {...PRIMARY_PACE}
      const getState = mockGetState(updatedPace, PRIMARY_PACE)
      const compressResponse = {
        1: 'a date',
        2: 'another date'
      }
      fetchMock.post(COMPRESS_API, compressResponse)

      const thunkedAction = coursePaceActions.compressDates()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([uiActions.showLoadingOverlay('Compressing...')])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('compress')])
      expect(dispatch.mock.calls[2]).toEqual([
        coursePaceActions.setCompressedItemDates(compressResponse)
      ])
      // Compare dispatched functions by name since they won't be directly equal
      expect(dispatch.mock.calls[3]).toEqual([uiActions.hideLoadingOverlay()])
      // compress() POSTs a flattened and stripped-down version of the course pace
      expect(fetchMock.calls()[0][1]?.body).toEqual(
        JSON.stringify({
          course_pace: {
            start_date: updatedPace.start_date,
            end_date: updatedPace.end_date,
            exclude_weekends: updatedPace.exclude_weekends,
            course_pace_module_items_attributes: updatedPace.modules.reduce(
              (runningValue: Array<any>, module) => {
                return runningValue.concat(
                  module.items.map(item => ({
                    id: item.id,
                    duration: item.duration,
                    module_item_id: item.module_item_id
                  }))
                )
              },
              []
            )
          }
        })
      )
      expect(fetchMock.called(COMPRESS_API, 'POST')).toBe(true)
    })

    it('Sets an error message if compression fails', async () => {
      const updatedPace = {...PRIMARY_PACE}
      const error = new Error('Whoops!')
      const getState = mockGetState(updatedPace, PRIMARY_PACE)
      fetchMock.post(COMPRESS_API, {
        throws: error
      })

      const thunkedAction = coursePaceActions.compressDates()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.showLoadingOverlay('Compressing...')],
        [uiActions.clearCategoryError('compress')],
        [uiActions.hideLoadingOverlay()],
        [uiActions.setCategoryError('compress', error.toString())]
      ])
    })
  })

  describe('syncUnpublishedChanges', () => {
    it('saves blackout dates and publishes the pace', async () => {
      const asyncDispatch = jest.fn(() => Promise.resolve())
      const updatedPace = {...PRIMARY_PACE, excludeWeekends: false}
      const getState = mockGetState(updatedPace, PRIMARY_PACE, {
        syncing: SyncState.UNSYNCED,
        blackoutDates: BLACKOUT_DATES
      })

      const thunkedAction = coursePaceActions.syncUnpublishedChanges()
      await thunkedAction(asyncDispatch, getState)

      expect(asyncDispatch.mock.calls.length).toBe(5)
      expect(asyncDispatch.mock.calls[0]).toEqual([uiActions.clearCategoryError('publish')])
      expect(asyncDispatch.mock.calls[1]).toEqual([uiActions.startSyncing()])
      expect(typeof asyncDispatch.mock.calls[2][0]).toBe('function') // dispatch syncBlackoutDates
      expect(typeof asyncDispatch.mock.calls[3][0]).toBe('function') // dispatch publishPace
      expect(asyncDispatch.mock.calls[4]).toEqual([uiActions.syncingCompleted()])
    })

    it('only publishes the pace if blackout dates have not changed', async () => {
      const asyncDispatch = jest.fn(() => Promise.resolve())
      const updatedPace = {...PRIMARY_PACE, excludeWeekends: false}
      const getState = mockGetState(updatedPace, PRIMARY_PACE)

      const thunkedAction = coursePaceActions.syncUnpublishedChanges()
      await thunkedAction(asyncDispatch, getState)

      expect(asyncDispatch.mock.calls.length).toBe(2)
    })
  })
})
