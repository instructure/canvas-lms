/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import classMunger from '../classMunger'

describe('ExternalApps.classMunger', () => {
  test('conditionally joins classes', () => {
    let cls = classMunger('foo', {
      bar: true,
      baz: false,
    })
    expect(cls).toBe('foo bar')
    cls = classMunger('foo', {
      bar: true,
      baz: true,
    })
    expect(cls).toBe('foo bar baz')
    cls = classMunger('foo fum', {
      bar: true,
      baz: false,
      bop: true,
    })
    expect(cls).toBe('foo fum bar bop')
  })
})
