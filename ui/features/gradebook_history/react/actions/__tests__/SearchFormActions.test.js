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

import environment from '../../environment'
import GradebookHistoryStore from '../../store/GradebookHistoryStore'
import * as HistoryActions from '../HistoryActions'
import HistoryApi from '../../api/HistoryApi'
import SearchFormActions, {
  CLEAR_RECORDS,
  FETCH_RECORDS_START,
  FETCH_RECORDS_SUCCESS,
  FETCH_RECORDS_FAILURE,
  FETCH_RECORDS_NEXT_PAGE_START,
  FETCH_RECORDS_NEXT_PAGE_SUCCESS,
  FETCH_RECORDS_NEXT_PAGE_FAILURE,
} from '../SearchFormActions'
import UserApi from '../../api/UserApi'
import Fixtures from '@canvas/grading/Fixtures'

jest.mock('../../environment', () => ({
  courseId: jest.fn(() => '123'),
  courseIsConcluded: jest.fn(),
}))

jest.mock('../HistoryActions', () => ({
  fetchHistoryStart: jest.fn(() => ({type: 'fetchHistoryStart'})),
  fetchHistorySuccess: jest.fn(() => ({type: 'fetchHistorySuccess'})),
  fetchHistoryFailure: jest.fn(() => ({type: 'fetchHistoryFailure'})),
}))

describe('SearchFormActions', () => {
  describe('action creators', () => {
    const response = {
      data: Fixtures.userArray(),
      headers: {
        link: '<http://example.com/3?&page=first>; rel="current",<http://example.com/3?&page=bookmark:asdf>; rel="next"',
      },
    }

    it('creates an action with type FETCH_RECORDS_START', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_START,
        payload: {recordType},
      }

      expect(SearchFormActions.fetchRecordsStart(recordType)).toEqual(expectedValue)
    })

    it('creates an action with type FETCH_RECORDS_SUCCESS', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_SUCCESS,
        payload: {recordType, data: response.data, link: response.headers.link},
      }

      expect(SearchFormActions.fetchRecordsSuccess(response, recordType)).toEqual(expectedValue)
    })

    it('creates an action with type FETCH_RECORDS_FAILURE', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_FAILURE,
        payload: {recordType},
      }

      expect(SearchFormActions.fetchRecordsFailure(recordType)).toEqual(expectedValue)
    })

    it('creates an action with type FETCH_RECORDS_NEXT_PAGE_START', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_NEXT_PAGE_START,
        payload: {recordType},
      }

      expect(SearchFormActions.fetchRecordsNextPageStart(recordType)).toEqual(expectedValue)
    })

    it('creates an action with type FETCH_RECORDS_NEXT_PAGE_SUCCESS', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_NEXT_PAGE_SUCCESS,
        payload: {recordType, data: response.data, link: response.headers.link},
      }

      expect(SearchFormActions.fetchRecordsNextPageSuccess(response, recordType)).toEqual(
        expectedValue,
      )
    })

    it('creates an action with type FETCH_RECORDS_NEXT_PAGE_FAILURE', () => {
      const recordType = 'graders'
      const expectedValue = {
        type: FETCH_RECORDS_NEXT_PAGE_FAILURE,
        payload: {recordType},
      }

      expect(SearchFormActions.fetchRecordsNextPageFailure(recordType)).toEqual(expectedValue)
    })

    it('creates an action with type CLEAR_RECORDS', () => {
      const recordType = 'assignments'
      const expectedValue = {
        type: CLEAR_RECORDS,
        payload: {recordType},
      }

      expect(SearchFormActions.clearSearchOptions(recordType)).toEqual(expectedValue)
    })
  })

  describe('getGradebookHistory', () => {
    let response
    let getGradebookHistoryMock
    let dispatchMock

    beforeEach(() => {
      response = Fixtures.historyResponse()
      getGradebookHistoryMock = jest
        .spyOn(HistoryApi, 'getGradebookHistory')
        .mockResolvedValue(response)
      dispatchMock = jest.fn()
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('dispatches fetchHistoryStart', async () => {
      const thunk = SearchFormActions.getGradebookHistory({})
      await thunk(dispatchMock)
      expect(HistoryActions.fetchHistoryStart).toHaveBeenCalled()
      expect(dispatchMock).toHaveBeenCalledWith({type: 'fetchHistoryStart'})
    })

    it('dispatches fetchHistorySuccess on success', async () => {
      const thunk = SearchFormActions.getGradebookHistory({})
      await thunk(dispatchMock)
      expect(HistoryActions.fetchHistorySuccess).toHaveBeenCalledWith(
        response.data,
        response.headers,
      )
      expect(dispatchMock).toHaveBeenCalledWith({type: 'fetchHistorySuccess'})
    })

    it('dispatches fetchHistoryFailure on failure', async () => {
      const error = new Error('FAIL')
      getGradebookHistoryMock.mockRejectedValue(error)
      const thunk = SearchFormActions.getGradebookHistory({})
      await thunk(dispatchMock)
      expect(HistoryActions.fetchHistoryFailure).toHaveBeenCalled()
      expect(dispatchMock).toHaveBeenCalledWith({type: 'fetchHistoryFailure'})
    })
  })

  describe('getSearchOptions', () => {
    let userResponse
    let getUsersByNameMock
    let courseIsConcludedMock
    let dispatchMock

    beforeEach(() => {
      userResponse = {
        data: Fixtures.userArray(),
        headers: {link: 'http://example.com/link-to-next-page'},
      }
      getUsersByNameMock = jest.spyOn(UserApi, 'getUsersByName').mockResolvedValue(userResponse)
      courseIsConcludedMock = jest.spyOn(environment, 'courseIsConcluded')
      dispatchMock = jest.fn()
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('dispatches fetchRecordsStart', async () => {
      const fetchSpy = jest.spyOn(SearchFormActions, 'fetchRecordsStart')
      const thunk = SearchFormActions.getSearchOptions('assignments', '50 Page Essay')
      await thunk(dispatchMock)
      expect(fetchSpy).toHaveBeenCalledTimes(1)
    })

    it('dispatches fetchRecordsSuccess on success', async () => {
      const fetchSpy = jest.spyOn(SearchFormActions, 'fetchRecordsSuccess')
      const thunk = SearchFormActions.getSearchOptions('graders', 'Norval')
      await thunk(dispatchMock)
      expect(fetchSpy).toHaveBeenCalledWith(userResponse, 'graders')
    })

    it('dispatches fetchRecordsFailure on failure', async () => {
      const error = new Error('FAIL')
      getUsersByNameMock.mockRejectedValue(error)
      const fetchSpy = jest.spyOn(SearchFormActions, 'fetchRecordsFailure')
      const thunk = SearchFormActions.getSearchOptions('students', 'Norval')
      await thunk(dispatchMock)
      expect(fetchSpy).toHaveBeenCalledTimes(1)
    })

    it('calls getUsersByName with empty array for enrollmentStates if course is not concluded', async () => {
      courseIsConcludedMock.mockReturnValue(false)
      const thunk = SearchFormActions.getSearchOptions('graders', 'Norval')
      await thunk(dispatchMock)
      expect(getUsersByNameMock).toHaveBeenCalledWith('123', 'graders', 'Norval', [])
    })
  })
})
