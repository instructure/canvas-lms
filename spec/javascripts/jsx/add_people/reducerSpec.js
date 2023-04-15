/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {cloneDeep} from 'lodash'
import {actions} from '@canvas/add-people/react/actions'
import reducer from '@canvas/add-people/react/reducer'

// dummy test data ---------------
// duplicates as returned by the api, search by unique_id/login
const rawDupeList = [
  [
    {
      address: 'bob',
      user_name: 'Bob Barker',
      email: 'bob@deal.com',
      login_id: 'bob',
      account_id: 1,
      account_name: 'TV Land',
      user_id: 1,
    },
    {
      address: 'bob',
      user_name: 'Bob Weir',
      email: 'bob@thedead.org',
      login: 'bob',
      account_id: 2,
      account_name: 'Grateful Dead',
      user_id: 2,
    },
    {
      address: 'bob',
      user_name: 'Bob Ross',
      email: 'bob@pbs.org',
      login: 'bob',
      account_id: 3,
      account_name: 'PBS',
      user_id: 3,
    },
  ],
  [
    {
      address: 'sally',
      user_name: 'Sally Ride',
      email: 'sally@nasa.gov',
      login_id: 'sally',
      account_id: 4,
      account_name: 'NASA',
      user_id: 4,
    },
    {
      address: 'sally',
      user_name: 'Sally Field',
      email: 'sally@flyingnun.tv',
      login_id: 'sally',
      account_id: 5,
      account_name: 'Hollywood',
      user_id: 5,
    },
    {
      address: 'sally',
      user_name: 'Sally Jessy Raphael',
      email: 'sally@radio.com',
      login_id: 'sally',
      account_id: 6,
      account_name: null,
      user_id: 6,
    },
  ],
]
// same duplicates after they are transformed by the validate_users_success reducer
const dupeList = {
  bob: {
    address: 'bob',
    createNew: false,
    newUserInfo: undefined,
    selectedUserId: -1,
    skip: false,
    userList: [
      {
        address: 'bob',
        user_name: 'Bob Barker',
        email: 'bob@deal.com',
        login_id: 'bob',
        account_id: 1,
        account_name: 'TV Land',
        user_id: 1,
      },
      {
        address: 'bob',
        user_name: 'Bob Weir',
        email: 'bob@thedead.org',
        login: 'bob',
        account_id: 2,
        account_name: 'Grateful Dead',
        user_id: 2,
      },
      {
        address: 'bob',
        user_name: 'Bob Ross',
        email: 'bob@pbs.org',
        login: 'bob',
        account_id: 3,
        account_name: 'PBS',
        user_id: 3,
      },
    ],
  },
  sally: {
    address: 'sally',
    createNew: false,
    newUserInfo: undefined,
    selectedUserId: -1,
    skip: false,
    userList: [
      {
        address: 'sally',
        user_name: 'Sally Ride',
        email: 'sally@nasa.gov',
        login_id: 'sally',
        account_id: 4,
        account_name: 'NASA',
        user_id: 4,
      },
      {
        address: 'sally',
        user_name: 'Sally Field',
        email: 'sally@flyingnun.tv',
        login_id: 'sally',
        account_id: 5,
        account_name: 'Hollywood',
        user_id: 5,
      },
      {
        address: 'sally',
        user_name: 'Sally Jessy Raphael',
        email: 'sally@radio.com',
        login_id: 'sally',
        account_id: 6,
        account_name: null,
        user_id: 6,
      },
    ],
  },
}

// missing by login, as returned by the api
const rawMissingList = [
  {address: 'amelia', type: 'unique_id'},
  {address: 'dbcooper', type: 'unique_id'},
]
// missing by login after transformed by validate_user_success reducer
const missingList = {
  amelia: {
    address: 'amelia',
    createNew: false,
    type: 'unique_id',
    newUserInfo: {email: '', name: ''},
  },
  dbcooper: {
    address: 'dbcooper',
    createNew: false,
    type: 'unique_id',
    newUserInfo: {email: '', name: ''},
  },
}

const goodUsers = [
  {
    address: 'john',
    user_name: 'John Lennon',
    account_id: 8,
    account_name: 'British Invasion',
    user_id: 7,
  },
  {
    address: 'paul',
    user_name: 'Paul McCartney',
    account_id: 8,
    account_name: 'British Invasion',
    user_id: 8,
  },
  {
    address: 'georg',
    user_name: 'George Harrison',
    account_id: 8,
    account_name: 'British Invasion',
    user_id: 9,
  },
  {
    address: 'ringo',
    user_name: 'Ringo Starr',
    account_id: 8,
    account_name: 'British Invasion',
    user_id: 10,
  },
]

