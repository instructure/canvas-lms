/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as AssignmentActions from '../AssignmentActions'
import * as AssignmentApi from '../AssignmentApi'
import configureStore from '../../configureStore'

jest.mock('../AssignmentApi')

const flushPromises = () => new Promise(resolve => setTimeout(resolve))

describe('GradeSummary AssignmentActions', () => {
  let store

  beforeEach(() => {
    store = configureStore({
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}],
    })
  })

  describe('updateAssignment', () => {
    it('updates the assignment in the store', () => {
      store.dispatch(AssignmentActions.updateAssignment({gradesPublished: true}))
      const {assignment} = store.getState().assignment
      expect(assignment.gradesPublished).toBe(true)
    })
  })

  describe('releaseGrades', () => {
    let resolvePromise
    let rejectPromise

    beforeEach(() => {
      const mockPromise = new Promise((resolve, reject) => {
        resolvePromise = resolve
        rejectPromise = reject
      })
      AssignmentApi.releaseGrades.mockReturnValue(mockPromise)
      store.dispatch(AssignmentActions.releaseGrades())
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('sets the "release grades" status to "started"', () => {
      const {releaseGradesStatus} = store.getState().assignment
      expect(releaseGradesStatus).toBe(AssignmentActions.STARTED)
    })

    it('releases grades through the api', () => {
      expect(AssignmentApi.releaseGrades).toHaveBeenCalled()
    })

    it('includes the course id when releasing through the api', () => {
      expect(AssignmentApi.releaseGrades).toHaveBeenCalledWith('1201', expect.any(String))
    })

    it('includes the assignment id when releasing through the api', () => {
      expect(AssignmentApi.releaseGrades).toHaveBeenCalledWith(expect.any(String), '2301')
    })

    it('updates the assignment in the store when the request succeeds', async () => {
      resolvePromise()
      await flushPromises()
      const {assignment} = store.getState().assignment
      expect(assignment.gradesPublished).toBe(true)
    })

    it('sets the "release grades" status to "success" when the request succeeds', async () => {
      resolvePromise()
      await flushPromises()
      const {releaseGradesStatus} = store.getState().assignment
      expect(releaseGradesStatus).toBe(AssignmentActions.SUCCESS)
    })

    it('sets the "release grades" status to "already released" when grades were already released', async () => {
      rejectPromise({response: {status: 400}})
      await flushPromises()
      const {releaseGradesStatus} = store.getState().assignment
      expect(releaseGradesStatus).toBe(AssignmentActions.GRADES_ALREADY_RELEASED)
    })

    it('sets the "release grades" status to "not all selected" when a submission has no selected grade', async () => {
      rejectPromise({response: {status: 422}})
      await flushPromises()
      const {releaseGradesStatus} = store.getState().assignment
      expect(releaseGradesStatus).toBe(AssignmentActions.NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE)
    })

    it('sets the "release grades" status to "failure" when any other failure occurs', async () => {
      rejectPromise({response: {status: 500}})
      await flushPromises()
      const {releaseGradesStatus} = store.getState().assignment
      expect(releaseGradesStatus).toBe(AssignmentActions.FAILURE)
    })
  })

  describe('unmuteAssignment', () => {
    let resolvePromise
    let rejectPromise

    beforeEach(() => {
      const mockPromise = new Promise((resolve, reject) => {
        resolvePromise = resolve
        rejectPromise = reject
      })
      AssignmentApi.unmuteAssignment.mockReturnValue(mockPromise)
      store.dispatch(AssignmentActions.unmuteAssignment())
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('sets the "unmuted assignment" status to "started"', () => {
      const {unmuteAssignmentStatus} = store.getState().assignment
      expect(unmuteAssignmentStatus).toBe(AssignmentActions.STARTED)
    })

    it('unmutes assignment through the api', () => {
      expect(AssignmentApi.unmuteAssignment).toHaveBeenCalled()
    })

    it('includes the course id when unmuting through the api', () => {
      expect(AssignmentApi.unmuteAssignment).toHaveBeenCalledWith('1201', expect.any(String))
    })

    it('includes the assignment id when unmuting through the api', () => {
      expect(AssignmentApi.unmuteAssignment).toHaveBeenCalledWith(expect.any(String), '2301')
    })

    it('updates the assignment in the store when the request succeeds', async () => {
      resolvePromise()
      await flushPromises()
      const {assignment} = store.getState().assignment
      expect(assignment.muted).toBe(false)
    })

    it('sets the "unmuted assignment" status to "success" when the request succeeds', async () => {
      resolvePromise()
      await flushPromises()
      const {unmuteAssignmentStatus} = store.getState().assignment
      expect(unmuteAssignmentStatus).toBe(AssignmentActions.SUCCESS)
    })

    it('sets the "unmuted assignment" status to "failure" when the request fails', async () => {
      rejectPromise(new Error('server error'))
      await flushPromises()
      const {unmuteAssignmentStatus} = store.getState().assignment
      expect(unmuteAssignmentStatus).toBe(AssignmentActions.FAILURE)
    })
  })
})
