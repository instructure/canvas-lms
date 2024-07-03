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

QUnit.module('sortByStudentColumn', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('does not cause gradebook to forget about students that are loaded but not currently in view', function () {
  this.gradebook.courseContent.students.setStudentIds(['1', '3', '4'])

  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Z'},
    {id: '4', sortable_name: 'A'},
  ]

  this.gradebook.sortByStudentColumn('sortable_name', 'ascending')
  const loadedStudentIds = this.gradebook.courseContent.students
    .listStudents()
    .map(student => student.id)
  deepEqual(loadedStudentIds, ['1', '3', '4'])
})

test('sorts the gradebook rows', function () {
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Z'},
    {id: '4', sortable_name: 'A'},
  ]
  this.gradebook.sortByStudentColumn('sortable_name', 'ascending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '4')
  strictEqual(secondRow.id, '3')
})

test('sorts the gradebook rows descending', function () {
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'A'},
    {id: '4', sortable_name: 'Z'},
  ]
  this.gradebook.sortByStudentColumn('sortable_name', 'descending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '4')
  strictEqual(secondRow.id, '3')
})

test('sort gradebook rows by id when sortable names are the same', function () {
  this.gradebook.gridData.rows = [
    {id: '4', sortable_name: 'Same Name'},
    {id: '3', sortable_name: 'Same Name'},
  ]
  this.gradebook.sortByStudentColumn('sortable_name', 'ascending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '3')
  strictEqual(secondRow.id, '4')
})

test('descending sort gradebook rows by id sortable names are the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Same Name'},
    {id: '4', sortable_name: 'Same Name'},
  ]
  this.gradebook.sortByStudentColumn('someProperty', 'descending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '4')
  strictEqual(secondRow.id, '3')
})

QUnit.module('sortByCustomColumn', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('sorts the gradebook rows', function () {
  this.gradebook.gridData.rows = [
    {id: '3', custom_col_501: 'Z'},
    {id: '4', custom_col_501: 'A'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.custom_col_501, 'A')
  strictEqual(secondRow.custom_col_501, 'Z')
})

test('sorts the gradebook rows descending', function () {
  this.gradebook.gridData.rows = [
    {id: '4', custom_col_501: 'A'},
    {id: '3', custom_col_501: 'Z'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.custom_col_501, 'Z')
  strictEqual(secondRow.custom_col_501, 'A')
})

test('sort gradebook rows by sortable_name when setting key is the same', function () {
  this.gradebook.gridData.rows = [
    {id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42'},
    {id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.sortable_name, 'Ford, Betty')
  strictEqual(secondRow.sortable_name, 'Jones, Adam')
})

test('descending sort gradebook rows by sortable_name when setting key is the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42'},
    {id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.sortable_name, 'Jones, Adam')
  strictEqual(secondRow.sortable_name, 'Ford, Betty')
})

test('sort gradebook rows by id when setting key and sortable name are the same', function () {
  this.gradebook.gridData.rows = [
    {id: '4', sortable_name: 'Same Name', custom_col_501: '42'},
    {id: '3', sortable_name: 'Same Name', custom_col_501: '42'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '3')
  strictEqual(secondRow.id, '4')
})

test('descending sort gradebook rows by id when setting key and sortable name are the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    {id: '3', sortable_name: 'Same Name', custom_col_501: '42'},
    {id: '4', sortable_name: 'Same Name', custom_col_501: '42'},
  ]
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending')
  const [firstRow, secondRow] = this.gradebook.gridData.rows

  strictEqual(firstRow.id, '4')
  strictEqual(secondRow.id, '3')
})

QUnit.module('sortByAssignmentColumn', {
  setup() {
    this.gradebook = createGradebook()
    this.studentA = {name: 'Adam Jones'}
    this.studentB = {name: 'Betty Ford'}
    sandbox
      .stub(this.gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(this.studentA, this.studentB))
    sandbox.stub(this.gradebook, 'gradeSort')
    sandbox.stub(this.gradebook, 'missingSort')
    sandbox.stub(this.gradebook, 'lateSort')
  },
})

test('sorts the gradebook rows', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
  equal(this.gradebook.sortRowsBy.callCount, 1)
})

test('sorts using gradeSort when the settingKey is "grade"', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
  equal(this.gradebook.gradeSort.callCount, 1)
})

test('sorts by grade using the columnId', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
  const field = this.gradebook.gradeSort.getCall(0).args[2]
  equal(field, 'assignment_201')
})

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, true, 'ascending is explicitly true')
})

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'descending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, false, 'ascending is explicitly false')
})

test('optionally sorts by missing in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'missing', 'ascending')
  const columnId = this.gradebook.missingSort.getCall(0).args
  equal(columnId, 'assignment_201')
})

test('optionally sorts by late in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'late', 'ascending')
  const columnId = this.gradebook.lateSort.getCall(0).args
  equal(columnId, 'assignment_201')
})