const INITIAL_STATE = {
  courseParams: {
    courseId: '1',
    roles: [{id: 1}, {id: 2}, {id: 3}],
    sections: [{id: 1}, {id: 2}, {id: 3}],
  },
  inputParams: {
    searchType: 'cc_path',
    nameList: '',
    role: '',
    section: '',
    limitPrivilege: false,
    canReadSIS: true,
  },
  apiState: {
    pendingCount: 0, // >0 while api calls are in-flight
    error: undefined, // api error message
  },
  userValidationResult: {
    validUsers: [], // the validated users
    duplicates: {}, // key: address, value: instance of duplicateShape
    missing: {}, // key: address, value: instance of missingShape
  },
  usersToBeEnrolled: [], // key: user_id, value: {user_id, name, email, ...}
  usersEnrolled: false, // true when students have been enrolled and we're finished
}

const USER_BOB = {email: 'bob@npr.org', name: 'Bob Villa'}
const USER_AMELIA = {email: 'amelia@lost.org', name: 'Amelia Earhart'}

const API_VALIDATION_RESPONSE1 = {
  users: goodUsers,
  duplicates: rawDupeList,
  missing: rawMissingList,
  errors: [],
}

const API_CREATE_RESPONSE1 = {
  invited_users: [{email: 'bob@npr.org', id: 11}],
  errored_users: [],
}
const API_CREATE_RESPONSE2 = {
  invited_users: [{email: 'bob@npr.org', id: 11}],
  errored_users: [
    {
      email: 'no@nope.net',
      errors: [{message: 'Error message'}],
      existing_users: [
        {
          address: 'who@cares.net',
          user_id: 12,
          user_name: 'Who Cares',
          account_id: 1,
          account_name: 'TV Land',
        },
      ],
    },
  ],
}
const API_ENROLL_RESPONSE = [{}, {}]

// the tests ---------------------
QUnit.module('Course Enrollment Add People Reducer')

const reduce = (action, state = INITIAL_STATE) => reducer(state, action)

let runningState = cloneDeep(INITIAL_STATE)

