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

import semanticDateRange from 'compiled/util/semanticDateRange'

QUnit.module('semanticDateRange')

test('different day', () => {
  const date1 = new Date(0)
  const date2 = new Date(+date1 + 86400000)
  equal(
    semanticDateRange(date1, date2),
    `\
<span class="date-range">
  <time datetime='1970-01-01T00:00:00.000Z'>
    Jan 1, 1970 at 12am
  </time> -
  <time datetime='1970-01-02T00:00:00.000Z'>
    Jan 2, 1970 at 12am
  </time>
</span>\
`
  )
})

test('same day, different time', () => {
  const date1 = new Date(0)
  const date2 = new Date(+date1 + 3600000)
  equal(
    semanticDateRange(date1, date2),
    `\
<span class="date-range">
  <time datetime='1970-01-01T00:00:00.000Z'>
    Jan 1, 1970, 12am
  </time> -
  <time datetime='1970-01-01T01:00:00.000Z'>
    1am
  </time>
</span>\
`
  )
})

test('same day, same time', () => {
  const date = new Date(0)
  equal(
    semanticDateRange(date, date),
    `\
<span class="date-range">
  <time datetime='1970-01-01T00:00:00.000Z'>
    Jan 1, 1970 at 12am
  </time>
</span>\
`
  )
})

test('no date', () =>
  equal(
    semanticDateRange(null, null),
    `\
<span class="date-range date-range-no-date">
  No Date
</span>\
`
  ))

test('can take ISO strings', () => {
  const date = new Date(0).toISOString()
  equal(
    semanticDateRange(date, date),
    `\
<span class="date-range">
  <time datetime='1970-01-01T00:00:00.000Z'>
    Jan 1, 1970 at 12am
  </time>
</span>\
`
  )
})
