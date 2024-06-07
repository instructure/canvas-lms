/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import _ from 'lodash'
import {createGradebook} from './GradebookSpecHelper'

QUnit.module('Gradebook React Header Component References', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('when sections are loaded and there is secondary info configured, do not change it', () => {
  const sections = [
    {id: 1, name: 'Section 1'},
    {id: 2, name: 'Section 2'},
  ]
  const settings = {
    student_column_secondary_info: 'login_id',
  }
  const gradebook = createGradebook({sections, settings})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id')
})

test('when one section is loaded and there is secondary info configured, do not change it', () => {
  const sections = [{id: 1, name: 'Section 1'}]
  const settings = {
    student_column_secondary_info: 'login_id',
  }
  const gradebook = createGradebook({sections, settings})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id')
})

test('when zero sections are loaded and there is secondary info configured, do not change it', () => {
  const sections = []
  const settings = {
    student_column_secondary_info: 'login_id',
  }
  const gradebook = createGradebook({sections, settings})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id')
})

test('sets the submission state map .hasGradingPeriods to true when a grading period set exists', () => {
  const gradebook = createGradebook({
    grading_period_set: {id: '1501', grading_periods: [{id: '701'}, {id: '702'}]},
  })
  strictEqual(gradebook.submissionStateMap.hasGradingPeriods, true)
})

test('sets the submission state map .selectedGradingPeriodID to the current grading period', () => {
  const grading_period_set = {
    id: '1501',
    grading_periods: [
      {id: '701', title: 'Grading Period 1', startDate: new Date(1)},
      {id: '702', title: 'Grading Period 2', startDate: new Date(2)},
    ],
  }
  const gradebook = createGradebook({current_grading_period_id: '701', grading_period_set})
  strictEqual(gradebook.submissionStateMap.selectedGradingPeriodID, '701')
})

test('adds teacher notes to custom columns when provided', () => {
  const teacherNotes = {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false}
  const gradebook = createGradebook({teacher_notes: teacherNotes})
  deepEqual(gradebook.gradebookContent.customColumns, [teacherNotes])
})

test('custom columns remain empty when teacher notes are not provided', () => {
  const gradebook = createGradebook()
  deepEqual(gradebook.gradebookContent.customColumns, [])
})
