/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

/**
 * @jest-environment node
 */

import deprecated from '../deprecated'

describe('deprecated', () => {

  let originalFn
  beforeEach(() => {
    originalFn = jest.fn()
    jest.spyOn(global.console, 'warn').mockImplementation()
  })
  afterEach(() => {
    global.console.warn.mockRestore()
  })

  it('only logs deprecation message once', () => {
    const foo = deprecated("some message", originalFn)

    foo()
    expect(console.warn).toHaveBeenCalledTimes(1)
    expect(originalFn).toHaveBeenCalledTimes(1)

    foo(); foo("some arg"); foo()
    expect(console.warn).toHaveBeenCalledTimes(1)
    expect(originalFn).toHaveBeenCalledTimes(4)
  })

  it('passes on args', () => {
    const hostObj = {}
    deprecated("some message", hostObj, 'deprecatedMethod', originalFn)

    hostObj.deprecatedMethod("some arg")
    expect(console.warn).toHaveBeenCalledTimes(1)
    expect(originalFn).toHaveBeenLastCalledWith("some arg")

    hostObj.deprecatedMethod(hostObj)
    expect(console.warn).toHaveBeenCalledTimes(1)
    expect(originalFn).toHaveBeenLastCalledWith(hostObj)
  })

  it('works the same with other signature', () => {
    const hostObj = {deprecatedMethod: originalFn}
    deprecated("some message", hostObj, 'deprecatedMethod')

    hostObj.deprecatedMethod("some arg")
    expect(console.warn).toHaveBeenCalledTimes(1)
    expect(originalFn).toHaveBeenLastCalledWith("some arg")
  })
})
