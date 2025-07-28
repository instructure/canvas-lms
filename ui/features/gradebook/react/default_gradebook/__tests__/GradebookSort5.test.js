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

describe('Gradebook#setSortRowsBySetting', () => {
  let options
  let gradebook

  beforeEach(() => {
    options = {settings_update_url: '/course/1/gradebook_settings'}
    gradebook = createGradebook(options)

    // Mock the saveSettings method to prevent actual HTTP requests
    gradebook.saveSettings = jest.fn().mockResolvedValue({})
  })

  it('sets the "sort rows by" setting', () => {
    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending')
    const sortRowsBySetting = gradebook.getSortRowsBySetting()
    expect(sortRowsBySetting.columnId).toBe('assignment_201')
    expect(sortRowsBySetting.settingKey).toBe('grade')
    expect(sortRowsBySetting.direction).toBe('descending')
  })

  it('sorts the grid rows after updating the setting', () => {
    gradebook.sortGridRows = jest.fn()

    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending')

    expect(gradebook.sortGridRows).toHaveBeenCalled()

    // Verify that the setting was updated before sorting
    const sortRowsBySetting = gradebook.getSortRowsBySetting()
    expect(sortRowsBySetting.columnId).toBe('assignment_201')
    expect(sortRowsBySetting.settingKey).toBe('grade')
    expect(sortRowsBySetting.direction).toBe('descending')
  })
})

describe('Gradebook#sortRowsWithFunction', () => {
  let gradebook
  const sortFn = row => row.someProperty

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', someProperty: false},
      {id: '4', sortable_name: 'A Firstington', someProperty: true},
    ]
  })

  it('returns two objects in the rows collection', () => {
    gradebook.sortRowsWithFunction(sortFn)
    expect(gradebook.gridData.rows).toHaveLength(2)
  })

  it('sorts with a passed in function', () => {
    gradebook.sortRowsWithFunction(sortFn)
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  it('sorts by descending when asc is false', () => {
    gradebook.sortRowsWithFunction(sortFn, {asc: false})
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  it('relies on idSort when rows have equal sorting criteria and the same sortable name', () => {
    const value = 0
    gradebook.gridData.rows[0].someProperty = value
    gradebook.gridData.rows[1].someProperty = value
    const name = 'Same Name'
    gradebook.gridData.rows[0].sortable_name = name
    gradebook.gridData.rows[1].sortable_name = name
    gradebook.sortRowsWithFunction(sortFn)
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  it('relies on descending idSort when rows have equal sorting criteria and the same sortable name', () => {
    const value = 0
    gradebook.gridData.rows[0].someProperty = value
    gradebook.gridData.rows[1].someProperty = value
    const name = 'Same Name'
    gradebook.gridData.rows[0].sortable_name = name
    gradebook.gridData.rows[1].sortable_name = name
    gradebook.sortRowsWithFunction(sortFn, {asc: false})
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })
})

describe('Gradebook#missingSort', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {missing: false}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {missing: true}},
    ]
  })

  it('sorts by missing', () => {
    gradebook.missingSort('assignment_201')
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  it('relies on localeSort when rows have equal sorting criteria results', () => {
    gradebook.gridData.rows = [
      {id: '1', sortable_name: 'Z Last Graded', assignment_201: {missing: false}},
      {id: '3', sortable_name: 'Z Last Missing', assignment_201: {missing: true}},
      {id: '2', sortable_name: 'A First Graded', assignment_201: {missing: false}},
      {id: '4', sortable_name: 'A First Missing', assignment_201: {missing: true}},
    ]
    gradebook.missingSort('assignment_201')
    const [firstRow, secondRow, thirdRow, fourthRow] = gradebook.gridData.rows
    expect(firstRow.sortable_name).toBe('A First Missing')
    expect(secondRow.sortable_name).toBe('Z Last Missing')
    expect(thirdRow.sortable_name).toBe('A First Graded')
    expect(fourthRow.sortable_name).toBe('Z Last Graded')
  })

  it('relies on id sorting when rows have equal sorting criteria results and same sortable name', () => {
    gradebook.gridData.rows = [
      {id: '2', sortable_name: 'Student Name', assignment_201: {missing: true}},
      {id: '3', sortable_name: 'Student Name', assignment_201: {missing: true}},
      {id: '4', sortable_name: 'Student Name', assignment_201: {missing: true}},
      {id: '1', sortable_name: 'Student Name', assignment_201: {missing: true}},
    ]
    gradebook.missingSort('assignment_201')
    const [firstRow, secondRow, thirdRow, fourthRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('1')
    expect(secondRow.id).toBe('2')
    expect(thirdRow.id).toBe('3')
    expect(fourthRow.id).toBe('4')
  })

  it('when no submission is found, it is missing', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {missing: false}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {}},
    ]
    gradebook.missingSort('assignment_201')
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })
})