test('set input paramaters', () => {
  const newSearchParams = {
    fieldType: 'unique_id',
    nameList: 'foo, bar, baz',
    role: '2',
    secion: '2',
    limitPrivilege: true,
  }
  const newState = reduce(actions.setInputParams(newSearchParams))
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, newSearchParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')
  deepEqual(
    newState.userValidationResult,
    INITIAL_STATE.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
})

// validating users
test('VALIDATE_USERS_START', () => {
  const newState = reduce(actions.validateUsersStart(runningState))
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 1, error: undefined}, 'apiState')
  deepEqual(
    newState.userValidationResult,
    INITIAL_STATE.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('VALIDATE_USERS_SUCCESS', () => {
  const newState = reduce(actions.validateUsersSuccess(API_VALIDATION_RESPONSE1), runningState)
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  deepEqual(newState.userValidationResult.duplicates, dupeList, 'userValidationResult.duplicates')
  deepEqual(newState.userValidationResult.missing, missingList, 'userValidationResult.missing')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')

  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('VALIDATE_USERS_ERROR', () => {
  const state = cloneDeep(INITIAL_STATE)
  state.apiState.pendingCount = 1
  const newState = reduce(actions.validateUsersError('whoops'), state)
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(
    newState.apiState,
    {pendingCount: 0, error: 'whoops'},
    'api is no longer in-flight with error'
  )
  deepEqual(
    newState.userValidationResult,
    INITIAL_STATE.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
})

// manipulating duplicates
test('CHOOSE_DUPLICATE', () => {
  // choose bob weir
  const newState = reduce(actions.chooseDuplicate({address: 'bob', user_id: '2'}), runningState)
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  equal(newState.userValidationResult.duplicates.bob.createNew, false, 'duplicate set createNew')
  equal(
    newState.userValidationResult.duplicates.bob.selectedUserId,
    2,
    'duplicate set selectedUserId'
  )
  equal(newState.userValidationResult.duplicates.bob.skip, false, 'duplicate set skip')

  deepEqual(newState.userValidationResult.missing, missingList, 'userValidationResult.missing')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('SKIP_DUPLICATE', () => {
  // skip the bobs
  const newState = reduce(actions.skipDuplicate('bob'), runningState)
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  equal(newState.userValidationResult.duplicates.bob.createNew, false, 'duplicate set createNew')
  equal(
    newState.userValidationResult.duplicates.bob.selectedUserId,
    -1,
    'duplicate set selectedUserId'
  )
  equal(newState.userValidationResult.duplicates.bob.skip, true, 'duplicate set skip')

  deepEqual(newState.userValidationResult.missing, missingList, 'userValidationResult.missing')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('ENQUEUE_NEW_FOR_DUPLICATE', () => {
  // create a new bob
  const newState = reduce(
    actions.enqueueNewForDuplicate({address: 'bob', newUserInfo: USER_BOB}),
    runningState
  )
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  equal(newState.userValidationResult.duplicates.bob.createNew, true, 'duplicate set createNew')
  equal(
    newState.userValidationResult.duplicates.bob.selectedUserId,
    -1,
    'duplicate set selectedUserId'
  )
  equal(newState.userValidationResult.duplicates.bob.skip, false, 'duplicate set skip')
  deepEqual(
    newState.userValidationResult.duplicates.bob.newUserInfo,
    USER_BOB,
    'duplicate set newUserInfo'
  )

  deepEqual(newState.userValidationResult.missing, missingList, 'userValidationResult.missing')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})

// manipulating missing users
test('ENQUEUE_NEW_FOR_MISSING', () => {
  // reset state to just after validation
  runningState.userValidationResult.duplicates = cloneDeep(dupeList)

  // create a new user for amelia
  const newState = reduce(
    actions.enqueueNewForMissing({address: 'amelia', newUserInfo: USER_AMELIA}),
    runningState
  )

  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  equal(newState.userValidationResult.missing.amelia.createNew, true, 'missing entry set createNew')
  deepEqual(
    newState.userValidationResult.missing.amelia.newUserInfo,
    USER_AMELIA,
    'missing entry has newUserInfo'
  )

  deepEqual(newState.userValidationResult.duplicates, dupeList, 'userValidationResult.dupliates')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('ENQUEUE_NEW_FOR_MISSING, unselect user', () => {
  const newState = reduce(
    actions.enqueueNewForMissing({address: 'amelia', newUserInfo: false}),
    runningState
  )
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')

  equal(
    newState.userValidationResult.missing.amelia.createNew,
    false,
    'missing entry unset createNew'
  )
  deepEqual(
    newState.userValidationResult.missing.amelia.newUserInfo,
    USER_AMELIA,
    'missing entry still has newUserInfo'
  )

  deepEqual(newState.userValidationResult.duplicates, dupeList, 'userValidationResult.dupliates')
  deepEqual(newState.userValidationResult.validUsers, goodUsers, 'userValidationResult.avalidUsers')
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
// creating users
test('CREATE_USERS_START', () => {
  const newState = reduce(actions.createUsersStart(), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 1, error: undefined}, 'api is in-flight')
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, runningState.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('CREATE_USERS_SUCCESS', () => {
  const newState = reduce(actions.createUsersSuccess(API_CREATE_RESPONSE1), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 0, error: undefined}, 'api is no longer in-flight')
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, runningState.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('CREATE_USERS_SUCCESS, with error', () => {
  runningState.apiState.pendingCount = 1
  const newState = reduce(actions.createUsersSuccess(API_CREATE_RESPONSE2), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 0, error: ['no@nope.net: Error message']})
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, runningState.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('ENROLL_USERS_ERROR', () => {
  const state = cloneDeep(runningState)
  state.apiState.pendingCount = 1
  const newState = reduce(actions.createUsersError({response: {data: 'uh oh'}}), state)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(
    newState.apiState,
    {pendingCount: 0, error: 'uh oh'},
    'api is no longer in-flight and has error'
  )
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, runningState.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
})

// enrolling users
test('ENQUEUE_USERS_TO_BE_ENROLLED', () => {
  const newState = reduce(actions.enqueueUsersToBeEnrolled(goodUsers), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, runningState.apiState, 'apiState')
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, goodUsers, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('ENROLL_USERS_STARTt', () => {
  const newState = reduce(actions.enrollUsersStart(), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 1, error: undefined}, 'api is in-flight')
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, goodUsers, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, runningState.usersEnrolled, 'usersEnrolled')
  runningState = newState
})
test('ENROLL_USERS_SUCCESS', () => {
  const newState = reduce(actions.enrollUsersSuccess(API_ENROLL_RESPONSE), runningState)
  deepEqual(newState.courseParams, runningState.courseParams, 'courseParams')
  deepEqual(newState.inputParams, runningState.inputParams, 'inputParams')
  deepEqual(newState.apiState, {pendingCount: 0, error: undefined}, 'api is no longer in-flight')
  deepEqual(
    newState.userValidationResult,
    runningState.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, [], 'usersToBeEnrolled is emptied')
  equal(Boolean(newState.usersEnrolled), true, 'usersEnrolled')
})
test('ENROLL_USERS_ERROR (2)', () => {
  const state = cloneDeep(INITIAL_STATE)
  state.apiState.pendingCount = 1
  const newState = reduce(actions.enrollUsersError('whoops'), state)
  deepEqual(
    newState.apiState,
    {pendingCount: 0, error: 'whoops'},
    'api is no longer in-flight and has error'
  )
})
test(' ', () => {
  const newState = reduce(actions.reset(), runningState)
  deepEqual(newState.courseParams, INITIAL_STATE.courseParams, 'courseParams')
  deepEqual(newState.inputParams, INITIAL_STATE.inputParams, 'inputParams')
  deepEqual(newState.apiState, INITIAL_STATE.apiState, 'apiState')
  deepEqual(
    newState.userValidationResult,
    INITIAL_STATE.userValidationResult,
    'userValidationResult'
  )
  deepEqual(newState.usersToBeEnrolled, INITIAL_STATE.usersToBeEnrolled, 'usersToBeEnrolled')
  equal(newState.usersEnrolled, INITIAL_STATE.usersEnrolled, 'usersEnrolled')
})

// dummy data
