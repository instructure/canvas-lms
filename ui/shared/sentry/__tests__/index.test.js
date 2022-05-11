/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import { isolate } from '..'

describe('isolate', () => {
  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })

  it('isolates throws from function', async () => {
    await isolate(() => { throw new Error('nope') })()
    expect(console.error).toHaveBeenCalledWith(new Error('nope'))
  })

  it('isolates throws from async function', async () => {
    await isolate(async () => { throw new Error('nope') })()
    expect(console.error).toHaveBeenCalledWith(new Error('nope'))
  })

  it('isolates rejections returned by function', async () => {
    await isolate(() => Promise.reject(new Error('nope')))()
    expect(console.error).toHaveBeenCalledWith(new Error('nope'))
  })

  it('isolates rejections returned by async function', async () => {
    await isolate(async () => Promise.reject(new Error('nope')))()
    expect(console.error).toHaveBeenCalledWith(new Error('nope'))
  })

  it('isolates rejections awaited by async function', async () => {
    await isolate(async () => {
      await Promise.reject(new Error('nope'))
    })()
    expect(console.error).toHaveBeenCalledWith(new Error('nope'))
  })

  it('cannot isolate rejections that were not returned', async () => {
    await isolate(() => { Promise.reject(new Error('nope')) })()
    expect(console.error).not.toHaveBeenCalled()
  })
})