describe('Gradebook#lateSort', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {late: false}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {late: true}},
    ]
  })

  it('sorts by late', () => {
    gradebook.lateSort('assignment_201')
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  it('relies on localeSort when rows have equal sorting criteria results', () => {
    gradebook.gridData.rows = [
      {id: '1', sortable_name: 'Z Last Not Late', assignment_201: {late: false}},
      {id: '3', sortable_name: 'Z Last Late', assignment_201: {late: true}},
      {id: '2', sortable_name: 'A First Not Late', assignment_201: {late: false}},
      {id: '4', sortable_name: 'A First Late', assignment_201: {late: true}},
    ]
    gradebook.lateSort('assignment_201')
    const [firstRow, secondRow, thirdRow, fourthRow] = gradebook.gridData.rows
    expect(firstRow.sortable_name).toBe('A First Late')
    expect(secondRow.sortable_name).toBe('Z Last Late')
    expect(thirdRow.sortable_name).toBe('A First Not Late')
    expect(fourthRow.sortable_name).toBe('Z Last Not Late')
  })

  it('relies on id sort when rows have equal sorting criteria results and the same sortable name', () => {
    gradebook.gridData.rows = [
      {id: '4', sortable_name: 'Student Name', assignment_201: {late: true}},
      {id: '3', sortable_name: 'Student Name', assignment_201: {late: true}},
      {id: '2', sortable_name: 'Student Name', assignment_201: {late: true}},
      {id: '1', sortable_name: 'Student Name', assignment_201: {late: true}},
    ]
    gradebook.lateSort('assignment_201')
    const [firstRow, secondRow, thirdRow, fourthRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('1')
    expect(secondRow.id).toBe('2')
    expect(thirdRow.id).toBe('3')
    expect(fourthRow.id).toBe('4')
  })

  it('when no submission is found, it is not late', () => {
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z Lastington', assignment_201: {}},
      {id: '4', sortable_name: 'A Firstington', assignment_201: {late: true}},
    ]
    gradebook.lateSort('assignment_201')
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })
})

describe('Gradebook#compareAssignmentModulePositions - when both records have module info', () => {
  let gradebook

  const createRecord = (moduleId, positionInModule) => ({
    object: {
      module_ids: [moduleId],
      module_positions: [positionInModule],
    },
  })

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Another Module', position: 2},
      {id: '3', name: 'Module 2', position: 3},
    ])
  })

  it("returns a negative number if the position of the first record's module comes first", () => {
    const firstRecord = createRecord('1', 1)
    const secondRecord = createRecord('2', 1)
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBeLessThan(0)
  })

  it("returns a positive number if the position of the first record's module comes later", () => {
    const firstRecord = createRecord('2', 1)
    const secondRecord = createRecord('1', 1)
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBeGreaterThan(0)
  })

  it('returns a negative number if within the same module the position of the first record comes first', () => {
    const firstRecord = createRecord('1', 1)
    const secondRecord = createRecord('1', 2)
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBeLessThan(0)
  })

  it('returns a positive number if within the same module the position of the first record comes later', () => {
    const firstRecord = createRecord('1', 2)
    const secondRecord = createRecord('1', 1)
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBeGreaterThan(0)
  })

  it('returns zero if both records are in the same module at the same position', () => {
    const firstRecord = createRecord('1', 1)
    const secondRecord = createRecord('1', 1)
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBe(0)
  })
})

describe('Gradebook#compareAssignmentModulePositions - when only one record has module info', () => {
  let gradebook, firstRecord, secondRecord

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
    firstRecord = {
      object: {
        module_ids: ['1'],
        module_positions: [1],
      },
    }
    secondRecord = {
      object: {
        module_ids: [],
        module_positions: [],
      },
    }
  })

  it('returns a negative number when the first record has module information but the second does not', () => {
    expect(gradebook.compareAssignmentModulePositions(firstRecord, secondRecord)).toBeLessThan(0)
  })

  it('returns a positive number when the first record has no module information but the second does', () => {
    expect(gradebook.compareAssignmentModulePositions(secondRecord, firstRecord)).toBeGreaterThan(0)
  })
})

