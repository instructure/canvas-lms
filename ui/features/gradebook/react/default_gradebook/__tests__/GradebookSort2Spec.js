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

import {createGradebook} from './GradebookSpecHelper'
import round from '@canvas/round'

QUnit.module('Gradebook#setSortRowsBySetting', hooks => {
  let server
  let options
  let gradebook

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({respondImmediately: true})
    options = {settings_update_url: '/course/1/gradebook_settings'}
    server.respondWith('POST', options.settings_update_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])
    gradebook = createGradebook(options)
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('sets the "sort rows by" setting', () => {
    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending')
    const sortRowsBySetting = gradebook.getSortRowsBySetting()
    equal(sortRowsBySetting.columnId, 'assignment_201')
    equal(sortRowsBySetting.settingKey, 'grade')
    equal(sortRowsBySetting.direction, 'descending')
  })

  test('sorts the grid rows after updating the setting', () => {
    sandbox.stub(gradebook, 'sortGridRows').callsFake(() => {
      const sortRowsBySetting = gradebook.getSortRowsBySetting()
      equal(
        sortRowsBySetting.columnId,
        'assignment_201',
        'sortRowsBySetting.columnId was set beforehand'
      )
      equal(
        sortRowsBySetting.settingKey,
        'grade',
        'sortRowsBySetting.settingKey was set beforehand'
      )
      equal(
        sortRowsBySetting.direction,
        'descending',
        'sortRowsBySetting.direction was set beforehand'
      )
    })
    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending')
  })
})

QUnit.module('Gradebook#sortRowsWithFunction', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', someProperty: false},
      {id: '4', sortable_name: 'A Firstington', someProperty: true},
    ]
  },
  sortFn(row) {
    return row.someProperty
  },
})

test('returns two objects in the rows collection', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn)

  equal(this.gradebook.gridData.rows.length, 2)
})

test('sorts with a passed in function', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn)
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'when fn is true, order first')
  equal(secondRow.id, '3', 'when fn is false, order second')
})

test('sorts by descending when asc is false', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn, {asc: false})
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '3', 'when fn is false, order first')
  equal(secondRow.id, '4', 'when fn is true, order second')
})

test('relies on idSort when rows have equal sorting criteria and the same sortable name', function () {
  const value = 0
  this.gradebook.gridData.rows[0].someProperty = value
  this.gradebook.gridData.rows[1].someProperty = value
  const name = 'Same Name'
  this.gradebook.gridData.rows[0].sortable_name = name
  this.gradebook.gridData.rows[1].sortable_name = name
  this.gradebook.sortRowsWithFunction(this.sortFn)
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '3', 'lower id sorts first')
  equal(secondRow.id, '4', 'higher id sorts second')
})

test('relies on descending idSort when rows have equal sorting criteria and the same sortable name', function () {
  const value = 0
  this.gradebook.gridData.rows[0].someProperty = value
  this.gradebook.gridData.rows[1].someProperty = value
  const name = 'Same Name'
  this.gradebook.gridData.rows[0].sortable_name = name
  this.gradebook.gridData.rows[1].sortable_name = name
  this.gradebook.sortRowsWithFunction(this.sortFn, {asc: false})
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'higher id sorts first')
  equal(secondRow.id, '3', 'lower id sorts second')
})

QUnit.module('Gradebook#missingSort', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {missing: false}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {missing: true}},
    ]
  },
})

test('sorts by missing', function () {
  this.gradebook.missingSort('assignment_201')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'when missing is true, order first')
  equal(secondRow.id, '3', 'when missing is false, order second')
})

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.gridData.rows = [
    {id: '1', sortable_name: 'Z Last Graded', assignment_201: {missing: false}},
    {id: '3', sortable_name: 'Z Last Missing', assignment_201: {missing: true}},
    {id: '2', sortable_name: 'A First Graded', assignment_201: {missing: false}},
    {id: '4', sortable_name: 'A First Missing', assignment_201: {missing: true}},
  ]
  this.gradebook.missingSort('assignment_201')
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows

  equal(firstRow.sortable_name, 'A First Missing', 'A First Missing sorts first')
  equal(secondRow.sortable_name, 'Z Last Missing', 'Z Last Missing sorts second')
  equal(thirdRow.sortable_name, 'A First Graded', 'A First Graded sorts third')
  equal(fourthRow.sortable_name, 'Z Last Graded', 'Z Last Graded sorts fourth')
})

test('relies on id sorting when rows have equal sorting criteria results and same sortable name', function () {
  this.gradebook.gridData.rows = [
    {id: '2', sortable_name: 'Student Name', assignment_201: {missing: true}},
    {id: '3', sortable_name: 'Student Name', assignment_201: {missing: true}},
    {id: '4', sortable_name: 'Student Name', assignment_201: {missing: true}},
    {id: '1', sortable_name: 'Student Name', assignment_201: {missing: true}},
  ]
  this.gradebook.missingSort('assignment_201')
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '1')
  equal(secondRow.id, '2')
  equal(thirdRow.id, '3')
  equal(fourthRow.id, '4')
})

