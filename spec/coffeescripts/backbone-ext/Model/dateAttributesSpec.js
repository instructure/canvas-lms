/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import {Model} from '@canvas/backbone'

QUnit.module('dateAttributes')

test('converts date strings to date objects', function () {
  class TestModel extends Model {
    static initClass() {
      this.prototype.dateAttributes = ['foo', 'bar']
    }
  }
  TestModel.initClass()
  const stringDate = '2012-04-10T17:21:09-06:00'
  const parsedDate = Date.parse(stringDate)
  const res = TestModel.prototype.parse({
    foo: stringDate,
    bar: null,
    baz: stringDate,
  })
  const expected = {
    foo: parsedDate,
    bar: null,
    baz: stringDate,
  }
  deepEqual(res, expected)
})
