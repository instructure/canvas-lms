// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {createDeepMockProxy} from './deepMockProxy'

describe('createDeepMockProxy', () => {
  it('should create a recursive proxy', () => {
    const thing = createDeepMockProxy<Thing>()

    thing.action()
    thing.child?.otherAction?.()

    thing.child?.child?.action()
    thing.child?.child?.action()

    expect(thing.action).toHaveBeenCalled()
    expect(thing.child?.otherAction).toHaveBeenCalled()
    expect(thing.child?.child?.action).toHaveBeenCalledTimes(2)

    expect(thing.child?.action).not.toHaveBeenCalled()
  })

  it('should support deep overrides', () => {
    const thing = createDeepMockProxy<Thing>({
      num: 10,
      child: {
        child: {
          num: 20,
        },
      },
    })

    thing.action()
    thing.child?.child?.action()

    expect(thing.action).toHaveBeenCalled()
    expect(thing.child?.child?.action).toHaveBeenCalledTimes(1)

    expect(thing.num).toEqual(10)
    expect(thing.child?.child?.num).toEqual(20)
  })

  it('should support shallow object overrides', () => {
    const child = {
      num: 15,
      child: null,
      action: () => null,
    }
    const thing = createDeepMockProxy<Thing>(
      {
        num: 10,
        child: {
          num: 2,
        },
      },
      {child}
    )

    thing.action()
    thing.child?.action()

    expect(thing.child).toBe(child)
    expect(thing.action).toHaveBeenCalled()
  })

  it('should handle null overrides', () => {
    const thing = createDeepMockProxy<Thing>({child: null})
    expect(thing.child).toBe(null)
  })

  it('should handle undefined overrides', () => {
    const thing = createDeepMockProxy<Thing>({child: undefined})
    expect(thing.child).toBe(undefined)
  })

  it('should handle function overrides', () => {
    const thing = createDeepMockProxy<Thing>({action: () => 10})
    expect(thing.action()).toBe(10)
  })
})

interface Thing {
  num: number

  action()
  otherAction?()

  child?: Thing | null
}