test('when no submission is found, it is missing', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Z Lastington', assignment_201: {missing: false}},
    {id: '4', sortable_name: 'A Firstington', assignment_201: {}},
  ]
  this.gradebook.lateSort('assignment_201')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'missing assignment sorts first')
  equal(secondRow.id, '3', 'graded assignment sorts second')
})

QUnit.module('Gradebook#lateSort', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {late: false}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {late: true}},
    ]
  },
})

test('sorts by late', function () {
  this.gradebook.lateSort('assignment_201')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'when late is true, order first')
  equal(secondRow.id, '3', 'when late is false, order second')
})

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.gridData.rows = [
    {id: '1', sortable_name: 'Z Last Not Late', assignment_201: {late: false}},
    {id: '3', sortable_name: 'Z Last Late', assignment_201: {late: true}},
    {id: '2', sortable_name: 'A First Not Late', assignment_201: {late: false}},
    {id: '4', sortable_name: 'A First Late', assignment_201: {late: true}},
  ]
  this.gradebook.lateSort('assignment_201')
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows

  equal(firstRow.sortable_name, 'A First Late', 'A First Late sorts first')
  equal(secondRow.sortable_name, 'Z Last Late', 'Z Last Late sorts second')
  equal(thirdRow.sortable_name, 'A First Not Late', 'A First Not Late sorts third')
  equal(fourthRow.sortable_name, 'Z Last Not Late', 'Z Last Not Late sorts fourth')
})

test('relies on id sort when rows have equal sorting criteria results and the same sortable name', function () {
  this.gradebook.gridData.rows = [
    {id: '4', sortable_name: 'Student Name', assignment_201: {late: true}},
    {id: '3', sortable_name: 'Student Name', assignment_201: {late: true}},
    {id: '2', sortable_name: 'Student Name', assignment_201: {late: true}},
    {id: '1', sortable_name: 'Student Name', assignment_201: {late: true}},
  ]
  this.gradebook.lateSort('assignment_201')
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '1')
  equal(secondRow.id, '2')
  equal(thirdRow.id, '3')
  equal(fourthRow.id, '4')
})

test('when no submission is found, it is not late', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key (e.g. `late`)
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Z Lastington', assignment_201: {}},
    {id: '4', sortable_name: 'A Firstington', assignment_201: {late: true}},
  ]
  this.gradebook.lateSort('assignment_201')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  equal(firstRow.id, '4', 'when late is true, order first')
  equal(secondRow.id, '3', 'when no submission is found, order second')
})

QUnit.module('Gradebook#compareAssignmentModulePositions - when neither record has module info', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
    sinon.spy(this.gradebook, 'compareAssignmentPositions')

    this.firstRecord = {
      object: {
        module_ids: [],
        module_positions: [],
        assignment_group: {
          position: 1,
        },
        position: 1,
      },
    }
    this.secondRecord = {
      object: {
        module_ids: [],
        module_positions: [],
        assignment_group: {
          position: 1,
        },
        position: 2,
      },
    }

    this.comparisonResult = this.gradebook.compareAssignmentModulePositions(
      this.firstRecord,
      this.secondRecord
    )
  },
})

QUnit.module('Gradebook#compareAssignmentModulePositions - when both records have module info', {
  createRecord(moduleId, positionInModule) {
    return {
      object: {
        module_ids: [moduleId],
        module_positions: [positionInModule],
      },
    }
  },

  setup() {
    this.gradebook = createGradebook()
    this.gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Another Module', position: 2},
      {id: '3', name: 'Module 2', position: 3},
    ])
  },
})

test("returns a negative number if the position of the first record's module comes first", function () {
  const firstRecord = this.createRecord('1', 1)
  const secondRecord = this.createRecord('2', 1)

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) < 0)
})

test("returns a positive number if the position of the first record's module comes later", function () {
  const firstRecord = this.createRecord('2', 1)
  const secondRecord = this.createRecord('1', 1)

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) > 0)
})

test('returns a negative number if within the same module the position of the first record comes first', function () {
  const firstRecord = this.createRecord('1', 1)
  const secondRecord = this.createRecord('1', 2)

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) < 0)
})

test('returns a positive number if within the same module the position of the first record comes later', function () {
  const firstRecord = this.createRecord('1', 2)
  const secondRecord = this.createRecord('1', 1)

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) > 0)
})

test('returns a zero if both records are in the same module at the same position', function () {
  const firstRecord = this.createRecord('1', 1)
  const secondRecord = this.createRecord('1', 1)

  strictEqual(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord), 0)
})

QUnit.module('Gradebook#compareAssignmentModulePositions - when only one record has module info', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
    this.firstRecord = {
      object: {
        module_ids: ['1'],
        module_positions: [1],
      },
    }
    this.secondRecord = {
      object: {
        module_ids: [],
        module_positions: [],
      },
    }
  },
})