QUnit.module('sortByAssignmentGroupColumn', {
  setup() {
    this.gradebook = createGradebook()
    this.studentA = {name: 'Adam Jones'}
    this.studentB = {name: 'Betty Ford'}
    sandbox
      .stub(this.gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(this.studentA, this.studentB))
    sandbox.stub(this.gradebook, 'gradeSort')
  },
})

test('sorts the gradebook rows', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
  equal(this.gradebook.sortRowsBy.callCount, 1)
})

test('sorts by grade using gradeSort', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
  equal(this.gradebook.gradeSort.callCount, 1)
})

test('sorts by grade using the columnId', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
  const field = this.gradebook.gradeSort.getCall(0).args[2]
  equal(field, 'assignment_group_301')
})

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, true, 'ascending is explicitly true')
})

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'descending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, false, 'ascending is explicitly false')
})

QUnit.module('sortByTotalGradeColumn', {
  setup() {
    this.gradebook = createGradebook()
    this.studentA = {name: 'Adam Jones'}
    this.studentB = {name: 'Betty Ford'}
    sandbox
      .stub(this.gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(this.studentA, this.studentB))
    sandbox.stub(this.gradebook, 'gradeSort')
  },
})

test('sorts the gradebook rows', function () {
  this.gradebook.sortByTotalGradeColumn('ascending')
  equal(this.gradebook.sortRowsBy.callCount, 1)
})

test('sorts by grade using gradeSort', function () {
  this.gradebook.sortByTotalGradeColumn('ascending')
  equal(this.gradebook.gradeSort.callCount, 1)
})

test('sorts by "total_grade"', function () {
  this.gradebook.sortByTotalGradeColumn('ascending')
  const field = this.gradebook.gradeSort.getCall(0).args[2]
  equal(field, 'total_grade')
})

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByTotalGradeColumn('ascending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, true, 'ascending is explicitly true')
})

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByTotalGradeColumn('descending')
  const [studentA, studentB /* field */, , ascending] = this.gradebook.gradeSort.getCall(0).args
  equal(studentA, this.studentA, 'student A is in first position')
  equal(studentB, this.studentB, 'student B is in second position')
  equal(ascending, false, 'ascending is explicitly false')
})

QUnit.module('Gradebook#sortGridRows', {
  setup() {
    this.gradebook = createGradebook()
    this.server = sinon.fakeServer.create({respondImmediately: true})
    const options = {settings_update_url: '/course/1/gradebook_settings'}
    this.server.respondWith('POST', options.settings_update_url, [
      200,
      {'Content-Type': 'application/json'},
      '{}',
    ])
  },

  teardown() {
    this.server.restore()
  },
})

test('sorts by the student column by default', function () {
  sandbox.stub(this.gradebook, 'sortByStudentColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByStudentColumn.callCount, 1)
})

test('uses the saved sort setting for student column sorting', function () {
  this.gradebook.setSortRowsBySetting('student_name', 'sortable_name', 'ascending')
  sandbox.stub(this.gradebook, 'sortByStudentColumn')
  this.gradebook.sortGridRows()

  const [settingKey, direction] = this.gradebook.sortByStudentColumn.getCall(0).args
  equal(settingKey, 'sortable_name', 'parameter 1 is the sort settingKey')
  equal(direction, 'ascending', 'parameter 2 is the sort direction')
})

test('optionally sorts by a custom column', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending')
  sandbox.stub(this.gradebook, 'sortByCustomColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByCustomColumn.callCount, 1)
})

test('uses the saved sort setting for custom column sorting', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending')
  sandbox.stub(this.gradebook, 'sortByCustomColumn')
  this.gradebook.sortGridRows()

  const [columnId, direction] = this.gradebook.sortByCustomColumn.getCall(0).args
  equal(columnId, 'custom_col_501', 'parameter 1 is the sort columnId')
  equal(direction, 'ascending', 'parameter 2 is the sort direction')
})

test('optionally sorts by an assignment column', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1)
})

test('uses the saved sort setting for assignment sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn')
  this.gradebook.sortGridRows()

  const [columnId, settingKey, direction] = this.gradebook.sortByAssignmentColumn.getCall(0).args
  equal(columnId, 'assignment_201', 'parameter 1 is the sort columnId')
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey')
  equal(direction, 'ascending', 'parameter 3 is the sort direction')
})

test('optionally sorts by an assignment group column', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentGroupColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByAssignmentGroupColumn.callCount, 1)
})

test('uses the saved sort setting for assignment group sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentGroupColumn')
  this.gradebook.sortGridRows()

  const [columnId, settingKey, direction] =
    this.gradebook.sortByAssignmentGroupColumn.getCall(0).args
  equal(columnId, 'assignment_group_301', 'parameter 1 is the sort columnId')
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey')
  equal(direction, 'ascending', 'parameter 3 is the sort direction')
})

test('optionally sorts by the total grade column', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByTotalGradeColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByTotalGradeColumn.callCount, 1)
})

