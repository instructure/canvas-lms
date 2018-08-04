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

// The idea behind this is to make redux-thunk actions identifiable in tests.
//
// Normally in tests, you can check that an action was dispatched by comparing
// the action object:
//
// mockDispatch = jest.fn() mockDispatch(someAction(42))
// expect(mockDispatch).toHaveBeenCalledWith({type: 'SOME_ACTION', payload: 42})
//
// This utility lets you assert that the action's thunk was passed to a mock
// dispatch function without having to invoke the thunk and check for side
// effects. For example:
//
// mockDispatch = jest.fn()
// const someComplexAction =
//   identifiableThunk((num) => (dispatch, getState) => { dispatch(someAction(num)) })
// mockDispatch(someComplexAction(42));
// expect(mockDispatch).toHaveBeenCalledWith(someComplexAction)
// expect(someComplexAction.args()).toEqual([42])
// expect(mockDispatch).not.toHaveBeenCalledWith(someOtherComplexAction)
//
// Note that it's important to call the reset method on the action to make
// sure the tests don't interfere with each other:
//
// afterEach(() => someComplexAction.resetArgs())
//
export function identifiableThunk(fn) {
  let thunk = undefined // remember the return value of fn, which should be a thunk
  let fnArgs = undefined // only need to remember this for tests to check
  const identifiableFn = (...args) => {
    if (typeof args[0] === 'function') { // called as a thunk
      if (thunk === undefined) throw new Error('identifiableThunk was called as a thunk before it was called as a normal function. The action\'s first parameter must not be a function.');
      // reset first so the thunk can dispatch the action recursively
      const rememberThunk = thunk
      identifiableFn.reset()
      return rememberThunk(...args) // forward the thunk's return value
    } else { // called as a normal function
      if (thunk !== undefined) throw new Error('identifiableThunk was called as a normal function twice in a row. If testing, You may need to add `action.resetArgs()` to your beforeEach or afterEach.');
      thunk = fn(...args) // remember the thunk for the next call
      fnArgs = args // remember args for checking in tests
      return identifiableFn // so it can be called again as a thunk
    }
  }

  // useful methods for testing
  identifiableFn.reset = () => { thunk = undefined; fnArgs = undefined }
  identifiableFn.args = () => fnArgs
  identifiableFn.fn = () => fn
  return identifiableFn;
}
