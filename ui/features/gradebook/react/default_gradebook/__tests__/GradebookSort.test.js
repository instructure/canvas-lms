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

import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import GradebookApi from '../apis/GradebookApi'
import AsyncComponents from '../AsyncComponents'
import sinon from 'sinon'

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
  let sandbox

  beforeEach(() => {
    gradebook = createGradebook()
    sandbox = sinon.createSandbox()
    sandbox
      .stub(gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    sandbox.stub(gradebook, 'gradeSort')
    sandbox.stub(gradebook, 'missingSort')
    sandbox.stub(gradebook, 'lateSort')
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    sandbox.restore()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    expect(gradebook.sortRowsBy.callCount).toBe(1)
  })

  test('sorts using gradeSort when the settingKey is "grade"', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    expect(gradebook.gradeSort.callCount).toBe(1)
  })

  test('sorts by grade using the columnId', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    const field = gradebook.gradeSort.getCall(0).args[2]
    expect(field).toBe('assignment_201')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })

  test('optionally sorts by missing in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'missing', 'ascending')
    const columnId = gradebook.missingSort.getCall(0).args[0]
    expect(columnId).toBe('assignment_201')
  })

  test('optionally sorts by late in ascending order', () => {
    gradebook.sortByAssignmentColumn('assignment_201', 'late', 'ascending')
    const columnId = gradebook.lateSort.getCall(0).args[0]
    expect(columnId).toBe('assignment_201')
  })
})

describe('sortByAssignmentGroupColumn', () => {
  let gradebook
  let sandbox

  beforeEach(() => {
    gradebook = createGradebook()
    sandbox = sinon.createSandbox()
    sandbox
      .stub(gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    sandbox.stub(gradebook, 'gradeSort')
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    sandbox.restore()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    expect(gradebook.sortRowsBy.callCount).toBe(1)
  })

  test('sorts by grade using gradeSort', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    expect(gradebook.gradeSort.callCount).toBe(1)
  })

  test('sorts by grade using the columnId', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    const field = gradebook.gradeSort.getCall(0).args[2]
    expect(field).toBe('assignment_group_301')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })
})

describe('sortByTotalGradeColumn', () => {
  let gradebook
  let sandbox

  beforeEach(() => {
    gradebook = createGradebook()
    sandbox = sinon.createSandbox()
    sandbox
      .stub(gradebook, 'sortRowsBy')
      .callsFake(sortFn => sortFn(gradebook.studentA, gradebook.studentB))
    sandbox.stub(gradebook, 'gradeSort')
    gradebook.studentA = {name: 'Adam Jones'}
    gradebook.studentB = {name: 'Betty Ford'}
  })

  afterEach(() => {
    sandbox.restore()
  })

  test('sorts the gradebook rows', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    expect(gradebook.sortRowsBy.callCount).toBe(1)
  })

  test('sorts by grade using gradeSort', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    expect(gradebook.gradeSort.callCount).toBe(1)
  })

  test('sorts by "total_grade"', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    const field = gradebook.gradeSort.getCall(0).args[2]
    expect(field).toBe('total_grade')
  })

  test('optionally sorts by grade in ascending order', () => {
    gradebook.sortByTotalGradeColumn('ascending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(true)
  })

  test('optionally sorts by grade in descending order', () => {
    gradebook.sortByTotalGradeColumn('descending')
    const [studentA, studentB, /* field */ , ascending] = gradebook.gradeSort.getCall(0).args
    expect(studentA).toBe(gradebook.studentA)
    expect(studentB).toBe(gradebook.studentB)
    expect(ascending).toBe(false)
  })
})

