/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import tz from '../'
import { equal, moonwalk, setup } from './helpers'

setup(this)

test('shift() should adjust the date as appropriate', () =>
  equal(+tz.shift(moonwalk, '-1 day'), moonwalk - 86400000))

test('shift() should apply multiple directives', () =>
  equal(+tz.shift(moonwalk, '-1 day', '-1 hour'), moonwalk - 86400000 - 3600000))

test('shift() should parse the value if necessary', () =>
  equal(+tz.shift('1969-07-21 02:56', '-1 day'), moonwalk - 86400000))

test('shift() should return null if the parse fails', () =>
  equal(tz.shift('bogus', '-1 day'), null))

test('shift() should return null if the directives includes a format string', () =>
  equal(tz.shift('bogus', '-1 day', '%F %T%:z'), null))
