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

import FocusManager from '../focusManager'

interface FocusableNode {
  focus: () => void
  name?: string
}

describe('FocusManager', () => {
  test('allocateNext() returns the appropriate next index', () => {
    const manager = new FocusManager()
    expect(manager.allocateNext().index).toBe(0)
    expect(manager.allocateNext().index).toBe(1)
  })

  test('allocateNext() adds on to items', () => {
    const manager = new FocusManager()
    expect(manager.items).toHaveLength(0)

    manager.allocateNext()
    manager.allocateNext()

    expect(manager.items).toHaveLength(2)
  })

  test('allocateNext() returns an appropriate register ref function', () => {
    const manager = new FocusManager()
    const nextNode = manager.allocateNext()
    nextNode.ref({name: 'foo'} as FocusableNode)
    expect(manager.items).toHaveLength(1)
    expect(manager.items[0]).toEqual({name: 'foo'})
  })

  test('reset() removes all items', () => {
    const manager = new FocusManager()
    manager.allocateNext()

    expect(manager.items).toHaveLength(1)
    manager.reset()
    expect(manager.items).toHaveLength(0)
  })

  test('registerItem() sets a node at an index', () => {
    const manager = new FocusManager()
    manager.registerItem({name: 'foo'} as FocusableNode, 0)

    expect(manager.items).toHaveLength(1)
    expect(manager.items[0]).toEqual({name: 'foo'})
  })

  test('registerItemRef() returns a ref function that registers item at index', () => {
    const manager = new FocusManager()
    const ref = manager.registerItemRef(0)
    ref({name: 'foo'} as FocusableNode)

    expect(manager.items).toHaveLength(1)
    expect(manager.items[0]).toEqual({name: 'foo'})
  })

  test('registerBeforeRef() registers the before ref', () => {
    const manager = new FocusManager()
    manager.registerBeforeRef({name: 'foo'} as FocusableNode)
    expect(manager.before).toEqual({name: 'foo'})
  })

  test('registerAfterRef() registers the after ref', () => {
    const manager = new FocusManager()
    manager.registerAfterRef({name: 'foo'} as FocusableNode)
    expect(manager.after).toEqual({name: 'foo'})
  })

  test('movePrev() moves focus to item before index', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.registerItem({focus: spy}, 0)
    manager.registerItem({focus: () => {}}, 1)

    manager.movePrev(1)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('movePrev() moves focus to before if on first index', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.before = {focus: spy}
    manager.registerItem({focus: () => {}}, 0)

    manager.movePrev(0)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('moveNext() moves focus to item after index', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.registerItem({focus: () => {}}, 0)
    manager.registerItem({focus: spy}, 1)

    manager.moveNext(0)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('moveNext() moves focus to after if on last index', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.after = {focus: spy}
    manager.registerItem({focus: () => {}}, 0)

    manager.moveNext(0)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('moveBefore() moves focus to before', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.before = {focus: spy}

    manager.moveBefore()
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('moveAfter() moves focus to after', () => {
    const manager = new FocusManager()
    const spy = jest.fn()
    manager.after = {focus: spy}

    manager.moveAfter()
    expect(spy).toHaveBeenCalledTimes(1)
  })

  test('focus() calls focus on thing', () => {
    const manager = new FocusManager()
    const spy = jest.fn()

    manager.focus({focus: spy})
    expect(spy).toHaveBeenCalledTimes(1)
  })
})