describe('Gradebook#gradeSort by "total_grade"', () => {
  let studentA, studentB

  beforeEach(() => {
    studentA = {total_grade: {score: 10, possible: 20}}
    studentB = {total_grade: {score: 6, possible: 10}}
  })

  it('sorts by percent when not showing total grade as points', () => {
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'total_grade', true)
    expect(round(comparison, 1)).toBe(-0.1)
  })

  it('sorts percent grades with no points possible at lowest priority', () => {
    studentA.total_grade.possible = 0
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'total_grade', true)
    expect(comparison).toBe(1)
  })

  it('sorts percent grades with no points possible at lowest priority in descending order', () => {
    studentA.total_grade.possible = 0
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'total_grade', false)
    expect(comparison).toBe(1)
  })

  it('sorts by score when showing total grade as points', () => {
    const gradebook = createGradebook({show_total_grade_as_points: true})
    const comparison = gradebook.gradeSort(studentA, studentB, 'total_grade', true)
    expect(comparison).toBe(4)
  })

  it('optionally sorts in descending order', () => {
    const gradebook = createGradebook({show_total_grade_as_points: true})
    const comparison = gradebook.gradeSort(studentA, studentB, 'total_grade', false)
    expect(comparison).toBe(-4)
  })
})

describe('Gradebook#gradeSort by an assignment group', () => {
  let studentA, studentB

  beforeEach(() => {
    studentA = {assignment_group_301: {score: 10, possible: 20}}
    studentB = {assignment_group_301: {score: 6, possible: 10}}
  })

  it('always sorts by percent', () => {
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_group_301', true)
    expect(round(comparison, 1)).toBe(-0.1)
  })

  it('optionally sorts in descending order', () => {
    const gradebook = createGradebook({show_total_grade_as_points: true})
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_group_301', false)
    expect(round(comparison, 1)).toBe(0.1)
  })

  it('sorts grades with no points possible at lowest priority', () => {
    studentA.assignment_group_301.possible = 0
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_group_301', true)
    expect(comparison).toBe(1)
  })

  it('sorts grades with no points possible at lowest priority in descending order', () => {
    studentA.assignment_group_301.possible = 0
    const gradebook = createGradebook({show_total_grade_as_points: false})
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_group_301', false)
    expect(comparison).toBe(1)
  })
})

describe('Gradebook#gradeSort by an assignment', () => {
  let studentA, studentB, gradebook

  beforeEach(() => {
    studentA = {
      id: '1',
      sortable_name: 'A, Student',
      assignment_201: {score: 10, possible: 20},
    }
    studentB = {id: '2', sortable_name: 'B, Student', assignment_201: {score: 6, possible: 10}}
    gradebook = createGradebook()
  })

  it('sorts by score', () => {
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', true)
    expect(comparison).toBe(4)
  })

  it('optionally sorts in descending order', () => {
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', false)
    expect(comparison).toBe(-4)
  })

  it('returns -1 when sorted by sortable name where scores are the same', () => {
    const score = 10
    studentA.assignment_201.score = score
    studentB.assignment_201.score = score
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', true)
    expect(comparison).toBe(-1)
  })

  it('returns 1 when sorted by sortable name descending where scores are the same and sorting by descending', () => {
    const score = 10
    studentA.assignment_201.score = score
    studentB.assignment_201.score = score
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', false)
    expect(comparison).toBe(1)
  })

  it('returns -1 when sorted by id where scores and sortable names are the same', () => {
    const score = 10
    studentA.assignment_201.score = score
    studentB.assignment_201.score = score
    const name = 'Same Name'
    studentA.sortable_name = name
    studentB.sortable_name = name
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', true)
    expect(comparison).toBe(-1)
  })

  it('returns 1 when descending sorted by id where scores and sortable names are the same and sorting by descending', () => {
    const score = 10
    studentA.assignment_201.score = score
    studentB.assignment_201.score = score
    const name = 'Same Name'
    studentA.sortable_name = name
    studentB.sortable_name = name
    const comparison = gradebook.gradeSort(studentA, studentB, 'assignment_201', false)
    expect(comparison).toBe(1)
  })
})
