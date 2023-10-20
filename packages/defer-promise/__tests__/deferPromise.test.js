/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import deferPromise from '../index'

describe('Shared > Async > .deferPromise()', () => {
  let deferred

  beforeEach(() => {
    deferred = deferPromise()
  })

  it('returns an object with a promise', () => {
    expect(deferred.promise).toBeInstanceOf(Promise)
  })

  it('includes a state of "pending"', () => {
    expect(deferred.state).toEqual('pending')
  })

  it('includes a `resolve` function', () => {
    expect(deferred.resolve).toBeInstanceOf(Function)
  })

  it('includes a `reject` function', () => {
    expect(deferred.reject).toBeInstanceOf(Function)
  })

  describe('when `resolve` is called', () => {
    it('resolves the promise on the deferred object', async () => {
      const resolved = deferred.promise.then(() => 'expected')
      deferred.resolve()
      expect(await resolved).toEqual('expected')
    })

    it('resolves the promise with the given value', async () => {
      const resolved = deferred.promise
      deferred.resolve('given value')
      expect(await resolved).toEqual('given value')
    })

    it('does not resolve when the promise has already resolved', async () => {
      const resolved = deferred.promise
      deferred.resolve('given value')
      deferred.resolve('again')
      expect(await resolved).toEqual('given value')
    })

    it('does not resolve when the promise has already rejected', async () => {
      const error = new Error('expected failure')
      const caught = deferred.promise.catch(e => e)
      deferred.reject(error)
      deferred.resolve('given value')
      expect(await caught).toEqual(error)
    })
  })

  describe('when `reject` is called', () => {
    it('rejects the promise on the deferred object', async () => {
      const caught = deferred.promise.catch(() => 'expected')
      deferred.reject()
      expect(await caught).toEqual('expected')
    })

    it('rejects the promise with the given error', async () => {
      const error = new Error('expected failure')
      const caught = deferred.promise.catch(e => e)
      deferred.reject(error)
      expect(await caught).toEqual(error)
    })

    it('does not reject when the promise has already resolved', async () => {
      const caught = deferred.promise.catch(e => e)
      deferred.resolve('given value')
      deferred.reject(new Error('failure'))
      expect(await caught).toEqual('given value')
    })

    it('does not reject when the promise has already rejected', async () => {
      const error = new Error('expected failure')
      const caught = deferred.promise.catch(e => e)
      deferred.reject(error)
      deferred.reject(new Error('different failure'))
      expect(await caught).toEqual(error)
    })
  })
})
