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

import awaitElement from '../index'

describe('awaitElement', () => {
  beforeAll(() => {
    vi.useFakeTimers()
  })

  afterAll(() => {
    vi.runAllTimers()
    vi.useRealTimers()
  })

  beforeEach(() => {
    vi.spyOn(window, 'requestAnimationFrame').mockImplementation(function (
      cb: (number: number) => void,
    ): number {
      return window.setTimeout(function () {
        cb(0)
      }, 50)
    })
    vi.spyOn(window, 'cancelAnimationFrame').mockImplementation(function (timer: number): void {
      window.clearTimeout(timer)
    })
  })

  afterEach(() => {
    ;(window.requestAnimationFrame as any).mockRestore()
    ;(window.cancelAnimationFrame as any).mockRestore()
  })

  it('detects a new DOM element when it’s added', async () => {
    const elt = document.createElement('div')
    elt.id = 'lolly'

    const promise = awaitElement('lolly', 1000)
    document.body.append(elt)
    vi.runAllTimers()
    const result = await promise
    expect(result.id).toBe('lolly')
  })

  it('detects a DOM element that’s already there', async () => {
    const elt = document.createElement('div')
    elt.id = 'popsicle'
    document.body.append(elt)

    const promise = awaitElement('popsicle', 1000)
    vi.runAllTimers()
    const result = await promise
    expect(result.id).toBe('popsicle')
  })

  it('rejects the Promise if the element never gets added', async () => {
    const promise = awaitElement('lost-to-eternity', 1000)
    try {
      vi.advanceTimersByTime(1050) // oops we waited just a little too long
      await promise
      throw new Error('fails')
    } catch (e) {
      expect(e).toEqual(new Error('Timeout waiting for element to appear'))
    }
  })

  it('waits the requested amount of time before rejecting', async () => {
    const elt = document.createElement('div')
    elt.id = 'just-in-time'

    const promise = awaitElement('just-in-time', 3000)

    vi.advanceTimersByTime(2949) // wait until it's almost too late
    document.body.append(elt) // ...then add the element in the nick of time
    vi.runAllTimers()

    const result = await promise
    expect(result.id).toBe('just-in-time')
  })
})