describe('Gradebook#sortGridRows', () => {
  let gradebook
  let sandbox

  beforeEach(() => {
    sandbox = sinon.createSandbox()
    window.ENV = {
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
        grading_schemes: [],
        settings_update_url: '/courses/1/gradebook_settings',
      },
      FEATURES: {instui_nav: false},
    }
    gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z', total_grade: {score: 15}, assignment_2301: {score: 10}},
      {id: '4', sortable_name: 'A', total_grade: {score: 10}, assignment_2301: {score: 15}},
    ]
    gradebook.setAssignments({
      2301: {
        id: '2301',
        grading_type: 'points',
        name: 'Assignment 1',
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    gradebook.gridDisplaySettings.viewUngradedAsZero = false
    sandbox.stub(gradebook.gradebookGrid, 'updateColumns')
    sandbox.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
  })

  afterEach(() => {
    sandbox.restore()
    window.ENV = undefined
  })

  test('uses the saved sort setting for student column sorting', () => {
    gradebook.setSortRowsBySetting('student_name', 'ascending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  test.skip('optionally sorts by a custom column', () => {
    gradebook.setSortRowsBySetting('custom_col_2301', 'ascending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  test('uses the saved sort setting for custom column sorting', () => {
    gradebook.setSortRowsBySetting('custom_col_2301', 'descending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test('optionally sorts by an assignment column', () => {
    gradebook.setSortRowsBySetting('assignment_2301', 'ascending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test.skip('uses the saved sort setting for assignment sorting', () => {
    gradebook.setSortRowsBySetting('assignment_2301', 'descending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  test.skip('optionally sorts by the total grade column', () => {
    gradebook.setSortRowsBySetting('total_grade', 'ascending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('4')
    expect(secondRow.id).toBe('3')
  })

  test('uses the saved sort setting for total grade sorting', () => {
    gradebook.setSortRowsBySetting('total_grade', 'descending')
    gradebook.sortGridRows()
    const [firstRow, secondRow] = gradebook.gridData.rows
    expect(firstRow.id).toBe('3')
    expect(secondRow.id).toBe('4')
  })

  test('updates the column headers after sorting', () => {
    gradebook.sortGridRows()
    expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount).toBe(1)
  })
})

describe('Gradebook#getColumnSortSettingsViewOptionsMenuProps', () => {
  let gradebook
  let sandbox
  let $fixtures
  let oldEnv

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
    sandbox = sinon.createSandbox()
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: true},
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
      },
    }
    gradebook = createGradebook()
    sandbox.stub(gradebook, 'arrangeColumnsBy')
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    sandbox.restore()
    window.ENV = oldEnv
  })

  function getProps(sortType = 'due_date', direction = 'ascending') {
    gradebook.setColumnOrder({sortType, direction})
    return gradebook.getColumnSortSettingsViewOptionsMenuProps()
  }

  function expectedArgs(sortType, direction) {
    return [{sortType, direction}, false]
  }

  test('includes all required properties', () => {
    const props = getProps()

    expect(typeof props.criterion).toBe('string') // props include "criterion"
    expect(typeof props.direction).toBe('string') // props include "direction"
    expect(typeof props.disabled).toBe('boolean') // props include "disabled"
    expect(typeof props.onSortByDefault).toBe('function') // props include "onSortByDefault"
    expect(typeof props.onSortByNameAscending).toBe('function') // props include "onSortByNameAscending"
    expect(typeof props.onSortByNameDescending).toBe('function') // props include "onSortByNameDescending"
    expect(typeof props.onSortByDueDateAscending).toBe('function') // props include "onSortByDueDateAscending"
    expect(typeof props.onSortByDueDateDescending).toBe('function') // props include "onSortByDueDateDescending"
    expect(typeof props.onSortByPointsAscending).toBe('function') // props include "onSortByPointsAscending"
    expect(typeof props.onSortByPointsDescending).toBe('function') // props include "onSortByPointsDescending"
  })

  test('sets criterion to the sort field', () => {
    expect(getProps().criterion).toBe('due_date')
    expect(getProps('name').criterion).toBe('name')
  })

  test('sets criterion to "default" when isDefaultSortOrder returns true', () => {
    expect(getProps('assignment_group').criterion).toBe('default')
  })

  test('sets the direction', () => {
    expect(getProps(undefined, 'ascending').direction).toBe('ascending')
    expect(getProps(undefined, 'descending').direction).toBe('descending')
  })

  test('sets disabled to true when assignments have not been loaded yet', () => {
    expect(getProps().disabled).toBe(true)
  })

  test('sets disabled to false when assignments have been loaded', () => {
    gradebook.setAssignmentsLoaded()
    expect(getProps().disabled).toBe(false)
  })

  test('sets modulesEnabled to true when there are modules in the current course', () => {
    gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
    expect(getProps().modulesEnabled).toBe(true)
  })

  test('sets modulesEnabled to false when there are no modules in the current course', () => {
    gradebook.setContextModules([])
    expect(getProps().modulesEnabled).toBe(false)
  })

  test('sets onSortByNameAscending to a function that sorts columns by name ascending', () => {
    getProps().onSortByNameAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('name', 'ascending'))
  })

  test('sets onSortByNameDescending to a function that sorts columns by name descending', () => {
    getProps().onSortByNameDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('name', 'descending'))
  })

  test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', () => {
    getProps().onSortByDueDateAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('due_date', 'ascending'))
  })

  test('sets onSortByDueDateDescending to a function that sorts columns by due date descending', () => {
    getProps().onSortByDueDateDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('due_date', 'descending'),
    )
  })

  test('sets onSortByPointsAscending to a function that sorts columns by points ascending', () => {
    getProps().onSortByPointsAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('points', 'ascending'))
  })

  test('sets onSortByPointsDescending to a function that sorts columns by points descending', () => {
    getProps().onSortByPointsDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('points', 'descending'))
  })

  test('sets onSortByModuleAscending to a function that sorts columns by module position ascending', () => {
    getProps().onSortByModuleAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('module_position', 'ascending'),
    )
  })

  test('sets onSortByModuleDescending to a function that sorts columns by module position descending', () => {
    getProps().onSortByModuleDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('module_position', 'descending'),
    )
  })
})

