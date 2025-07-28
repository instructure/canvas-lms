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

import mixin from '../mixin'

describe('mixin', () => {
  test('merges objects without blowing away events or defaults', () => {
    const mixin1 = {
      events: {'click .foo': 'foo'},
      defaults: {foo: 'bar'},
      foo: jest.fn(),
    }
    const mixin2 = {
      events: {'click .bar': 'bar'},
      defaults: {baz: 'qux'},
      bar: jest.fn(),
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
    expect(obj.events).toEqual(expectedEvents)
    expect(obj.defaults).toEqual(expectedDefaults)
    obj.foo()
    expect(obj.foo).toHaveBeenCalledTimes(1)
    obj.bar()
    expect(obj.bar).toHaveBeenCalledTimes(1)
  })
})
