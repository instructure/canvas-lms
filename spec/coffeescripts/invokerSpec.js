/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import invoker from 'compiled/util/invoker'

const obj = invoker({
  one() {
    return 1
  },
  noMethod() {
    return 'noMethod'
  }
})

QUnit.module('Invoker')

test('should call a method with invoke', () => {
  const result = obj.invoke('one')
  equal(result, 1)
})

test("should call noMethod when invoked method doesn't exist", () => {
  const result = obj.invoke('non-existent')
  equal(result, 'noMethod')
})
