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

import { jest } from '@jest/globals'
import createPersistentArray from '../index'

const key = 'PersistentArrayTest'
const throttle = 1
const debounceWindow = throttle + 2

afterEach(async () => {
  localStorage.removeItem(key)
})

describe('PersistentArray', () => {
  it('initializes to an empty set', () => {
    expect(createPersistentArray({ key })).toEqual([])
  })

  it('deserializes initial value from localStorage', () => {
    localStorage.setItem(key, '[1]')
    expect(createPersistentArray({ key })).toEqual([1])
  })
})

describe('PersistentArray#push', () => {
  let subject

  beforeEach(() => {
    subject = createPersistentArray({ key, throttle, size: 3 })
  })

  afterEach(() => {
    subject.cancel()
  })

  it('works normally', () => {
    subject.push(1)
    expect(subject[0]).toEqual(1)
  })

  it('writes to localStorage on push sometime later', async () => {
    subject.push('a')

    expect(localStorage.getItem(key)).toEqual(null)

    await new Promise(resolve => setTimeout(resolve, debounceWindow))

    expect(JSON.parse(localStorage.getItem(key))).toEqual(['a'])
  })

  it('batches multiple pushes into a single write to localStorage', async () => {
    const setItem = jest.spyOn(localStorage, 'setItem')

    subject.push('a')
    subject.push('b')
    subject.push('c')

    await new Promise(resolve => setTimeout(resolve, debounceWindow))

    expect(setItem.mock.calls.length).toEqual(1)
    expect(JSON.parse(localStorage.getItem(key))).toEqual(['a','b','c'])
  })

  it('discards older entries if array size exceeds requested size', () => {
    subject.push('a')
    subject.push('b')
    subject.push('c')
    subject.push('d')

    expect(subject.length).toEqual(3)
    expect(subject).toEqual(['b','c','d'])
  })
})

describe('PersistentArray#splice', () => {
  let subject

  beforeEach(() => {
    localStorage.setItem(key, '[1]')
    subject = createPersistentArray({ key, throttle })
  })

  afterEach(() => {
    subject.cancel()
  })

  it('works normally', () => {
    expect(subject.length).toEqual(1)
    subject.splice(0)
    expect(subject.length).toEqual(0)
  })

  it('writes to localStorage on the next frame', async () => {
    expect(subject.length).toEqual(1)
    subject.splice(0)
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(localStorage.getItem(key)).toEqual('[]')
  })
})

describe('PersistentArray#save', () => {
  let subject

  afterEach(() => {
    if (subject) {
      subject.cancel()
    }
  })

  it('transforms the value for saving', async () => {
    subject = createPersistentArray({
      key,
      throttle,
      transform: x => [].concat(x).sort()
    })

    subject.push(3)
    subject.push(1)

    await new Promise(resolve => setTimeout(resolve, debounceWindow))

    expect(subject).toEqual([3,1])
    expect(JSON.parse(localStorage.getItem(key))).toEqual([1,3])
  })
})
