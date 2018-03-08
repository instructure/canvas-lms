/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import LockManager from 'jsx/blueprint_courses/apps/LockManager'

QUnit.module('LockManager class')

test('shouldInit returns false if master courses env is not setup', () => {
  ENV.MASTER_COURSE_DATA = null
  const manager = new LockManager()
  notOk(manager.shouldInit())
})

test('shouldInit returns true if is_master_course_master_content is true', () => {
  ENV.MASTER_COURSE_DATA = {is_master_course_master_content: true}
  const manager = new LockManager()
  ok(manager.shouldInit())
})

test('shouldInit returns true if is_master_course_child_content is true', () => {
  ENV.MASTER_COURSE_DATA = {is_master_course_child_content: true}
  const manager = new LockManager()
  ok(manager.shouldInit())
})
