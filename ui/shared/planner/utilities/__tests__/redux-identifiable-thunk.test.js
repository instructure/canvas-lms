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

import {identifiableThunk} from '../redux-identifiable-thunk'

it('returns a thunk that is identical to itself ', () => {
  let called = false
  const doSomething = identifiableThunk(() => (_dispatch, _getState) => {
    called = true
  })
  expect(called).toBe(false)
  const doSomethingThunk = doSomething()
  expect(doSomethingThunk).toBe(doSomething)
  doSomethingThunk(
    () => {},
    () => {}
  )
  expect(called).toBe(true)
})

it('passes arguments to the fn', () => {
  expect.hasAssertions()
  const doSomething = identifiableThunk((first, second) => (_dispatch, _getState) => {
    expect(first).toBe('first')
    expect(second).toBe('second')
  })
  doSomething('first', 'second')(
    () => {},
    () => {}
  )
})

it('passes only the specified args to the function', () => {
  let passedArgs
  const doSomething = identifiableThunk(
    (...args) =>
      (_dispatch, _getState) =>
        (passedArgs = args)
  )
  const thunk = doSomething()
  expect(doSomething.args()).toEqual([])
  thunk(
    () => {},
    () => {}
  )
  expect(passedArgs).toEqual([])
})

it('forwards the return value of the thunked function', () => {
  const doSomething = identifiableThunk(() => (_dispatch, _getState) => {
    return 42
  })
  expect(
    doSomething()(
      () => {},
      () => {}
    )
  ).toBe(42)
})

it('lets us alternate between calling it with args and calling it as a thunk', () => {
  let sum = 0
  const doSomething = identifiableThunk(increment => (_dispatch, _getState) => {
    sum += increment
  })
  doSomething(1)(
    () => {},
    () => {}
  )
  doSomething(2)(
    () => {},
    () => {}
  )
  expect(sum).toBe(3)
})

it('throws if the thunk is not invoked before we call it with normal args again', () => {
  const doSomething = identifiableThunk(() => (_dispatch, _getState) => {})
  expect(() => {
    doSomething()
    doSomething()
  }).toThrow()
})

it('throws if the action is invoked as a thunk before it is called with normal args', () => {
  const doSomething = identifiableThunk(() => () => {})
  expect(() =>
    doSomething(
      () => {},
      () => {}
    )
  ).toThrow()
})

it('can invoke itself recursively', () => {
  const doSomething = identifiableThunk(recur => (_dispatch, _getState) => {
    if (recur)
      return doSomething(false)(
        () => {},
        () => {}
      )
    else return 'recurred'
  })
  expect(
    doSomething(true)(
      () => {},
      () => {}
    )
  ).toBe('recurred')
})

it('can reset args and be called as a normal function twice in a row', () => {
  const doSomething = identifiableThunk(() => () => {})
  doSomething()
  doSomething.reset()
  doSomething()
})

it('can return the original function', () => {
  const fn = () => () => {}
  const doSomething = identifiableThunk(fn)
  expect(doSomething.fn()).toBe(fn)
})

it('can access the current args', () => {
  const doSomething = identifiableThunk(() => () => {})
  expect(doSomething.args()).not.toBeDefined()
  const thunk = doSomething(1, 2, 3)
  expect(doSomething.args()).toEqual([1, 2, 3])
  thunk(
    () => {},
    () => {}
  )
  expect(doSomething.args()).not.toBeDefined()
})

it('can be invoked with more than 3 args', () => {
  const doSomething = identifiableThunk((a, b, c, d) => (_dispatch, _getState) => a + b + c + d)
  expect(
    doSomething(
      1,
      2,
      3,
      4
    )(
      () => {},
      () => {}
    )
  ).toBe(10)
})
