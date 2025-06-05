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

describe('Gradebook#sortGridRows', () => {
  let gradebook

  beforeEach(() => {
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
    gradebook.gradebookGrid.updateColumns = jest.fn()
    gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders = jest.fn()
    gradebook.saveSettings = jest.fn().mockResolvedValue({})
  })

  afterEach(() => {
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
    expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledTimes(1)
  })
})

describe('Gradebook#getColumnSortSettingsViewOptionsMenuProps', () => {
  let gradebook
  let $fixtures
  let oldEnv

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
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
    gradebook.arrangeColumnsBy = jest.fn()
    gradebook.saveSettings = jest.fn().mockResolvedValue({})
  })

  afterEach(async () => {
    if (gradebook?.destroy) {
      gradebook.destroy()
    }
    $fixtures.remove()
    window.ENV = oldEnv
    // Wait a tick to let any pending promises settle
    await new Promise(resolve => setTimeout(resolve, 0))
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
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(...expectedArgs('name', 'ascending'))
  })

  test('sets onSortByNameDescending to a function that sorts columns by name descending', () => {
    getProps().onSortByNameDescending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(...expectedArgs('name', 'descending'))
  })

  test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', () => {
    getProps().onSortByDueDateAscending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(
      ...expectedArgs('due_date', 'ascending'),
    )
  })

  test('sets onSortByDueDateDescending to a function that sorts columns by due date descending', () => {
    getProps().onSortByDueDateDescending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(
      ...expectedArgs('due_date', 'descending'),
    )
  })

  test('sets onSortByPointsAscending to a function that sorts columns by points ascending', () => {
    getProps().onSortByPointsAscending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(...expectedArgs('points', 'ascending'))
  })

  test('sets onSortByPointsDescending to a function that sorts columns by points descending', () => {
    getProps().onSortByPointsDescending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(...expectedArgs('points', 'descending'))
  })

  test('sets onSortByModuleAscending to a function that sorts columns by module position ascending', () => {
    getProps().onSortByModuleAscending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(
      ...expectedArgs('module_position', 'ascending'),
    )
  })

  test('sets onSortByModuleDescending to a function that sorts columns by module position descending', () => {
    getProps().onSortByModuleDescending()
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledTimes(1)
    expect(gradebook.arrangeColumnsBy).toHaveBeenCalledWith(
      ...expectedArgs('module_position', 'descending'),
    )
  })
})

describe('when enhanced_gradebook_filters is enabled', () => {
  let gradebook
  let errorFn
  let successFn
  let $fixtures
  let oldEnv

  beforeEach(() => {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    setFixtureHtml($fixtures)
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

    errorFn = jest.fn()
    successFn = jest.fn()

    GradebookApi.saveUserSettings = jest.fn().mockResolvedValue({})
  })

  afterEach(() => {
    if (gradebook?.destroy) {
      gradebook.destroy()
    }
    $fixtures.remove()
    window.ENV = oldEnv
  })

  test('calls the provided successFn if the request succeeds', async () => {
    GradebookApi.saveUserSettings.mockResolvedValue({})
    await gradebook.saveSettings({}).then(successFn).catch(errorFn)
    expect(successFn).toHaveBeenCalledTimes(1)
    expect(errorFn).not.toHaveBeenCalled()
  })

  test('calls the provided errorFn if the request fails', async () => {
    GradebookApi.saveUserSettings.mockRejectedValue(new Error(':('))
    await gradebook.saveSettings({}).then(successFn).catch(errorFn)
    expect(errorFn).toHaveBeenCalledTimes(1)
    expect(successFn).not.toHaveBeenCalled()
  })

  test('just returns if the request succeeds and no successFn is provided', async () => {
    // QUnit.expect(0) is not needed in Jest
    GradebookApi.saveUserSettings.mockResolvedValue({})
    await gradebook.saveSettings({})
    // No assertions needed
  })

  test('throws an error if the request fails and no errorFn is provided', async () => {
    // QUnit.expect(1) is not needed in Jest
    GradebookApi.saveUserSettings.mockRejectedValue(new Error('>:('))

    await expect(gradebook.saveSettings({})).rejects.toThrow('>:(')
  })
})