test('returns a negative number when the first record has module information but the second does not', function () {
  ok(this.gradebook.compareAssignmentModulePositions(this.firstRecord, this.secondRecord) < 0)
})

test('returns a positive number when the first record has no module information but the second does', function () {
  ok(this.gradebook.compareAssignmentModulePositions(this.secondRecord, this.firstRecord) > 0)
})

QUnit.module('Gradebook#gradeSort by "total_grade"', {
  setup() {
    this.studentA = {total_grade: {score: 10, possible: 20}}
    this.studentB = {total_grade: {score: 6, possible: 10}}
  },
})

test('sorts by percent when not showing total grade as points', function () {
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true)
  // a negative value indicates preserving the order of inputs
  equal(round(comparison, 1), -0.1, 'studentB with the higher percent is ordered second')
})

test('sorts percent grades with no points possible at lowest priority', function () {
  this.studentA.total_grade.possible = 0
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true)
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second')
})

test('sorts percent grades with no points possible at lowest priority in descending order', function () {
  this.studentA.total_grade.possible = 0
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', false)
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second')
})

test('sorts by score when showing total grade as points', function () {
  const gradebook = createGradebook({show_total_grade_as_points: true})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true)
  // a positive value indicates reversing the order of inputs
  equal(comparison, 4, 'studentA with the higher score is ordered second')
})

test('optionally sorts in descending order', function () {
  const gradebook = createGradebook({show_total_grade_as_points: true})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', false)
  // a negative value indicates preserving the order of inputs
  equal(comparison, -4, 'studentA with the higher score is ordered first')
})

QUnit.module('Gradebook#gradeSort by an assignment group', {
  setup() {
    this.studentA = {assignment_group_301: {score: 10, possible: 20}}
    this.studentB = {assignment_group_301: {score: 6, possible: 10}}
  },
})

test('always sorts by percent', function () {
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', true)
  // a negative value indicates preserving the order of inputs
  equal(round(comparison, 1), -0.1, 'studentB with the higher percent is ordered second')
})

test('optionally sorts in descending order', function () {
  const gradebook = createGradebook({show_total_grade_as_points: true})
  const comparison = gradebook.gradeSort(
    this.studentA,
    this.studentB,
    'assignment_group_301',
    false
  )
  // a positive value indicates reversing the order of inputs
  equal(round(comparison, 1), 0.1, 'studentB with the higher percent is ordered first')
})

test('sorts grades with no points possible at lowest priority', function () {
  this.studentA.assignment_group_301.possible = 0
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', true)
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second')
})

test('sorts grades with no points possible at lowest priority in descending order', function () {
  this.studentA.assignment_group_301.possible = 0
  const gradebook = createGradebook({show_total_grade_as_points: false})
  const comparison = gradebook.gradeSort(
    this.studentA,
    this.studentB,
    'assignment_group_301',
    false
  )
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second')
})

QUnit.module('Gradebook#gradeSort by an assignment', {
  setup() {
    this.studentA = {
      id: '1',
      sortable_name: 'A, Student',
      assignment_201: {score: 10, possible: 20},
    }
    this.studentB = {id: '2', sortable_name: 'B, Student', assignment_201: {score: 6, possible: 10}}
    this.gradebook = createGradebook()
  },
})

test('sorts by score', function () {
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true)
  // a positive value indicates reversing the order of inputs
  strictEqual(comparison, 4, 'studentA with the higher score is ordered second')
})

test('optionally sorts in descending order', function () {
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false)
  // a negative value indicates preserving the order of inputs
  equal(comparison, -4, 'studentA with the higher score is ordered first')
})

test('returns -1 when sorted by sortable name where scores are the same', function () {
  const score = 10
  this.studentA.assignment_201.score = score
  this.studentB.assignment_201.score = score
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true)
  strictEqual(comparison, -1)
})

test('returns 1 when sorted by sortable name descending where scores are the same and sorting by descending', function () {
  const score = 10
  this.studentA.assignment_201.score = score
  this.studentB.assignment_201.score = score
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false)
  strictEqual(comparison, 1)
})

test('returns -1 when sorted by id where scores and sortable names are the same', function () {
  const score = 10
  this.studentA.assignment_201.score = score
  this.studentB.assignment_201.score = score
  const name = 'Same Name'
  this.studentA.sortable_name = name
  this.studentB.sortable_name = name
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true)
  strictEqual(comparison, -1)
})

test('returns 1 when descending sorted by id where where scores and sortable names are the same and sorting by descending', function () {
  const score = 10
  this.studentA.assignment_201.score = score
  this.studentB.assignment_201.score = score
  const name = 'Same Name'
  this.studentA.sortable_name = name
  this.studentB.sortable_name = name
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false)
  strictEqual(comparison, 1)
})
