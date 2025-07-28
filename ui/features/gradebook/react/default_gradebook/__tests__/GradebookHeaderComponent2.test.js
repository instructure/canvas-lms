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

import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook React Header Component References', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  describe('Secondary Info Configuration', () => {
    it('maintains configured secondary info when multiple sections are loaded', () => {
      const sections = [
        {id: 1, name: 'Section 1'},
        {id: 2, name: 'Section 2'},
      ]
      const settings = {
        student_column_secondary_info: 'login_id',
      }
      gradebook = createGradebook({sections, settings})

      expect(gradebook.getSelectedSecondaryInfo()).toBe('login_id')
    })

    it('maintains configured secondary info when one section is loaded', () => {
      const sections = [{id: 1, name: 'Section 1'}]
      const settings = {
        student_column_secondary_info: 'login_id',
      }
      gradebook = createGradebook({sections, settings})

      expect(gradebook.getSelectedSecondaryInfo()).toBe('login_id')
    })

    it('maintains configured secondary info when no sections are loaded', () => {
      const sections = []
      const settings = {
        student_column_secondary_info: 'login_id',
      }
      gradebook = createGradebook({sections, settings})

      expect(gradebook.getSelectedSecondaryInfo()).toBe('login_id')
    })
  })

  describe('Grading Periods', () => {
    it('sets submissionStateMap.hasGradingPeriods to true when grading period set exists', () => {
      gradebook = createGradebook({
        grading_period_set: {id: '1501', grading_periods: [{id: '701'}, {id: '702'}]},
      })
      expect(gradebook.submissionStateMap.hasGradingPeriods).toBe(true)
    })

    it('sets submissionStateMap.selectedGradingPeriodID to current grading period', () => {
      const grading_period_set = {
        id: '1501',
        grading_periods: [
          {id: '701', title: 'Grading Period 1', startDate: new Date(1)},
          {id: '702', title: 'Grading Period 2', startDate: new Date(2)},
        ],
      }
      gradebook = createGradebook({current_grading_period_id: '701', grading_period_set})
      expect(gradebook.submissionStateMap.selectedGradingPeriodID).toBe('701')
    })
  })

  describe('Custom Columns', () => {
    it('includes teacher notes in custom columns when provided', () => {
      const teacherNotes = {
        id: '2401',
        title: 'Notes',
        position: 1,
        teacher_notes: true,
        hidden: false,
      }
      gradebook = createGradebook({teacher_notes: teacherNotes})
      expect(gradebook.gradebookContent.customColumns).toEqual([teacherNotes])
    })

    it('maintains empty custom columns when teacher notes are not provided', () => {
      gradebook = createGradebook()
      expect(gradebook.gradebookContent.customColumns).toEqual([])
    })
  })
})