describe('when enhanced_gradebook_filters is enabled', () => {
  let gradebook
  let errorFn
  let successFn
  let saveUserSettingsStub
  let sandbox
  let $fixtures
  let oldEnv

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
    sandbox = sinon.createSandbox()
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: true},
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
        grading_schemes: [],
      },
    }
    gradebook = createGradebook({
      enhanced_gradebook_filters: true,
    })
    const assignment = {
      id: '2301',
      grading_type: 'points',
      name: 'Assignment 1',
      published: true,
      submission_types: ['online_text_entry'],
    }
    gradebook.setAssignments({2301: assignment})
    gradebook.setAssignmentsLoaded()

    errorFn = sandbox.stub()
    successFn = sandbox.stub()

    saveUserSettingsStub = sandbox.stub(GradebookApi, 'saveUserSettings')
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    saveUserSettingsStub.restore()
    sandbox.restore()
    window.ENV = oldEnv
  })

  test('calls the provided successFn if the request succeeds', async () => {
    saveUserSettingsStub.resolves({})
    await gradebook.saveSettings({}).then(successFn).catch(errorFn)
    expect(successFn.callCount).toBe(1)
    expect(errorFn.notCalled).toBeTruthy()
  })

  test('calls the provided errorFn if the request fails', async () => {
    saveUserSettingsStub.rejects(new Error(':('))
    await gradebook.saveSettings({}).then(successFn).catch(errorFn)
    expect(errorFn.callCount).toBe(1)
    expect(successFn.notCalled).toBeTruthy()
  })

  test('just returns if the request succeeds and no successFn is provided', async () => {
    // QUnit.expect(0) is not needed in Jest
    saveUserSettingsStub.resolves({})
    await gradebook.saveSettings({})
    // No assertions needed
  })

  test('throws an error if the request fails and no errorFn is provided', async () => {
    // QUnit.expect(1) is not needed in Jest
    saveUserSettingsStub.rejects(new Error('>:('))

    await expect(gradebook.saveSettings({})).rejects.toThrow('>:(')
  })
})

