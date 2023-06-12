/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import mixin from '@canvas/backbone/mixin'

QUnit.module('mixin')

test('merges objects without blowing away events or defaults', 4, () => {
  const mixin1 = {
    events: {'click .foo': 'foo'},
    defaults: {foo: 'bar'},
    foo: sinon.spy(),
  }
  const mixin2 = {
    events: {'click .bar': 'bar'},
    defaults: {baz: 'qux'},
    bar: sinon.spy(),
  }
  const obj = mixin({}, mixin1, mixin2)
  // events are expected to all be merged together
  // rather than getting blown away by the last mixin
  const expectedEvents = {
    'click .foo': 'foo',
    'click .bar': 'bar',
  }
  const expectedDefaults = {
    foo: 'bar',
    baz: 'qux',
  }
  deepEqual(obj.events, expectedEvents, 'events merged properly')
  deepEqual(obj.defaults, expectedDefaults, 'defaults merged properly')
  obj.foo()
  ok(obj.foo.calledOnce)
  obj.bar()
  ok(obj.bar.calledOnce)
})
