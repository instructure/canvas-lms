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

// because our version of jsdom doesn't support elt.closest('a') yet. Should soon.
export function closest(el, selector) {
  while (el && !el.matches(selector)) {
    el = el.parentElement
  }
  return el
}

export function mockCourse(overrides) {
  return {
    lid: 'course-lid',
    ...overrides
  }
}

export function mockAssignment(overrides) {
  return {
    name: 'assignment name',
    description: 'assignment description',
    lid: 'assignment-lid',
    dueAt: 'due-at',
    pointsPossible: 5,
    state: 'published',
    course: mockCourse(),
    ...overrides
  }
}