test('uses the saved sort setting for total grade sorting', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending')
  sandbox.stub(this.gradebook, 'sortByTotalGradeColumn')
  this.gradebook.sortGridRows()

  const [direction] = this.gradebook.sortByTotalGradeColumn.getCall(0).args
  equal(direction, 'ascending', 'the only parameter is the sort direction')
})

test('optionally sorts by missing', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'missing', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1)
})

test('optionally sorts by late', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'late', 'ascending')
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn')
  this.gradebook.sortGridRows()
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1)
})

test('updates the column headers after sorting', function () {
  sandbox.stub(this.gradebook, 'sortByStudentColumn')
  sandbox.stub(this.gradebook, 'updateColumnHeaders').callsFake(() => {
    equal(this.gradebook.sortByStudentColumn.callCount, 1, 'sorting method was called first')
  })
  this.gradebook.sortGridRows()
})

QUnit.module('Gradebook#getColumnSortSettingsViewOptionsMenuProps', {
  getProps(sortType = 'due_date', direction = 'ascending') {
    this.gradebook.setColumnOrder({direction, sortType})
    return this.gradebook.getColumnSortSettingsViewOptionsMenuProps()
  },

  expectedArgs(sortType, direction) {
    return [{sortType, direction}, false]
  },

  setup() {
    this.gradebook = createGradebook()
    sandbox.stub(this.gradebook, 'arrangeColumnsBy')
  },
})

test('includes all required properties', function () {
  const props = this.getProps()

  equal(typeof props.criterion, 'string', 'props include "criterion"')
  equal(typeof props.direction, 'string', 'props include "direction"')
  equal(typeof props.disabled, 'boolean', 'props include "disabled"')
  equal(typeof props.onSortByDefault, 'function', 'props include "onSortByDefault"')
  equal(typeof props.onSortByNameAscending, 'function', 'props include "onSortByNameAscending"')
  equal(typeof props.onSortByNameDescending, 'function', 'props include "onSortByNameDescending"')
  equal(
    typeof props.onSortByDueDateAscending,
    'function',
    'props include "onSortByDueDateAscending"'
  )
  equal(
    typeof props.onSortByDueDateDescending,
    'function',
    'props include "onSortByDueDateDescending"'
  )
  equal(typeof props.onSortByPointsAscending, 'function', 'props include "onSortByPointsAscending"')
  equal(
    typeof props.onSortByPointsDescending,
    'function',
    'props include "onSortByPointsDescending"'
  )
})

test('sets criterion to the sort field', function () {
  strictEqual(this.getProps().criterion, 'due_date')
  strictEqual(this.getProps('name').criterion, 'name')
})

test('sets criterion to "default" when isDefaultSortOrder returns true', function () {
  strictEqual(this.getProps('assignment_group').criterion, 'default')
})

test('sets the direction', function () {
  strictEqual(this.getProps(undefined, 'ascending').direction, 'ascending')
  strictEqual(this.getProps(undefined, 'descending').direction, 'descending')
})

test('sets disabled to true when assignments have not been loaded yet', function () {
  strictEqual(this.getProps().disabled, true)
})

test('sets disabled to false when assignments have been loaded', function () {
  this.gradebook.setAssignmentsLoaded()

  strictEqual(this.getProps().disabled, false)
})

test('sets modulesEnabled to true when there are modules in the current course', function () {
  this.gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])

  strictEqual(this.getProps().modulesEnabled, true)
})

test('sets modulesEnabled to false when there are no modules in the current course', function () {
  this.gradebook.setContextModules([])

  strictEqual(this.getProps().modulesEnabled, false)
})

test('sets onSortByNameAscending to a function that sorts columns by name ascending', function () {
  this.getProps().onSortByNameAscending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'ascending'))
})

test('sets onSortByNameDescending to a function that sorts columns by name descending', function () {
  this.getProps().onSortByNameDescending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'descending'))
})

test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', function () {
  this.getProps().onSortByDueDateAscending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('due_date', 'ascending')
  )
})

test('sets onSortByDueDateDescending to a function that sorts columns by due date descending', function () {
  this.getProps().onSortByDueDateDescending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('due_date', 'descending')
  )
})

test('sets onSortByPointsAscending to a function that sorts columns by points ascending', function () {
  this.getProps().onSortByPointsAscending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('points', 'ascending')
  )
})

test('sets onSortByPointsDescending to a function that sorts columns by points descending', function () {
  this.getProps().onSortByPointsDescending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('points', 'descending')
  )
})

test('sets onSortByModuleAscending to a function that sorts columns by module position ascending', function () {
  this.getProps().onSortByModuleAscending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('module_position', 'ascending')
  )
})

test('sets onSortByModuleDescending to a function that sorts columns by module position descending', function () {
  this.getProps().onSortByModuleDescending()

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1)
  deepEqual(
    this.gradebook.arrangeColumnsBy.firstCall.args,
    this.expectedArgs('module_position', 'descending')
  )
})
