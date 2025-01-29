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
import ReactDOM from 'react-dom'

import {createGradebook, setFixtureHtml} from '../../../__tests__/GradebookSpecHelper'
import StudentColumnHeader from '../StudentColumnHeader'
import StudentColumnHeaderRenderer from '../StudentColumnHeaderRenderer'
import StudentLastNameColumnHeader from '../StudentLastNameColumnHeader'

describe('GradebookGrid StudentLastNameColumnHeaderRenderer', () => {
  let $container
  let gradebook
  let renderer

  function renderComponent() {
    renderer.render(
      {} /* column */,
      $container,
      {} /* gridSupport */,
      {
        ref(_ref) {},
      },
    )
  }

  beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS',
    })
    gradebook.saveSettings = jest.fn().mockResolvedValue()
    renderer = new StudentColumnHeaderRenderer(
      gradebook,
      StudentLastNameColumnHeader,
      'student_lastname',
    )
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  describe('#render()', () => {
    it('renders the StudentLastNameColumnHeader to the given container node', () => {
      renderComponent()
      expect($container.innerText).toContain('Student Last Name')
    })
  })

  describe('#destroy()', () => {
    it('unmounts the component', () => {
      renderComponent()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      expect(removed).toBe(false) // the component was already unmounted
    })
  })
})

