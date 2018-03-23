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

import { isPassedDelayedPostAt } from 'jsx/announcements/utils'

QUnit.module('Util helpers for announcements')

test('isPassedDelayedPostAt correctly identifies date that is before as false', () => {
  const currentDate = "2015-12-1"
  const delayedDate = "2015-12-14"
  const check = isPassedDelayedPostAt({ currentDate, delayedDate })
  notOk(check)
})

test('isPassedDelayedPostAt correctly identifies date that is after as true', () => {
  const currentDate = "2015-12-17"
  const delayedDate = "2015-12-14"
  const check = isPassedDelayedPostAt({ currentDate, delayedDate })
  ok(check)
})

test('isPassedDelayedPostAt correctly identifies date that is equal as not passed', () => {
  const currentDate = "2015-12-14"
  const delayedDate = "2015-12-14"
  const check = isPassedDelayedPostAt({ currentDate, delayedDate })
  notOk(check)
})