describe('#renderGradebookSettingsModal', () => {
  let gradebook
  let sandbox
  let $fixtures
  let oldEnv

  function gradebookSettingsModalProps() {
    return AsyncComponents.renderGradebookSettingsModal.lastCall.args[0]
  }

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
    sandbox = sinon.createSandbox()
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: true},
      current_user_id: '1',
      context_id: '1',
    }
    sandbox.stub(AsyncComponents, 'renderGradebookSettingsModal')
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    sandbox.restore()
    window.ENV = oldEnv
  })

  test('renders the GradebookSettingsModal component', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(AsyncComponents.renderGradebookSettingsModal.callCount).toBe(1)
  })

  test('sets the .courseFeatures prop to #courseFeatures from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseFeatures).toBe(gradebook.courseFeatures)
  })

  test('sets the .courseSettings prop to #courseSettings from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseSettings).toBe(gradebook.courseSettings)
  })

  test('passes graded_late_submissions_exist option to the modal as a prop', () => {
    gradebook = createGradebook({graded_late_submissions_exist: true})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().gradedLateSubmissionsExist).toBe(true)
  })

  test('passes the context_id option to the modal as a prop', () => {
    gradebook = createGradebook({context_id: '8473'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseId).toBe('8473')
  })

  test('passes the locale option to the modal as a prop', () => {
    gradebook = createGradebook({locale: 'de'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().locale).toBe('de')
  })

  test('passes the postPolicies object as the prop of the same name', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().postPolicies).toBe(gradebook.postPolicies)
  })

  describe('.onCourseSettingsUpdated prop', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      sandbox.stub(gradebook.courseSettings, 'handleUpdated')
      const oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterEach(() => {
      window.ENV = oldEnv
      gradebook.courseSettings.handleUpdated.restore()
    })

    test('updates the course settings when called', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      expect(gradebook.courseSettings.handleUpdated.callCount).toBe(1)
    })

    test('updates the course settings using the given course settings data', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      const [givenSettings] = gradebook.courseSettings.handleUpdated.lastCall.args
      expect(givenSettings).toBe(settings)
    })
  })

  describe('anonymousAssignmentsPresent prop', () => {
    const anonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: true,
          assignment_group_id: '10001',
          id: '101',
          name: 'Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10001',
      name: 'An anonymous assignment group',
    }

    const nonAnonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: false,
          assignment_group_id: '10002',
          id: '102',
          name: 'Not-Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10002',
      name: 'An anonymous assignment group',
    }

    test('is passed as true if the course has at least one anonymous assignment', () => {
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([anonymousAssignmentGroup, nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(true)
    })

    test('is passed as false if the course has no anonymous assignments', () => {
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(false)
    })
  })

  describe('when enhanced gradebook filters are enabled', () => {
    test('sets allowSortingByModules to true if modules are enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(true)
    })

    test('sets allowSortingByModules to false if modules are not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(false)
    })

    test('sets allowViewUngradedAsZero to true if view ungraded as zero is enabled', () => {
      gradebook = createGradebook({
        allow_view_ungraded_as_zero: true,
        enhanced_gradebook_filters: true,
      })
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(true)
    })

    test('sets allowViewUngradedAsZero to false if view ungraded as zero is not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(false)
    })

    describe.skip('loadCurrentViewOptions prop', () => {
      const viewOptions = () => gradebookSettingsModalProps().loadCurrentViewOptions()

      test('sets columnSortSettings to the current sort criterion and direction', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.setColumnOrder({sortType: 'due_date', direction: 'descending'})
        gradebook.renderGradebookSettingsModal()

        expect(viewOptions().columnSortSettings).toEqual({
          criterion: 'due_date',
          direction: 'descending',
        })
      })

      test('sets showNotes to true if the notes column is shown', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: false,
          },
        })
        gradebook.renderGradebookSettingsModal()

        expect(gradebookSettingsModalProps().showNotes).toBe(true)
      })

      test('sets showNotes to false if the notes column is hidden', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: true,
          },
        })
        gradebook.renderGradebookSettingsModal()

        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test('sets showNotes to false if the notes column does not exist', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test('sets showUnpublishedAssignments to true if unpublished assignments are shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(true)
      })

      test('sets showUnpublishedAssignments to false if unpublished assignments are not shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('not true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(false)
      })

      test('sets viewUngradedAsZero to true if view ungraded as 0 is active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = true
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(true)
      })

      test('sets viewUngradedAsZero to false if view ungraded as 0 is not active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = false
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(false)
      })
    })
  })
})

