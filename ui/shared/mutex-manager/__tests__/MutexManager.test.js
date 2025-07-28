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
import MutexManager from '../MutexManager'

describe('MutexManager', () => {
  const mutexName = 'testMutex'

  afterEach(() => {
    // Reset the mutexes after each test
    MutexManager.mutexes = {}
  })

  it('should create a mutex', () => {
    MutexManager.createMutex(mutexName)

    const mutex = MutexManager.mutexes[mutexName]
    expect(mutex.isLocked).toBe(true)
    expect(mutex.waiting).toEqual([])
  })

  it('should create a mutex with a callback', () => {
    const callback = jest.fn()
    MutexManager.createMutex(mutexName, callback)

    const mutex = MutexManager.mutexes[mutexName]
    expect(mutex.isLocked).toBe(true)
    expect(mutex.waiting).toEqual([callback])
  })

  it('should release a locked mutex', () => {
    MutexManager.createMutex(mutexName)

    MutexManager.releaseMutex(mutexName)

    const mutex = MutexManager.mutexes[mutexName]
    expect(mutex).toBeUndefined()
  })

  it('should await a locked mutex and execute all callbacks when released', () => {
    let callback1Executed = false
    MutexManager.createMutex(mutexName, () => {
      callback1Executed = true
    })
    let callback2Executed = false
    MutexManager.awaitMutex(mutexName, () => {
      callback2Executed = true
    })

    // The callbacks should not have executed yet
    expect(callback1Executed).toBe(false)
    expect(callback2Executed).toBe(false)

    // Release the mutex
    MutexManager.releaseMutex(mutexName)

    // The callbacks should have executed
    expect(callback1Executed).toBe(true)
    expect(callback2Executed).toBe(true)
  })

  it('should immediately execute the callback if the mutex is not registered', () => {
    let callbackExecuted = false
    MutexManager.awaitMutex(mutexName, () => {
      callbackExecuted = true
    })

    expect(callbackExecuted).toBe(true)
  })

  it('should immediately execute the callback if the mutex was previously released', () => {
    MutexManager.createMutex(mutexName)
    MutexManager.releaseMutex(mutexName)

    let callbackExecuted = false
    MutexManager.awaitMutex(mutexName, () => {
      callbackExecuted = true
    })

    expect(callbackExecuted).toBe(true)
  })

  it('should only execute callbacks for the released mutex', () => {
    MutexManager.createMutex('otherMutex')
    let callback1Executed = false
    MutexManager.createMutex(mutexName, () => {
      callback1Executed = true
    })
    let callback2Executed = false
    MutexManager.awaitMutex('otherMutex', () => {
      callback2Executed = true
    })

    // The callbacks should not have executed yet
    expect(callback1Executed).toBe(false)
    expect(callback2Executed).toBe(false)

    // Release the mutex
    MutexManager.releaseMutex(mutexName)

    // Only the callback for the released mutex should have executed
    expect(callback1Executed).toBe(true)
    expect(callback2Executed).toBe(false)
  })
})
