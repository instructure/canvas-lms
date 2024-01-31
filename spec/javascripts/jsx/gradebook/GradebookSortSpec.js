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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import round from '@canvas/round'

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
