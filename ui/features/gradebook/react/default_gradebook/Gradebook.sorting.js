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

import natcompare from '@canvas/util/natcompare'

export function isDefaultSortOrder(sortOrder) {
  return !['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder)
}

export function localeSort(a, b, {asc = true, nullsLast = false} = {}) {
  if (nullsLast) {
    if (a != null && b == null) {
      return -1
    }
    if (a == null && b != null) {
      return 1
    }
  }
  if (!asc) {
    ;[b, a] = [a, b]
  }
  return natcompare.strings(a || '', b || '')
}

export function wrapColumnSortFn(wrappedFn, direction = 'ascending') {
  return function (a, b) {
    if (b.type === 'total_grade_override') {
      return -1
    }
    if (a.type === 'total_grade_override') {
      return 1
    }
    if (b.type === 'total_grade') {
      return -1
    }
    if (a.type === 'total_grade') {
      return 1
    }
    if (b.type === 'assignment_group' && a.type !== 'assignment_group') {
      return -1
    }
    if (a.type === 'assignment_group' && b.type !== 'assignment_group') {
      return 1
    }
    if (a.type === 'assignment_group' && b.type === 'assignment_group') {
      return a.object.position - b.object.position
    }
    if (direction === 'descending') {
      ;[a, b] = [b, a]
    }
    return wrappedFn(a, b)
  }
}

export function compareAssignmentPointsPossible(a, b) {
  return a.object.points_possible - b.object.points_possible
}

export function compareAssignmentPositions(a, b) {
  const diffOfAssignmentGroupPosition =
    a.object.assignment_group.position - b.object.assignment_group.position
  const diffOfAssignmentPosition = a.object.position - b.object.position
  // order first by assignment_group position and then by assignment position
  // will work when there are less than 1000000 assignments in an assignment_group
  return diffOfAssignmentGroupPosition * 1000000 + diffOfAssignmentPosition
}
