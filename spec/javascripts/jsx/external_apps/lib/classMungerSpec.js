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

import classMunger from 'ui/features/external_apps/react/lib/classMunger'

QUnit.module('ExternalApps.classMunger')

test('conditionally joins classes', () => {
  let cls = classMunger('foo', {
    bar: true,
    baz: false,
  })
  equal(cls, 'foo bar')
  cls = classMunger('foo', {
    bar: true,
    baz: true,
  })
  equal(cls, 'foo bar baz')
  cls = classMunger('foo fum', {
    bar: true,
    baz: false,
    bop: true,
  })
  equal(cls, 'foo fum bar bop')
})