describe.skip('when enhanced gradebook filters are not enabled', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  test('does not set allowSortingByModules', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().allowSortingByModules).toBeUndefined()
  })

  test('does not set allowViewUngradedAsZero', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBeUndefined()
  })

  test('does not set loadCurrentViewOptions', () => {
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().loadCurrentViewOptions).toBeUndefined()
  })
})

describe('Gradebook "Enter Grades as" Setting', () => {
  let gradebook
  let sandbox
  let updateGridStub

  beforeEach(() => {
    sandbox = sinon.createSandbox()
    window.ENV = {
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
        grading_schemes: [],
        settings_update_url: '/courses/1/gradebook_settings',
      },
      FEATURES: {instui_nav: false},
    }
    gradebook = createGradebook()
    gradebook.setAssignments({
      2301: {
        id: '2301',
        grading_type: 'points',
        name: 'Assignment 1',
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    updateGridStub = sandbox.stub(gradebook.gradebookGrid, 'updateColumns')
  })

  afterEach(() => {
    sandbox.restore()
    window.ENV = undefined
  })

  test.skip('calls updateGrid if a corresponding column is found', () => {
    gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2301', isOpen: true})
    expect(updateGridStub.callCount).toBe(1)
  })
})

describe('Gradebook#getColumnSortSettingsViewOptionsMenuProps', () => {
  let gradebook
  let sandbox
  let $fixtures
  let oldEnv

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
    sandbox = sinon.createSandbox()
    oldEnv = window.ENV
    window.ENV = {
      FEATURES: {instui_nav: true},
      current_user_id: '1',
      context_id: '1',
      GRADEBOOK_OPTIONS: {
        custom_columns: [],
      },
    }
    gradebook = createGradebook()
    sandbox.stub(gradebook, 'arrangeColumnsBy')
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    sandbox.restore()
    window.ENV = oldEnv
  })

  function getProps(sortType = 'due_date', direction = 'ascending') {
    gradebook.setColumnOrder({sortType, direction})
    return gradebook.getColumnSortSettingsViewOptionsMenuProps()
  }

  function expectedArgs(sortType, direction) {
    return [{sortType, direction}, false]
  }

  test('includes all required properties', () => {
    const props = getProps()

    expect(typeof props.criterion).toBe('string') // props include "criterion"
    expect(typeof props.direction).toBe('string') // props include "direction"
    expect(typeof props.disabled).toBe('boolean') // props include "disabled"
    expect(typeof props.onSortByDefault).toBe('function') // props include "onSortByDefault"
    expect(typeof props.onSortByNameAscending).toBe('function') // props include "onSortByNameAscending"
    expect(typeof props.onSortByNameDescending).toBe('function') // props include "onSortByNameDescending"
    expect(typeof props.onSortByDueDateAscending).toBe('function') // props include "onSortByDueDateAscending"
    expect(typeof props.onSortByDueDateDescending).toBe('function') // props include "onSortByDueDateDescending"
    expect(typeof props.onSortByPointsAscending).toBe('function') // props include "onSortByPointsAscending"
    expect(typeof props.onSortByPointsDescending).toBe('function') // props include "onSortByPointsDescending"
  })

  test('sets criterion to the sort field', () => {
    expect(getProps().criterion).toBe('due_date')
    expect(getProps('name').criterion).toBe('name')
  })

  test('sets criterion to "default" when isDefaultSortOrder returns true', () => {
    expect(getProps('assignment_group').criterion).toBe('default')
  })

  test('sets the direction', () => {
    expect(getProps(undefined, 'ascending').direction).toBe('ascending')
    expect(getProps(undefined, 'descending').direction).toBe('descending')
  })

  test('sets disabled to true when assignments have not been loaded yet', () => {
    expect(getProps().disabled).toBe(true)
  })

  test('sets disabled to false when assignments have been loaded', () => {
    gradebook.setAssignmentsLoaded()
    expect(getProps().disabled).toBe(false)
  })

  test('sets modulesEnabled to true when there are modules in the current course', () => {
    gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
    expect(getProps().modulesEnabled).toBe(true)
  })

  test('sets modulesEnabled to false when there are no modules in the current course', () => {
    gradebook.setContextModules([])
    expect(getProps().modulesEnabled).toBe(false)
  })

  test('sets onSortByNameAscending to a function that sorts columns by name ascending', () => {
    getProps().onSortByNameAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('name', 'ascending'))
  })

  test('sets onSortByNameDescending to a function that sorts columns by name descending', () => {
    getProps().onSortByNameDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('name', 'descending'))
  })

  test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', () => {
    getProps().onSortByDueDateAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('due_date', 'ascending'))
  })

  test('sets onSortByDueDateDescending to a function that sorts columns by due date descending', () => {
    getProps().onSortByDueDateDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('due_date', 'descending'),
    )
  })

  test('sets onSortByPointsAscending to a function that sorts columns by points ascending', () => {
    getProps().onSortByPointsAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('points', 'ascending'))
  })

  test('sets onSortByPointsDescending to a function that sorts columns by points descending', () => {
    getProps().onSortByPointsDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(expectedArgs('points', 'descending'))
  })

  test('sets onSortByModuleAscending to a function that sorts columns by module position ascending', () => {
    getProps().onSortByModuleAscending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('module_position', 'ascending'),
    )
  })

  test('sets onSortByModuleDescending to a function that sorts columns by module position descending', () => {
    getProps().onSortByModuleDescending()
    expect(gradebook.arrangeColumnsBy.callCount).toBe(1)
    expect(gradebook.arrangeColumnsBy.firstCall.args).toEqual(
      expectedArgs('module_position', 'descending'),
    )
  })
})

