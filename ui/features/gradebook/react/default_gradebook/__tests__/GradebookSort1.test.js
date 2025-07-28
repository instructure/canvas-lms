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

describe('sortByStudentColumn', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  test('does not cause gradebook to forget about students that are loaded but not currently in view', () => {
    gradebook.courseContent.students.setStudentIds(['1', '3', '4'])

    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z'},
      {id: '4', sortable_name: 'A'},
    ]

    gradebook.sortByStudentColumn('sortable_name', 'ascending')
    const loadedStudentIds = gradebook.courseContent.students
      .listStudents()
      .map(student => student.id)
    expect(loadedStudentIds).toEqual(['1', '3', '4'])
  })

  test('sorts the gradebook rows', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z'},
      {id: '4', sortable_name: 'A'},
    ]
    gradebook.sortByStudentColumn('sortable_name', 'ascending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  test('sorts the gradebook rows descending', () => {
    gradebook.gridData.rows = [
      {id: '4', sortable_name: 'A'},
      {id: '3', sortable_name: 'Z'},
    ]
    gradebook.sortByStudentColumn('sortable_name', 'descending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test('sort gradebook rows by id when sortable names are the same', () => {
    gradebook.gridData.rows = [
      {id: '4', sortable_name: 'Same Name'},
      {id: '3', sortable_name: 'Same Name'},
    ]
    gradebook.sortByStudentColumn('sortable_name', 'ascending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test('descending sort gradebook rows by id sortable names are the same and direction is descending', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Same Name'},
      {id: '4', sortable_name: 'Same Name'},
    ]
    gradebook.sortByStudentColumn('someProperty', 'descending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })
})

describe('sortByCustomColumn', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  test('sorts the gradebook rows', () => {
    gradebook.gridData.rows = [
      {id: '3', custom_col_501: 'Z'},
      {id: '4', custom_col_501: 'A'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'ascending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.custom_col_501).toBe('A')
    expect(secondRow.custom_col_501).toBe('Z')
  })

  test('sorts the gradebook rows descending', () => {
    gradebook.gridData.rows = [
      {id: '4', custom_col_501: 'A'},
      {id: '3', custom_col_501: 'Z'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'descending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.custom_col_501).toBe('Z')
    expect(secondRow.custom_col_501).toBe('A')
  })

  test('sort gradebook rows by sortable_name when setting key is the same', () => {
    gradebook.gridData.rows = [
      {id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42'},
      {id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'ascending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.sortable_name).toBe('Ford, Betty')
    expect(secondRow.sortable_name).toBe('Jones, Adam')
  })

  test('descending sort gradebook rows by sortable_name when setting key is the same and direction is descending', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42'},
      {id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'descending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.sortable_name).toBe('Jones, Adam')
    expect(secondRow.sortable_name).toBe('Ford, Betty')
  })

  test('sort gradebook rows by id when setting key and sortable name are the same', () => {
    gradebook.gridData.rows = [
      {id: '4', sortable_name: 'Same Name', custom_col_501: '42'},
      {id: '3', sortable_name: 'Same Name', custom_col_501: '42'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'ascending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test('descending sort gradebook rows by id when setting key and sortable name are the same and direction is descending', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Same Name', custom_col_501: '42'},
      {id: '4', sortable_name: 'Same Name', custom_col_501: '42'},
    ]
    gradebook.sortByCustomColumn('custom_col_501', 'descending')
    const [firstRow, secondRow] = gradebook.gridData.rows

    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })
})

describe('sortByAssignmentColumn', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    jest
      .spyOn(gradebook, 'sortRowsBy')
      .mockImplementation(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    jest.spyOn(gradebook, 'gradeSort').mockImplementation()
    jest.spyOn(gradebook, 'missingSort').mockImplementation()
    jest.spyOn(gradebook, 'lateSort').mockImplementation()
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    expect(gradebook.sortRowsBy).toHaveBeenCalledTimes(1)
  })

  test('sorts using gradeSort when the settingKey is "grade"', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    expect(gradebook.gradeSort).toHaveBeenCalledTimes(1)
  })

  test('sorts by grade using the columnId', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    const field = gradebook.gradeSort.mock.calls[0][2]
    expect(field).toBe('assignment_201')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })

  test('optionally sorts by missing in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'missing', 'ascending')
    const columnId = gradebook.missingSort.mock.calls[0][0]
    expect(columnId).toBe('assignment_201')
  })

  test('optionally sorts by late in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'late', 'ascending')
    const columnId = gradebook.lateSort.mock.calls[0][0]
    expect(columnId).toBe('assignment_201')
  })
})

describe('sortByAssignmentGroupColumn', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    jest
      .spyOn(gradebook, 'sortRowsBy')
      .mockImplementation(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    jest.spyOn(gradebook, 'gradeSort').mockImplementation()
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    expect(gradebook.sortRowsBy).toHaveBeenCalledTimes(1)
  })

  test('sorts by grade using gradeSort', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    expect(gradebook.gradeSort).toHaveBeenCalledTimes(1)
  })

  test('sorts by grade using the columnId', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    const field = gradebook.gradeSort.mock.calls[0][2]
    expect(field).toBe('assignment_group_301')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })
})

describe('sortByTotalGradeColumn', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    jest
      .spyOn(gradebook, 'sortRowsBy')
      .mockImplementation(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    jest.spyOn(gradebook, 'gradeSort').mockImplementation()
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    expect(gradebook.sortRowsBy).toHaveBeenCalledTimes(1)
  })

  test('sorts by grade using gradeSort', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    expect(gradebook.gradeSort).toHaveBeenCalledTimes(1)
  })

  test('sorts by "total_grade"', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    const field = gradebook.gradeSort.mock.calls[0][2]
    expect(field).toBe('total_grade')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByTotalGradeColumn('descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.mock.calls[0]
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })
})
