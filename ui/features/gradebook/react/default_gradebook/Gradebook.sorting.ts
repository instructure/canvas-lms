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
import NumberCompare from '../../util/NumberCompare'
import type {GridColumn} from './grid.d'
import type {Student} from '../../../../api.d'

export function isDefaultSortOrder(sortOrder: string) {
  return !['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder)
}

export function localeSort(
  a: null | string,
  b: null | string,
  {asc = true, nullsLast = false} = {}
): number {
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

export function wrapColumnSortFn(
  wrappedFn: (a: GridColumn, b: GridColumn) => number,
  direction = 'ascending'
) {
  return function (a: GridColumn, b: GridColumn): number {
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
      return (a.object?.position || 0) - (b.object?.position || 0)
    }
    if (direction === 'descending') {
      ;[a, b] = [b, a]
    }
    return wrappedFn(a, b)
  }
}

export function compareAssignmentPointsPossible(
  a: Pick<GridColumn, 'object'>,
  b: Pick<GridColumn, 'object'>
): number {
  return (a.object?.points_possible || 0) - (b.object?.points_possible || 0)
}

export function compareAssignmentPositions(
  a: Pick<GridColumn, 'object'>,
  b: Pick<GridColumn, 'object'>
): number {
  const diffOfAssignmentGroupPosition =
    (a.object?.assignment_group?.position || 0) - (b.object?.assignment_group?.position || 0)
  const diffOfAssignmentPosition = (a.object?.position || 0) - (b.object?.position || 0)
  // order first by assignment_group position and then by assignment position
  // will work when there are less than 1000000 assignments in an assignment_group
  return diffOfAssignmentGroupPosition * 1000000 + diffOfAssignmentPosition
}

export function idSort(a: {id: string}, b: {id: string}, ascending = true): number {
  return NumberCompare(Number(a.id), Number(b.id), {
    descending: !ascending,
  })
}

export function secondaryAndTertiarySort(
  a: Pick<Student, 'id' | 'sortable_name'>,
  b: Pick<Student, 'id' | 'sortable_name'>,
  {asc = true}
) {
  let result
  result = localeSort(a.sortable_name || '', b.sortable_name || '', {asc})
  if (result === 0) {
    result = idSort(a, b, asc)
  }
  return result
}

export function compareAssignmentNames(a: GridColumn, b: GridColumn): number {
  return localeSort(a.object?.name || '', b.object?.name || '')
}

export function makeCompareAssignmentCustomOrderFn(sortOrder: {customOrder?: string[]}) {
  let assignmentId: string
  let indexCounter: number
  let len: number
  let j: number
  const sortMap: {
    [key: string]: number
  } = {}
  indexCounter = 0
  const ref1 = sortOrder.customOrder || []
  for (j = 0, len = ref1.length; j < len; j++) {
    assignmentId = ref1[j]
    sortMap[String(assignmentId)] = indexCounter
    indexCounter += 1
  }
  return (a: GridColumn, b: GridColumn): number => {
    let aIndex, bIndex
    // The second lookup for each index is to maintain backwards
    // compatibility with old gradebook sorting on load which only
    // considered assignment ids.
    aIndex = sortMap[a.id || '']
    if (a.object != null) {
      if (aIndex == null) {
        aIndex = sortMap[String(a.object.id)]
      }
    }
    bIndex = sortMap[b.id || '']
    if (b.object != null) {
      if (bIndex == null) {
        bIndex = sortMap[String(b.object.id)]
      }
    }
    if (aIndex != null && bIndex != null) {
      return aIndex - bIndex
      // if there's a new assignment or assignment group and its
      // order has not been stored, it should come at the end
    } else if (aIndex != null && bIndex == null) {
      return -1
    } else if (bIndex != null) {
      return 1
    } else {
      const fn = wrapColumnSortFn(compareAssignmentPositions)
      return fn(a, b)
    }
  }
}
