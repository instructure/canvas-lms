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

import {stubbable, waitForNextExample} from './shared'

QUnit.module('Legacy Module', {
  setup() {
    sandbox.stub(stubbable, 'getValue').returns('fake')
    // setting up legacy module
  },
  teardown() {
    // tearing down legacy module
  },
})

test('accepts examples only after calls to `QUnit.module`', () => {
  ok(true)
})

test('uses "sandbox.stub()" within `setup` to stub methods', () => {
  strictEqual(stubbable.getValue(), 'fake')
})

test('uses "sandbox.stub()" within tests to stub methods', () => {
  sandbox.stub(stubbable, 'getOtherValue').returns('really fake')
  strictEqual(stubbable.getOtherValue(), 'really fake')
})

test('restores sandbox stubs between tests', () => {
  sandbox.stub(stubbable, 'getOtherValue').returns('super fake')
  strictEqual(stubbable.getOtherValue(), 'super fake')
})

test('auto-verifies mock expectations', () => {
  sandbox.mock(stubbable).expects('getOtherValue').once()
  // When the method call below is removed, this and only this spec will fail.
  stubbable.getOtherValue()
})

QUnit.skip('allows skipping examples', () => {
  // pending
})

QUnit.module('Legacy Module > when unmanaged async behavior begins in the "setup" callback', {
  setup() {
    waitForNextExample(() => {
      /*
       * When AsyncTracker unmanagedBehaviorStrategy is 'fail', this will cause a
       * test failure.
       * When otherwise unchecked, this will cause a build failure.
       */
      // throw new Error('Build failure "Script error."')
    })
  },
})

test('otherwise passing example 1', () => {
  ok(true)
})

QUnit.module('Legacy Module > when unmanaged async behavior begins in the "teardown" callback', {
  teardown() {
    waitForNextExample(() => {
      /*
       * When AsyncTracker unmanagedBehaviorStrategy is 'fail', this will cause a
       * test failure.
       * When otherwise unchecked, this will cause a build failure.
       */
      // throw new Error('Build failure "Script error."')
    })
  },
})

test('otherwise passing example 2', () => {
  ok(true)
})

QUnit.module('Legacy Module > when unmanaged async behavior begins in the example callback')

test('otherwise passing example 3', () => {
  ok(true)
  waitForNextExample(() => {
    /*
     * When AsyncTracker unmanagedBehaviorStrategy is 'fail', this will cause a test
     * failure.
     * When otherwise unchecked, this will cause a build failure.
     */
    // throw new Error('Build failure "Script error."')
  })
})
