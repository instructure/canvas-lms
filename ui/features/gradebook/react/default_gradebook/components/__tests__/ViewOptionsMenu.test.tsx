/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import ViewOptionsMenu from '../ViewOptionsMenu'

function defaultProps({props = {}, filterSettings = {}} = {}) {
  return {
    columnSortSettings: {
      criterion: 'due_date',
      direction: 'ascending',
      disabled: false,
      modulesEnabled: true,
      onSortByDefault() {},
      onSortByDueDateAscending() {},
      onSortByDueDateDescending() {},
      onSortByNameAscending() {},
      onSortByNameDescending() {},
      onSortByPointsAscending() {},
      onSortByPointsDescending() {},
      onSortByModuleAscending() {},
      onSortByModuleDescending() {},
    },
    filterSettings: {
      available: ['assignmentGroups', 'gradingPeriods', 'modules', 'sections'],
      onSelect() {},
      selected: [],
      ...filterSettings,
    },
    onSelectShowStatusesModal() {},
    onSelectShowUnpublishedAssignments() {},
    onSelectShowSeparateFirstLastNames() {},
    onSelectViewUngradedAsZero() {},
    showUnpublishedAssignments: false,
    allowShowSeparateFirstLastNames: true,
    showSeparateFirstLastNames: false,
    viewUngradedAsZero: false,
    allowViewUngradedAsZero: false,
    finalGradeOverrideEnabled: false,
    teacherNotes: {
      disabled: false,
      onSelect() {},
      selected: true,
    },
    overrides: {
      disabled: false,
      label: 'Overrides',
      onSelect() {},
      selected: false,
    },
    ...props,
  }
}

function mouseover($el: any) {
  const event = new MouseEvent('mouseover', {
    bubbles: true,
    cancelable: true,
    view: window,
  })
  $el.dispatchEvent(event)
}

function getMenuItemWithLabel($parent: Element, label: any) {
  const $children = Array.from(($parent as Element)?.querySelectorAll('[role^="menuitem"]') ?? [])
  return $children.find($child => $child.textContent?.trim() === label)
}

function getFlyoutWithLabel($parent: Element, label: any) {
  const $children = Array.from($parent.querySelectorAll('[role="button"]'))
  return $children.find($child => $child.textContent?.trim() === label)
}

function getSubmenu($menuItem: Element) {
  return document.querySelector(`[aria-labelledby="${$menuItem.id}"]`)
}

function getMenuItem($menu: Element, ...path: any[]) {
  return path.reduce(($el, label, index) => {
    if (index < path.length - 1) {
      const $next = getFlyoutWithLabel($el, label)
      mouseover($next)
      if (!$next) return
      return getSubmenu($next)
    }

    return getMenuItemWithLabel($el, label) || getFlyoutWithLabel($el, label)
  }, $menu)
}

function mountAndOpenOptions() {
  wrapper = render(<ViewOptionsMenu {...props} ref={ref} />)
  fireEvent.click(wrapper.container.querySelector('button')!)
  return wrapper
}

let props: any, wrapper, ref: any

