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
import {pacePlanActions, PUBLISH_STATUS_POLLING_MS} from '../pace_plans'
import {
  COURSE,
  DEFAULT_STORE_STATE,
  PRIMARY_PLAN,
  PROGRESS_FAILED,
  PROGRESS_RUNNING
} from '../../__tests__/fixtures'

const CREATE_API = `/api/v1/courses/${COURSE.id}/pace_plans`
const UPDATE_API = `/api/v1/courses/${COURSE.id}/pace_plans/${PRIMARY_PLAN.id}`
const PROGRESS_API = `/api/v1/progress/${PROGRESS_RUNNING.id}`
const COMPRESS_API = `/api/v1/courses/${COURSE.id}/pace_plans/compress_dates`

const dispatch = jest.fn()

const mockGetState = (plan, originalPlan) => () => ({
  ...DEFAULT_STORE_STATE,
  pacePlan: {...plan},
  originalPlan: {...originalPlan}
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

describe('Pace plans actions', () => {
  describe('publishPlan', () => {
    it('Updates plan, manages loading state, and starts polling for publish status', async () => {
      const updatedPlan = {...PRIMARY_PLAN, excludeWeekends: false}
      const getState = mockGetState(updatedPlan, PRIMARY_PLAN)
      fetchMock.put(UPDATE_API, {
        pace_plan: updatedPlan,
        progress: PROGRESS_RUNNING
      })

      const thunkedAction = pacePlanActions.publishPlan()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([uiActions.showLoadingOverlay('Starting publish...')])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('publish')])
      expect(dispatch.mock.calls[2]).toEqual([pacePlanActions.setPacePlan(updatedPlan)])
      expect(dispatch.mock.calls[3]).toEqual([pacePlanActions.setProgress(PROGRESS_RUNNING)])
      // Compare dispatched functions by name since they won't be directly equal
      expect(JSON.stringify(dispatch.mock.calls[4])).toEqual(
        JSON.stringify([pacePlanActions.pollForPublishStatus()])
      )
      expect(dispatch.mock.calls[5]).toEqual([uiActions.hideLoadingOverlay()])
      expect(fetchMock.called(UPDATE_API, 'PUT')).toBe(true)
    })

    it('Calls create API when an ID is not present', async () => {
      fetchMock.post(CREATE_API, {pace_plan: {...PRIMARY_PLAN}, progress: PROGRESS_RUNNING})
      const planToCreate = {...PRIMARY_PLAN, id: undefined}
      const getState = mockGetState(planToCreate, planToCreate)

      const thunkedAction = pacePlanActions.publishPlan()
      await thunkedAction(dispatch, getState)

      expect(fetchMock.called(CREATE_API, 'POST')).toBe(true)
    })

    it('Sets an error message if the plan update fails', async () => {
      const updatedPlan = {...PRIMARY_PLAN, excludeWeekends: false}
      const error = new Error("You don't actually want to publish this")
      const getState = mockGetState(updatedPlan, PRIMARY_PLAN)
      fetchMock.put(UPDATE_API, {
        throws: error
      })

      const thunkedAction = pacePlanActions.publishPlan()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.showLoadingOverlay('Starting publish...')],
        [uiActions.clearCategoryError('publish')],
        [uiActions.hideLoadingOverlay()],
        [uiActions.setCategoryError('publish', error.toString())]
      ])
    })
  })

  describe('pollForPublishState', () => {
    it('does nothing without a progress or for progresses in terminal statuses', () => {
      const getStateNoProgress = () => ({...DEFAULT_STORE_STATE})
      pacePlanActions.pollForPublishStatus()(dispatch, getStateNoProgress)

      const getStateFailed = () => ({
        ...DEFAULT_STORE_STATE,
        pacePlan: {publishingProgress: PROGRESS_FAILED}
      })
      pacePlanActions.pollForPublishStatus()(dispatch, getStateFailed)

      const getStateCompleted = () => ({
        ...DEFAULT_STORE_STATE,
        pacePlan: {publishingProgress: {...PROGRESS_FAILED, workflow_state: 'completed'}}
      })
      pacePlanActions.pollForPublishStatus()(dispatch, getStateCompleted)

      expect(dispatch).not.toHaveBeenCalled()
    })

    it('sets a timeout that updates progress status and clears when a terminal status is reached', async () => {
      const getState = () => ({
        ...DEFAULT_STORE_STATE,
        pacePlan: {publishingProgress: {...PROGRESS_RUNNING}}
      })
      const progressUpdated = {...PROGRESS_RUNNING, completion: 60}
      fetchMock.get(PROGRESS_API, progressUpdated)

      await pacePlanActions.pollForPublishStatus()(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([pacePlanActions.setProgress(progressUpdated)])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('checkPublishStatus')])
      expect(setTimeout).toHaveBeenCalledTimes(1)

      const progressCompleted = {...PROGRESS_RUNNING, completion: 100, workflow_state: 'completed'}
      fetchMock.get(PROGRESS_API, progressCompleted, {overwriteRoutes: true})

      jest.advanceTimersByTime(PUBLISH_STATUS_POLLING_MS)

      await waitFor(() => {
        expect(dispatch.mock.calls.length).toBe(4)
        expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('checkPublishStatus')])
        expect(dispatch.mock.calls[2]).toEqual([pacePlanActions.setProgress(undefined)])
        expect(screen.getByText('Finished publishing plan')).toBeInTheDocument()
      })
    })

    it('stops polling and displays an error message if checking the progress API fails', async () => {
      const getState = () => ({
        ...DEFAULT_STORE_STATE,
        pacePlan: {publishingProgress: {...PROGRESS_RUNNING}}
      })
      const error = new Error('Progress? What progress?')
      fetchMock.get(PROGRESS_API, {throws: error})

      await pacePlanActions.pollForPublishStatus()(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.setCategoryError('checkPublishStatus', error?.toString())]
      ])
      expect(setTimeout).not.toHaveBeenCalled()
    })
  })

  describe('compressDates', () => {
    it('Updates plan and manages loading state', async () => {
      const updatedPlan = {...PRIMARY_PLAN}
      const getState = mockGetState(updatedPlan, PRIMARY_PLAN)
      const compressResponse = {
        1: 'a date',
        2: 'another date'
      }
      fetchMock.post(COMPRESS_API, compressResponse)

      const thunkedAction = pacePlanActions.compressDates()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls[0]).toEqual([uiActions.showLoadingOverlay('Compressing...')])
      expect(dispatch.mock.calls[1]).toEqual([uiActions.clearCategoryError('compress')])
      expect(dispatch.mock.calls[2]).toEqual([
        pacePlanActions.setCompressedItemDates(compressResponse)
      ])
      // Compare dispatched functions by name since they won't be directly equal
      expect(dispatch.mock.calls[3]).toEqual([uiActions.hideLoadingOverlay()])
      // compress() POSTs a flattened and stripped-down version of the pace plan
      expect(fetchMock.calls()[0][1].body).toEqual(
        JSON.stringify({
          pace_plan: {
            start_date: updatedPlan.start_date,
            end_date: updatedPlan.end_date,
            exclude_weekends: updatedPlan.exclude_weekends,
            pace_plan_module_items_attributes: updatedPlan.modules.reduce(
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
      const updatedPlan = {...PRIMARY_PLAN}
      const error = new Error('Whoops!')
      const getState = mockGetState(updatedPlan, PRIMARY_PLAN)
      fetchMock.post(COMPRESS_API, {
        throws: error
      })

      const thunkedAction = pacePlanActions.compressDates()
      await thunkedAction(dispatch, getState)

      expect(dispatch.mock.calls).toEqual([
        [uiActions.showLoadingOverlay('Compressing...')],
        [uiActions.clearCategoryError('compress')],
        [uiActions.hideLoadingOverlay()],
        [uiActions.setCategoryError('compress', error.toString())]
      ])
    })
  })
})
