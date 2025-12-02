/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import CardActions from '../differentiatedModulesCardActions'

describe('differentiatedModulesCardActions', () => {
  beforeEach(() => {
    CardActions.setOverrideInitializer('rowKey1', {
      due_at: new Date(2024, 0, 15),
      lock_at: new Date(2024, 0, 20),
      unlock_at: new Date(2024, 0, 10),
    })
  })

  describe('addStudentToExistingAdhocOverride', () => {
    it('adds a student to an existing adhoc override', () => {
      const existingOverride = {
        student_ids: [1, 2],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
        ],
        due_at: new Date(2024, 0, 15),
      }
      const overridesFromRow = [existingOverride]
      const newAssignee = {id: 3, name: 'Student 3'}

      const result = CardActions.addStudentToExistingAdhocOverride(
        newAssignee,
        existingOverride,
        overridesFromRow,
      )

      expect(result).toHaveLength(1)
      expect(result[0].student_ids).toEqual([1, 2, 3])
      expect(result[0].students).toHaveLength(3)
      expect(result[0].students[2]).toEqual(newAssignee)
    })

    it('removes the title from the resulting override', () => {
      const existingOverride = {
        student_ids: [1],
        students: [{id: 1, name: 'Student 1'}],
        title: 'Some Title',
      }
      const newAssignee = {id: 2, name: 'Student 2'}

      const result = CardActions.addStudentToExistingAdhocOverride(newAssignee, existingOverride, [
        existingOverride,
      ])

      expect(result[0].title).toBeUndefined()
    })

    it('replaces the existing override with the updated one using union and difference', () => {
      const existingOverride = {
        student_ids: [1],
        students: [{id: 1, name: 'Student 1'}],
      }
      const otherOverride = {
        course_section_id: 5,
        title: 'Section Override',
      }
      const overridesFromRow = [otherOverride, existingOverride]
      const newAssignee = {id: 2, name: 'Student 2'}

      const result = CardActions.addStudentToExistingAdhocOverride(
        newAssignee,
        existingOverride,
        overridesFromRow,
      )

      expect(result).toHaveLength(2)
      expect(result.some(o => o.course_section_id === 5)).toBe(true)
      expect(result.some(o => o.student_ids && o.student_ids.includes(2))).toBe(true)
    })

    it('preserves existing override properties', () => {
      const existingOverride = {
        student_ids: [1],
        students: [{id: 1, name: 'Student 1'}],
        due_at: new Date(2024, 0, 15),
        lock_at: new Date(2024, 0, 20),
        customProperty: 'value',
      }
      const newAssignee = {id: 2, name: 'Student 2'}

      const result = CardActions.addStudentToExistingAdhocOverride(newAssignee, existingOverride, [
        existingOverride,
      ])

      expect(result[0].due_at).toEqual(existingOverride.due_at)
      expect(result[0].lock_at).toEqual(existingOverride.lock_at)
      expect(result[0].customProperty).toEqual('value')
    })
  })

  describe('handleStudentRemove', () => {
    it('removes a student from adhoc override when multiple students remain', () => {
      const adhocOverride = {
        student_ids: [1, 2, 3],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
          {id: 3, name: 'Student 3'},
        ],
        due_at: new Date(2024, 0, 15),
      }
      const assigneeToRemove = {student_id: 2}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [adhocOverride])

      expect(result).toHaveLength(1)
      expect(result[0].student_ids).toEqual([1, 3])
      expect(result[0].students).toHaveLength(2)
      expect(result[0].students.map(s => s.id)).toEqual([1, 3])
    })

    it('removes the entire adhoc override when the last student is removed', () => {
      const adhocOverride = {
        student_ids: [1],
        students: [{id: 1, name: 'Student 1'}],
      }
      const assigneeToRemove = {student_id: 1}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [adhocOverride])

      expect(result).toEqual([])
    })

    it('removes the title from the resulting override', () => {
      const adhocOverride = {
        student_ids: [1, 2],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
        ],
        title: 'Some Title',
      }
      const assigneeToRemove = {student_id: 1}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [adhocOverride])

      expect(result[0].title).toBeUndefined()
    })

    it('preserves other overrides in the row', () => {
      const adhocOverride = {
        student_ids: [1, 2],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
        ],
      }
      const sectionOverride = {
        course_section_id: 5,
        title: 'Section Override',
      }
      const assigneeToRemove = {student_id: 1}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [
        sectionOverride,
        adhocOverride,
      ])

      expect(result).toHaveLength(2)
      expect(result.some(o => o.course_section_id === 5)).toBe(true)
    })

    it('finds the correct adhoc override when multiple overrides exist', () => {
      const adhocOverride1 = {
        student_ids: [1, 2],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
        ],
      }
      const adhocOverride2 = {
        student_ids: [3, 4],
        students: [
          {id: 3, name: 'Student 3'},
          {id: 4, name: 'Student 4'},
        ],
      }
      const assigneeToRemove = {student_id: 3}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [
        adhocOverride1,
        adhocOverride2,
      ])

      expect(result.find(o => o.student_ids && o.student_ids.includes(1))).toBeDefined()
      expect(result.find(o => o.student_ids && o.student_ids.includes(4))).toBeDefined()
      expect(result.find(o => o.student_ids && o.student_ids.includes(3))).toBeUndefined()
    })

    it('uses union and difference to properly update the overrides array', () => {
      const adhocOverride = {
        student_ids: [1, 2],
        students: [
          {id: 1, name: 'Student 1'},
          {id: 2, name: 'Student 2'},
        ],
        due_at: new Date(2024, 0, 15),
      }
      const assigneeToRemove = {student_id: 1}

      const result = CardActions.handleStudentRemove(assigneeToRemove, [adhocOverride])

      expect(result[0].student_ids).toEqual([2])
      expect(result[0].due_at).toEqual(adhocOverride.due_at)
    })
  })

  describe('handleStudentAdd', () => {
    it('creates new adhoc override when none exists', () => {
      const newAssignee = {id: 1, name: 'Student 1'}
      const overridesFromRow = []

      const result = CardActions.handleStudentAdd(newAssignee, overridesFromRow)

      expect(result).toHaveLength(1)
      expect(result[0].student_ids).toEqual([1])
      expect(result[0].students).toEqual([newAssignee])
    })

    it('adds to existing adhoc override when one exists', () => {
      const existingOverride = {
        student_ids: [1],
        students: [{id: 1, name: 'Student 1'}],
      }
      const newAssignee = {id: 2, name: 'Student 2'}

      const result = CardActions.handleStudentAdd(newAssignee, [existingOverride])

      expect(result).toHaveLength(1)
      expect(result[0].student_ids).toEqual([1, 2])
    })
  })
})