describe('ViewOptionsMenu', () => {
  beforeEach(() => {
    props = defaultProps()
    ref = React.createRef()
  })

  describe('ViewOptionsMenu#focus', () => {
    test('trigger is focused', () => {
      wrapper = render(<ViewOptionsMenu {...props} ref={ref} />)
      ref.current.focus()
      expect(document.activeElement).toBe(wrapper.container.querySelector('button'))
    })
  })

  describe('ViewOptionsMenu - notes', () => {
    test('teacher notes are optionally enabled', function () {
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Notes')
      expect(menuItem.getAttribute('aria-disabled')).toEqual(null)
    })

    test('teacher notes are optionally disabled', function () {
      props.teacherNotes.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Notes')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('triggers the onSelect when the "Notes" option is clicked', function () {
      const spy = jest.spyOn(props.teacherNotes, 'onSelect')
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Notes'))
      expect(spy).toHaveBeenCalledTimes(1)
    })

    test('the "Notes" option is optionally selected', function () {
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Notes')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('the "Notes" option is optionally deselected', function () {
      props.teacherNotes.selected = false
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Notes')
      expect(menuItem.getAttribute('aria-checked')).toEqual('false')
    })
  })

  describe('ViewOptionsMenu - Overrides', () => {
    test('is hidden by default', () => {
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Overrides')
      expect(menuItem).toBe(undefined)
    })
  })

  describe('ViewOptionsMenu - Filters', () => {
    test('includes each available filter', function () {
      wrapper = mountAndOpenOptions()
      const filters = ['Assignment Groups', 'Grading Periods', 'Modules', 'Sections']
      filters.forEach(label => {
        expect(getMenuItem(ref.current.menuContent, 'Filters', label)).toBeInTheDocument()
      })
    })

    test('includes only available filters', function () {
      props.filterSettings.available = ['gradingPeriods', 'modules']
      wrapper = mountAndOpenOptions()
      const filters = ['Assignment Groups', 'Sections']
      filters.forEach(label => {
        expect(getMenuItem(ref.current.menuContent, 'Filters', label)).toBe(undefined)
      })
    })

    test('does not display filters group when no filters are available', function () {
      props.filterSettings.available = []
      wrapper = mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'Filters')).toBe(undefined)
    })

    test('onSelect is called when a filter is selected', function () {
      props.filterSettings.onSelect = jest.fn()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Filters', 'Grading Periods'))
      expect(props.filterSettings.onSelect).toHaveBeenCalledTimes(1)
      expect(props.filterSettings.onSelect).toHaveBeenCalledWith(['gradingPeriods'])
    })

    test('onSelect is called with list of selected filters upon any selection change', function () {
      props.filterSettings.onSelect = jest.fn()
      props.filterSettings.selected = ['assignmentGroups', 'sections']
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Filters', 'Grading Periods'))
      expect(props.filterSettings.onSelect).toHaveBeenCalledWith([
        'assignmentGroups',
        'sections',
        'gradingPeriods',
      ])
    })
  })

  describe('ViewOptionsMenu - view ungraded as 0', () => {
    beforeEach(() => {
      props.viewUngradedAsZero = false
      props.allowViewUngradedAsZero = false
      props.onSelectViewUngradedAsZero = () => {}
    })

    test('"View Ungraded As 0" is shown when allowViewUngradedAsZero is true', function () {
      props.allowViewUngradedAsZero = true
      wrapper = mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'View Ungraded as 0')).toBeInTheDocument()
    })

    test('"View Ungraded As 0" is not shown when allowViewUngradedAsZero is false', function () {
      props.allowViewUngradedAsZero = false
      wrapper = mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'View Ungraded as 0')).toBe(undefined)
    })

    test('"View Ungraded As 0" is selected when viewUngradedAsZero is true', function () {
      props.viewUngradedAsZero = true
      props.allowViewUngradedAsZero = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'View Ungraded as 0')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('"View Ungraded As 0" is not selected when viewUngradedAsZero is false', function () {
      props.viewUngradedAsZero = false
      props.allowViewUngradedAsZero = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'View Ungraded as 0')
      expect(menuItem.getAttribute('aria-checked')).toEqual('false')
    })

    test('onSelectViewUngradedAsZero is called when selected', function () {
      props.viewUngradedAsZero = false
      props.allowViewUngradedAsZero = true
      props.onSelectViewUngradedAsZero = jest.fn()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'View Ungraded as 0'))
      expect(props.onSelectViewUngradedAsZero).toHaveBeenCalledTimes(1)
    })
  })

  describe('ViewOptionsMenu - unpublished assignments', () => {
    beforeEach(() => {
      props.showUnpublishedAssignments = true
      props.onSelectShowUnpublishedAssignments = () => {}
    })

    test('Unpublished Assignments is selected when showUnpublishedAssignments is true', function () {
      props.showUnpublishedAssignments = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Unpublished Assignments')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Unpublished Assignments is not selected when showUnpublishedAssignments is false', function () {
      props.showUnpublishedAssignments = false
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Unpublished Assignments')
      expect(menuItem.getAttribute('aria-checked')).toEqual('false')
    })

    test('onSelectShowUnpublishedAssignment is called when selected', function () {
      props.onSelectShowUnpublishedAssignments = jest.fn()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Unpublished Assignments'))
      expect(props.onSelectShowUnpublishedAssignments).toHaveBeenCalledTimes(1)
    })
  })

  describe('ViewOptionsMenu - show student last and first names separately', () => {
    beforeEach(() => {
      props.showSeparateFirstLastNames = true
      props.allowShowSeparateFirstLastNames = true
    })

    test('Split student names is not show shown when allowShowSeparateFirstLastNames is false', function () {
      props.allowShowSeparateFirstLastNames = false
      mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'Split Student Names')).toBe(undefined)
    })

    test('Split student names is selected when showSeparateFirstLastNames is true', function () {
      props.showSeparateFirstLastNames = true
      mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Split Student Names')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Split student names is unselected when showSeparateFirstLastNames is false', function () {
      props.showSeparateFirstLastNames = false
      mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Split Student Names')
      expect(menuItem.getAttribute('aria-checked')).toEqual('false')
    })
  })

  describe('ViewOptionsMenu - Column Sorting', () => {
    function sortingProps(
      criterion = 'due_date',
      direction = 'ascending',
      disabled = false,
      modulesEnabled = true
    ) {
      return {
        ...defaultProps(),
        columnSortSettings: {
          criterion,
          direction,
          disabled,
          modulesEnabled,
          onSortByDefault: jest.fn(),
          onSortByNameAscending: jest.fn(),
          onSortByNameDescending: jest.fn(),
          onSortByDueDateAscending: jest.fn(),
          onSortByDueDateDescending: jest.fn(),
          onSortByPointsAscending: jest.fn(),
          onSortByPointsDescending: jest.fn(),
          onSortByModuleAscending: jest.fn(),
          onSortByModuleDescending: jest.fn(),
        },
      }
    }

    test('Default Order is selected when criterion is default and direction is ascending', function () {
      props = sortingProps('default', 'ascending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Default Order')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Default Order is selected when criterion is default and direction is descending', function () {
      props = sortingProps('default', 'descending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Default Order')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Assignment Name - A-Z is selected when criterion is name and direction is ascending', function () {
      props = sortingProps('name', 'ascending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - A-Z')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Assignment Name - Z-A is selected when criterion is name and direction is ascending', function () {
      props = sortingProps('name', 'descending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - Z-A')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Due Date - Oldest to Newest is selected when criterion is due_date and direction is ascending', function () {
      props = sortingProps('due_date', 'ascending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Due Date - Oldest to Newest'
      )
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Due Date - Newest to Oldest is selected when criterion is due_date and direction is descending', function () {
      props = sortingProps('due_date', 'descending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Due Date - Newest to Oldest'
      )
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Points - Lowest to Highest is selected when criterion is points and direction is ascending', function () {
      props = sortingProps('points', 'ascending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Points - Lowest to Highest'
      )
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Points - Highest to Lowest is selected when criterion is points and direction is descending', function () {
      props = sortingProps('points', 'descending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Points - Highest to Lowest'
      )
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Module - First to Last is selected when criterion is module_position and direction is ascending', function () {
      props = sortingProps('module_position', 'ascending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - First to Last')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Module - Last to First is selected when criterion is module_position and direction is ascending', function () {
      props = sortingProps('module_position', 'descending')
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - Last to First')
      expect(menuItem.getAttribute('aria-checked')).toEqual('true')
    })

    test('Module - First to Last is not shown when modules are not enabled', function () {
      props = sortingProps('default', 'ascending', false, false)
      wrapper = mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - First to Last')).toBe(
        undefined
      )
    })

    test('Module - Last to First is not shown when modules are not enabled', function () {
      props = sortingProps('default', 'ascending', false, false)
      wrapper = mountAndOpenOptions()
      expect(getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - Last to First')).toBe(
        undefined
      )
    })

    test('Default Order is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Default Order')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Assignment Name - A-Z is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - A-Z')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Assignment Name - Z-A is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - Z-A')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Due Date - Oldest to Newest is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Due Date - Oldest to Newest'
      )
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Due Date - Newest to Oldest is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Due Date - Newest to Oldest'
      )
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Points - Lowest to Highest is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Points - Lowest to Highest'
      )
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Points - Highest to Lowest is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(
        ref.current.menuContent,
        'Arrange By',
        'Points - Highest to Lowest'
      )
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Module - First to Last is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - First to Last')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('Module - Last to First is disabled when column ordering settings are disabled', function () {
      props = sortingProps()
      props.columnSortSettings.disabled = true
      wrapper = mountAndOpenOptions()
      const menuItem = getMenuItem(ref.current.menuContent, 'Arrange By', 'Module - Last to First')
      expect(menuItem.getAttribute('aria-disabled')).toEqual('true')
    })

    test('clicking on "Default Order" triggers onSortByDefault', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Arrange By', 'Default Order'))
      expect(props.columnSortSettings.onSortByDefault).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Assignments - A-Z" triggers onSortByNameAscending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - A-Z'))
      expect(props.columnSortSettings.onSortByNameAscending).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Assignments - Z-A" triggers onSortByNameDescending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Arrange By', 'Assignment Name - Z-A'))
      expect(props.columnSortSettings.onSortByNameDescending).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Due Date - Oldest to Newest" triggers onSortByDueDateAscending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(
        getMenuItem(ref.current.menuContent, 'Arrange By', 'Due Date - Oldest to Newest')
      )
      expect(props.columnSortSettings.onSortByDueDateAscending).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Due Date - Newest to Oldest" triggers onSortByDueDateDescending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(
        getMenuItem(ref.current.menuContent, 'Arrange By', 'Due Date - Newest to Oldest')
      )
      expect(props.columnSortSettings.onSortByDueDateDescending).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Points - Lowest to Highest" triggers onSortByPointsAscending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(
        getMenuItem(ref.current.menuContent, 'Arrange By', 'Points - Lowest to Highest')
      )
      expect(props.columnSortSettings.onSortByPointsAscending).toHaveBeenCalledTimes(1)
    })

    test('clicking on "Points - Highest to Lowest" triggers onSortByPointsDescending', function () {
      props = sortingProps()
      wrapper = mountAndOpenOptions()
      fireEvent.click(
        getMenuItem(ref.current.menuContent, 'Arrange By', 'Points - Highest to Lowest')
      )
      expect(props.columnSortSettings.onSortByPointsDescending).toHaveBeenCalledTimes(1)
    })
  })

  describe('ViewOptionsMenu - Statuses', () => {
    test('clicking Statuses calls onSelectShowStatusesModal', () => {
      props.onSelectShowStatusesModal = jest.fn()
      wrapper = mountAndOpenOptions()
      fireEvent.click(getMenuItem(ref.current.menuContent, 'Statuses…'))
      expect(props.onSelectShowStatusesModal).toHaveBeenCalledTimes(1)
    })
  })
})
