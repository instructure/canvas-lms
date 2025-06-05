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
    jest.spyOn(gradebook, 'arrangeColumnsBy').mockImplementation(() => {})
  })

  afterEach(() => {
    if (gradebook) {
      gradebook.destroy && gradebook.destroy()
    }
    $fixtures.remove()
    jest.restoreAllMocks()
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
