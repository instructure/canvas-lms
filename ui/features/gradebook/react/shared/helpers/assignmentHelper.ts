// @ts-nocheck
/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import type {GridColumnObject} from '../../default_gradebook/grid.d'

const assignmentHelper = {
  compareByDueDate(a: GridColumnObject, b: GridColumnObject) {
    let aDate: number | Date | null = a.due_at == null ? null : new Date(a.due_at)
    let bDate: number | Date | null = b.due_at == null ? null : new Date(b.due_at)
    const aDateIsNull = aDate === null
    const bDateIsNull = bDate === null
    if (aDateIsNull && !bDateIsNull) {
      return 1
    }
    if (!aDateIsNull && bDateIsNull) {
      return -1
    }
    aDate = +aDate
    bDate = +bDate
    if (aDate === bDate) {
      const aName = a.name.toLowerCase() || ''
      const bName = b.name.toLowerCase() || ''
      if (aName === bName) {
        return 0
      }
      return aName > bName ? 1 : -1
    }
    return aDate - bDate
  },

  getComparator(arrangeBy) {
    if (arrangeBy === 'due_date') {
      return this.compareByDueDate.bind(this)
    }
    if (arrangeBy === 'assignment_group') {
      return this.compareByAssignmentGroup.bind(this)
    }
  },

  compareByAssignmentGroup(a, b) {
    const diffOfAssignmentGroupPosition = a.assignment_group_position - b.assignment_group_position
    if (diffOfAssignmentGroupPosition === 0) {
      const diffOfAssignmentPosition = a.position - b.position
      if (diffOfAssignmentPosition === 0) {
        return 0
      }
      return diffOfAssignmentPosition
    }
    return diffOfAssignmentGroupPosition
  },

  gradeByGroup(assignment) {
    return !!assignment.group_category_id && !assignment.grade_group_students_individually
  },
}

export default assignmentHelper