describe('GradebookGrid StudentColumnHeaderRenderer', () => {
  let $container
  let gradebook
  let renderer
  let component

  function renderComponent() {
    renderer.render(
      {} /* column */,
      $container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      },
    )
  }

  beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS',
    })
    gradebook.saveSettings = jest.fn().mockResolvedValue()
    renderer = new StudentColumnHeaderRenderer(gradebook, StudentColumnHeader, 'student')
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  describe('#render()', () => {
    it('renders the StudentColumnHeader to the given container node', () => {
      renderComponent()
      expect($container.innerText).toContain('Student Name')
    })

    it('calls the "ref" callback option with the component reference', () => {
      renderComponent()
      expect(component.constructor.name).toBe('StudentColumnHeader')
    })

    it('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      gradebook.keyboardNav.addGradebookElement = jest.fn()
      renderComponent()
      component.props.addGradebookElement()
      expect(gradebook.keyboardNav.addGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('sets the component as disabled when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      renderComponent()
      expect(component.props.disabled).toBe(true)
    })

    it('sets the component as not disabled when students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      renderComponent()
      expect(component.props.disabled).toBe(false)
    })

    it('includes the login handle name from Gradebook', () => {
      renderComponent()
      expect(component.props.loginHandleName).toBe('a_jones')
    })

    it('includes a callback for keyDown events', () => {
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown({})
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledTimes(1)
    })

    it.skip('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      const exampleEvent = new Event('example')
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown(exampleEvent)
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledWith(exampleEvent)
    })

    it('calls Gradebook#handleHeaderKeyDown with the column id', () => {
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown({})
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledWith(expect.any(Object), 'student')
    })

    it('includes a callback for closing the column header menu', () => {
      jest.useFakeTimers()
      gradebook.handleColumnHeaderMenuClose = jest.fn()
      renderComponent()
      component.props.onMenuDismiss()
      jest.runAllTimers()
      expect(gradebook.handleColumnHeaderMenuClose).toHaveBeenCalledTimes(1)
      jest.useRealTimers()
    })

    it('does not call the menu close handler synchronously', () => {
      jest.useFakeTimers()
      gradebook.handleColumnHeaderMenuClose = jest.fn()
      renderComponent()
      component.props.onMenuDismiss()
      expect(gradebook.handleColumnHeaderMenuClose).not.toHaveBeenCalled()
      jest.runAllTimers()
      jest.useRealTimers()
    })

    it('includes a callback for selecting the primary info', () => {
      gradebook.setSelectedPrimaryInfo = jest.fn()
      renderComponent()
      component.props.onSelectPrimaryInfo()
      expect(gradebook.setSelectedPrimaryInfo).toHaveBeenCalledTimes(1)
    })

    it('includes a callback for selecting the secondary info', () => {
      gradebook.setSelectedSecondaryInfo = jest.fn()
      renderComponent()
      component.props.onSelectSecondaryInfo()
      expect(gradebook.setSelectedSecondaryInfo).toHaveBeenCalledTimes(1)
    })

    it('includes a callback for toggling the enrollment filter', () => {
      gradebook.toggleEnrollmentFilter = jest.fn()
      renderComponent()
      component.props.onToggleEnrollmentFilter()
      expect(gradebook.toggleEnrollmentFilter).toHaveBeenCalledTimes(1)
    })

    it('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      gradebook.keyboardNav.removeGradebookElement = jest.fn()
      renderComponent()
      component.props.removeGradebookElement()
      expect(gradebook.keyboardNav.removeGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('sets sectionsEnabled to false when sections are not in use', () => {
      renderComponent()
      expect(component.props.sectionsEnabled).toBe(false)
    })

    it('sets studentGroupsEnabled to true when student groups are present', () => {
      gradebook.setStudentGroups([
        {
          groups: [
            {id: '1', name: 'Default Group 1'},
            {id: '2', name: 'Default Group 2'},
          ],
          id: '1',
          name: 'Default Group',
        },
      ])
      renderComponent()
      expect(component.props.studentGroupsEnabled).toBe(true)
    })

    it('sets studentGroupsEnabled to false when student groups are not present', () => {
      renderComponent()
      expect(component.props.studentGroupsEnabled).toBe(false)
    })

    it('includes the selected enrollment filters', () => {
      gradebook.toggleEnrollmentFilter('concluded')
      renderComponent()
      expect(component.props.selectedEnrollmentFilters).toEqual(['concluded'])
    })

    it('includes the selected primary info setting', () => {
      renderComponent()
      expect(component.props.selectedPrimaryInfo).toBe('first_last')
    })

    it('includes the selected secondary info setting', () => {
      renderComponent()
      expect(component.props.selectedSecondaryInfo).toBe('none')
    })

    it('includes the SIS name', () => {
      renderComponent()
      expect(component.props.sisName).toBe('Example SIS')
    })

    it('includes the "Sort by" direction setting', () => {
      renderComponent()
      expect(component.props.sortBySetting.direction).toBe('ascending')
    })

    it('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to false when students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(false)
    })

    it('sets the "Sort by" isSortColumn setting to true when sorting by the student column', () => {
      renderComponent()
      expect(component.props.sortBySetting.isSortColumn).toBe(true)
    })

    it('sets the "Sort by" isSortColumn setting to false when not sorting by the student column', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      expect(component.props.sortBySetting.isSortColumn).toBe(false)
    })

    it('includes the onSortBySortableName callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortBySortableName()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortBySisId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortBySisId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sis_user_id',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortByIntegrationId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByIntegrationId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'integration_id',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortByLoginId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByLoginId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'login_id',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortInAscendingOrder callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'descending')
      renderComponent()
      component.props.sortBySetting.onSortInAscendingOrder()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortInDescendingOrder callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortInDescendingOrder()
      const expectedSetting = {
        columnId: 'student',
        direction: 'descending',
        settingKey: 'sortable_name',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortBySortableNameAscending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'descending')
      renderComponent()
      component.props.sortBySetting.onSortBySortableNameAscending()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortBySortableNameDescending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortBySortableNameDescending()
      const expectedSetting = {
        columnId: 'student',
        direction: 'descending',
        settingKey: 'sortable_name',
      }
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    describe('when not currently sorting by the student column', () => {
      it('defaults to the "sortable_name" key when "sort ascending" is selected', () => {
        gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'descending')
        renderComponent()
        component.props.sortBySetting.onSortInAscendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'ascending',
          settingKey: 'sortable_name',
        }
        expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
      })

      it('defaults to the "sortable_name" key when "sort descending" is selected', () => {
        gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
        renderComponent()
        component.props.sortBySetting.onSortInDescendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'descending',
          settingKey: 'sortable_name',
        }
        expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
      })
    })

    describe('when currently sorting by the student column', () => {
      it('preserves the existing sort key when "sort ascending" is selected', () => {
        gradebook.setSortRowsBySetting('student', 'integration_id', 'descending')
        renderComponent()
        component.props.sortBySetting.onSortInAscendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'ascending',
          settingKey: 'integration_id',
        }
        expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
      })

      it('preserves the existing sort key when "sort descending" is selected', () => {
        gradebook.setSortRowsBySetting('student', 'integration_id', 'ascending')
        renderComponent()
        component.props.sortBySetting.onSortInDescendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'descending',
          settingKey: 'integration_id',
        }
        expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
      })
    })

    it('includes the "Sort by" settingKey', () => {
      renderComponent()
      expect(component.props.sortBySetting.settingKey).toBe('sortable_name')
    })
  })

  describe('#destroy()', () => {
    it('unmounts the component', () => {
      renderComponent()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      expect(removed).toBe(false) // the component was already unmounted
    })
  })
})
