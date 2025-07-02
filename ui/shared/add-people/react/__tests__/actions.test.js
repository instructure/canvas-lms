/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import {createStore} from '../store'
import {actions, actionTypes} from '../actions'
import INITIAL_STATE from '@canvas/add-people/initialState'

const mockAxiosSuccess = (data = {}) => {
  jest.spyOn(axios, 'post').mockResolvedValue({
    data,
    status: 200,
    statusText: 'Ok',
    headers: {},
  })
}
const failureData = {
  message: 'Error',
  response: {
    data: 'Error',
    status: 400,
    statusText: 'Bad Request',
    headers: {},
  },
}
const mockAxiosFail = () => {
  jest.spyOn(axios, 'post').mockRejectedValue(failureData)
}
let store = null
let storeSpy = null
let runningState = INITIAL_STATE
const mockStore = (state = runningState) => {
  storeSpy = jest.fn()
  store = createStore((st, action) => {
    storeSpy(action)
    return st
  }, state)
}
const testConfig = () => ({
  beforeEach() {
    mockStore()
  },
  afterEach() {
    jest.restoreAllMocks()
  },
})

describe('Add People Actions', () => {
  describe('validateUsers', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('dispatches VALIDATE_USERS_START when called', () => {
      mockAxiosSuccess()
      store.dispatch(actions.validateUsers())
      expect(storeSpy).toHaveBeenCalledWith({type: actionTypes.VALIDATE_USERS_START})
    })

    test('dispatches VALIDATE_USERS_SUCCESS with data when successful', async () => {
      const apiResponse = {
        users: [],
        duplicates: [],
        missing: [],
        errors: [],
      }
      mockAxiosSuccess(apiResponse)
      store.dispatch(actions.validateUsers())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.VALIDATE_USERS_SUCCESS,
        payload: apiResponse,
      })
    })

    test.skip('dispatches ENQUEUE_USERS_TO_BE_ENROLLED with data when validate users returns no dupes or missings', async () => {
      const apiResponse = {
        users: [
          {
            address: 'auser@example.com',
            user_id: 2,
            user_name: 'A User',
            account_id: 1,
            account_name: 'The Account',
            email: 'auser@example.com',
          },
        ],
        duplicates: [],
        missing: [],
        errors: [],
      }
      mockAxiosSuccess(apiResponse)
      store.dispatch(actions.validateUsers())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED,
          payload: apiResponse.users,
        }),
      )
    })

    test('dispatches VALIDATE_USERS_ERROR with error when fails', async () => {
      mockAxiosFail()
      store.dispatch(actions.validateUsers())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.VALIDATE_USERS_ERROR,
        payload: failureData,
      })
    })
  })

  describe('resolveValidationIssues', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('dispatches CREATE_USERS_START when called', () => {
      mockAxiosSuccess()
      const testState = {
        ...INITIAL_STATE,
        userValidationResult: {
          duplicates: {
            'test@example.com': {
              selectedUserId: 1,
              userList: [
                {
                  user_id: 1,
                  name: 'Test User',
                  email: 'test@example.com',
                },
              ],
            },
          },
          missing: {},
          validUsers: [],
        },
        courseParams: {
          courseId: '1',
          inviteUsersURL: '/courses/1/invite_users',
        },
      }
      mockStore(testState)
      store.dispatch(actions.resolveValidationIssues())
      expect(storeSpy).toHaveBeenCalledWith({type: actionTypes.CREATE_USERS_START})
    })

    test.skip('dispatches CREATE_USERS_SUCCESS with data when successful', async () => {
      const newUser = {
        name: 'foo',
        email: 'foo@bar.com',
      }
      runningState.userValidationResult.duplicates = {
        foo: {
          createNew: true,
          newUserInfo: newUser,
        },
      }
      const apiResponse = {
        invited_users: [newUser],
        errored_users: [],
      }
      mockAxiosSuccess(apiResponse)
      store.dispatch(actions.resolveValidationIssues())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.CREATE_USERS_SUCCESS,
        payload: apiResponse,
      })
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED,
        payload: [newUser],
      })
    })

    test.skip('dispatches CREATE_USERS_ERROR with error when fails', async () => {
      mockAxiosFail()
      store.dispatch(actions.resolveValidationIssues())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.CREATE_USERS_ERROR,
        payload: failureData,
      })
    })
  })

  describe('enrollUsers', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('dispatches START when called', () => {
      mockAxiosSuccess()
      store.dispatch(actions.enrollUsers())
      expect(storeSpy).toHaveBeenCalledWith({type: actionTypes.ENROLL_USERS_START})
    })

    test('dispatches SUCCESS with data when successful', async () => {
      mockAxiosSuccess({data: 'foo'})
      store.dispatch(actions.enrollUsers(() => Promise.resolve()))
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.ENROLL_USERS_SUCCESS,
        payload: {data: 'foo'},
      })
    })

    test('dispatches ERROR with error when fails', async () => {
      mockAxiosFail()
      store.dispatch(actions.enrollUsers())
      // Wait for the promise to resolve
      await new Promise(resolve => setTimeout(resolve, 1))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.ENROLL_USERS_ERROR,
        payload: failureData,
      })
    })
  })

  describe('chooseDuplicate', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('dispatches dependent actions', () => {
      runningState = INITIAL_STATE
      runningState.userValidationResult.duplicates = {
        foo: {
          selectedUserId: 1,
          newUserInfo: {
            email: 'foo',
            name: 'bar',
          },
        },
      }
      store.dispatch(
        actions.chooseDuplicate({
          address: 'foo',
          user_id: 1,
        }),
      )
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.CHOOSE_DUPLICATE,
        payload: {
          address: 'foo',
          user_id: 1,
        },
      })
    })
  })

  describe('skipDuplicate', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('dispatches dependent actions', () => {
      store.dispatch(actions.skipDuplicate({address: 'foo'}))
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.SKIP_DUPLICATE,
        payload: {address: 'foo'},
      })
    })
  })

  describe('enqueue new ', () => {
    beforeEach(testConfig().beforeEach)
    afterEach(testConfig().afterEach)

    test('for duplicate dispatches dependent action', () => {
      const newUser = {
        name: 'Foo Bar',
        email: 'foo@bar.com',
      }
      store.dispatch(
        actions.enqueueNewForDuplicate({
          address: 'foo',
          newUserInfo: newUser,
        }),
      )
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.ENQUEUE_NEW_FOR_DUPLICATE,
        payload: {
          address: 'foo',
          newUserInfo: newUser,
        },
      })
    })

    test('for missing dispatches dependent action', () => {
      const newUser = {
        name: 'Foo Bar',
        email: 'foo@bar.com',
      }
      runningState.userValidationResult.missing = {foo: {newUserInfo: newUser}}
      store.dispatch(
        actions.enqueueNewForMissing({
          address: 'foo',
          newUser: newUser,
        }),
      )
      expect(storeSpy).toHaveBeenCalledWith({
        type: actionTypes.ENQUEUE_NEW_FOR_MISSING,
        payload: {
          address: 'foo',
          newUser: newUser,
        },
      })
    })
  })
})
