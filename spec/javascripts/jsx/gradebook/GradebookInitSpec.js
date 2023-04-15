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
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook init')

test('correctly loads initial colors', () => {
  const color = '#F3EFEA'
  equal(
    createGradebook({
      colors: {late: color},
    }).options.colors.late,
    color
  )
})

test('normalizes the grading period set from the env', () => {
  const options = {
    grading_period_set: {
      id: '1501',
      grading_periods: [
        {id: '701', weight: 50},
        {id: '702', weight: 50},
      ],
      weighted: true,
    },
  }
  const gradingPeriodSet = createGradebook(options).gradingPeriodSet
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

QUnit.module('Gradebook#initialize', () => {
  QUnit.module('with dataloader stubs', moduleHooks => {
    moduleHooks.beforeEach(() => {
      setFixtureHtml($fixtures)
    })

    moduleHooks.afterEach(() => {
      $fixtures.innerHTML = ''
    })

    function createInitializedGradebook(options) {
      const gradebook = createGradebook(options)
      return gradebook
    }

    test('stores the late policy with camelized keys, if one exists', () => {
      const gradebook = createInitializedGradebook({
        late_policy: {late_submission_interval: 'hour'},
      })
      deepEqual(gradebook.courseContent.latePolicy, {lateSubmissionInterval: 'hour'})
    })

    test('stores the late policy as undefined if the late_policy option is null', () => {
      const gradebook = createInitializedGradebook({late_policy: null})
      strictEqual(gradebook.courseContent.latePolicy, undefined)
    })
  })
})

QUnit.module('Gradebook React Header Component References', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('#setHeaderComponentRef stores a reference by a column id', function () {
  const studentRef = {column: 'student'}
  const totalGradeRef = {column: 'total_grade'}
  this.gradebook.setHeaderComponentRef('student', studentRef)
  this.gradebook.setHeaderComponentRef('total_grade', totalGradeRef)
  equal(this.gradebook.getHeaderComponentRef('student'), studentRef)
  equal(this.gradebook.getHeaderComponentRef('total_grade'), totalGradeRef)
})

test('#setHeaderComponentRef replaces an existing reference', function () {
  const ref = {column: 'student'}
  this.gradebook.setHeaderComponentRef('student', {column: 'previous'})
  this.gradebook.setHeaderComponentRef('student', ref)
  equal(this.gradebook.getHeaderComponentRef('student'), ref)
})

test('#removeHeaderComponentRef removes an existing reference', function () {
  const ref = {column: 'student'}
  this.gradebook.setHeaderComponentRef('student', ref)
  this.gradebook.removeHeaderComponentRef('student')
  equal(typeof this.gradebook.getHeaderComponentRef('student'), 'undefined')
})

test('sets grading period set to null when not defined in the env', () => {
  const gradingPeriodSet = createGradebook().gradingPeriodSet
  deepEqual(gradingPeriodSet, null)
})

test('when sections are loaded and there is no secondary info configured, set it to "section"', () => {
  const sections = [
    {id: 1, name: 'Section 1'},
    {id: 2, name: 'Section 2'},
  ]
  const gradebook = createGradebook({sections})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'section')
})

test('when one section is loaded and there is no secondary info configured, set it to "none"', () => {
  const sections = [{id: 1, name: 'Section 1'}]
  const gradebook = createGradebook({sections})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'none')
})

test('when zero sections are loaded and there is no secondary info configured, set it to "none"', () => {
  const sections = []
  const gradebook = createGradebook({sections})

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'none')
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

QUnit.module('Gradebook#initPostGradesLtis')

test('sets postGradesLtis as an array', () => {
  const gradebook = createGradebook({post_grades_ltis: []})
  deepEqual(gradebook.postGradesLtis, [])
})
