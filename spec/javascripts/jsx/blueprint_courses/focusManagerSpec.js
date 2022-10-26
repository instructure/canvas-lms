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

import FocusManager from 'ui/features/blueprint_course_master/react/focusManager'

QUnit.module('FocusManager')

test('allocateNext() returns the appropriate next index', () => {
  const manager = new FocusManager()
  equal(manager.allocateNext().index, 0)
  equal(manager.allocateNext().index, 1)
})

test('allocateNext() adds on to items', () => {
  const manager = new FocusManager()
  equal(manager.items.length, 0)

  manager.allocateNext()
  manager.allocateNext()

  equal(manager.items.length, 2)
})

test('allocateNext() returns an appropriate register ref function', () => {
  const manager = new FocusManager()
  const nextNode = manager.allocateNext()
  nextNode.ref({name: 'foo'})
  equal(manager.items.length, 1)
  deepEqual(manager.items[0], {name: 'foo'})
})

test('reset() removes all items', () => {
  const manager = new FocusManager()
  manager.allocateNext()

  equal(manager.items.length, 1)
  manager.reset()
  equal(manager.items.length, 0)
})

test('registerItem() sets a node at an index', () => {
  const manager = new FocusManager()
  manager.registerItem({name: 'foo'}, 0)

  equal(manager.items.length, 1)
  deepEqual(manager.items[0], {name: 'foo'})
})

test('registerItemRef() returns a ref function that registers item at index', () => {
  const manager = new FocusManager()
  const ref = manager.registerItemRef(0)
  ref({name: 'foo'})

  equal(manager.items.length, 1)
  deepEqual(manager.items[0], {name: 'foo'})
})

test('registerBeforeRef() registers the before ref', () => {
  const manager = new FocusManager()
  manager.registerBeforeRef({name: 'foo'})
  deepEqual(manager.before, {name: 'foo'})
})

test('registerAfterRef() registers the after ref', () => {
  const manager = new FocusManager()
  manager.registerAfterRef({name: 'foo'})
  deepEqual(manager.after, {name: 'foo'})
})

test('movePrev() moves focus to item before index', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.registerItem({focus: spy}, 0)
  manager.registerItem({focus: () => {}}, 1)

  manager.movePrev(1)
  equal(spy.callCount, 1)
})

test('movePrev() moves focus to before if on first index', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.before = {focus: spy}
  manager.registerItem({focus: () => {}}, 0)

  manager.movePrev(0)
  equal(spy.callCount, 1)
})

test('moveNext() moves focus to item after index', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.registerItem({focus: () => {}}, 0)
  manager.registerItem({focus: spy}, 1)

  manager.moveNext(0)
  equal(spy.callCount, 1)
})

test('moveNext() moves focus to after if on last index', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.after = {focus: spy}
  manager.registerItem({focus: () => {}}, 0)

  manager.moveNext(0)
  equal(spy.callCount, 1)
})

test('moveBefore() moves focus to before ', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.before = {focus: spy}

  manager.moveBefore()
  equal(spy.callCount, 1)
})

test('moveAfter() moves focus to before ', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()
  manager.after = {focus: spy}

  manager.moveAfter()
  equal(spy.callCount, 1)
})

test('focus() calls focus on thing ', () => {
  const manager = new FocusManager()
  const spy = sinon.spy()

  manager.focus({focus: spy})
  equal(spy.callCount, 1)
})