function gradebookSettingsModalProps() {
  return {
    anonymousSpeedGraderAlertNode: document.createElement('div'),
    colors: {
      dropped: '#FEF0E5',
      excused: '#FEF7E5',
      extended: '#E5F3FC',
      late: '#E5F3FC',
      missing: '#FFE8E5',
      resubmitted: '#E5F3FC',
    },
    courseId: '1',
    courseFeatures: {
      finalGradeOverrideEnabled: false,
      allowViewUngradedAsZero: true,
    },
    locale: 'en',
    gradingSchemeEnabled: true,
    gradingSchemes: [],
    hideAssignmentGroupTotals: false,
    hideTotal: false,
    latePoliciesEnabled: true,
    loadCurrentGradingScheme: () => {},
    loadGradingSchemes: () => {},
    loadLatePolicies: () => {},
    loadStudentSettings: () => {},
    modules: [],
    onClose: () => {},
    saveCurrentGradingScheme: () => {},
    saveGradingScheme: () => {},
    saveLatePolicies: () => {},
    saveSettings: () => {},
    settings: {
      allowViewUngradedAsZero: false,
      showSeparateFirstLastNames: true,
      showUnpublishedAssignments: true,
      statusColors: {
        dropped: '#FEF0E5',
        excused: '#FEF7E5',
        extended: '#E5F3FC',
        late: '#E5F3FC',
        missing: '#FFE8E5',
        resubmitted: '#E5F3FC',
      },
      viewUngradedAsZero: false,
    },
    studentSettings: {
      allowViewUngradedAsZero: false,
      viewUngradedAsZero: false,
    },
  }
}
