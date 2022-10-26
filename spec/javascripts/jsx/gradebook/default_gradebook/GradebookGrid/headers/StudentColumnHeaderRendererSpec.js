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

import ReactDOM from 'react-dom'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import StudentColumnHeader from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentColumnHeader'
import StudentColumnHeaderRenderer from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentColumnHeaderRenderer'
import StudentLastNameColumnHeader from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentLastNameColumnHeader'

QUnit.module('GradebookGrid StudentLastNameColumnHeaderRenderer', suiteHooks => {
  let $container
  let gradebook
  let renderer

  function render() {
    renderer.render(
      {} /* column */,
      $container,
      {} /* gridSupport */,
      {
        ref(_ref) {},
      }
    )
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS',
    })
    sinon
      .stub(gradebook, 'saveSettings')
      .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
    renderer = new StudentColumnHeaderRenderer(
      gradebook,
      StudentLastNameColumnHeader,
      'student_lastname'
    )
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('renders the StudentLastNameColumnHeader to the given container node', () => {
      render()
      ok(
        $container.innerText.includes('Student Last Name'),
        'the "Student Last Name" header is rendered'
      )
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the component', () => {
      render()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      strictEqual(removed, false, 'the component was already unmounted')
    })
  })
})

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid StudentColumnHeaderRenderer', suiteHooks => {
  let $container
  let gradebook
  let renderer
  let component

  function render() {
    renderer.render(
      {} /* column */,
      $container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      }
    )
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS',
    })
    sinon
      .stub(gradebook, 'saveSettings')
      .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
    renderer = new StudentColumnHeaderRenderer(gradebook, StudentColumnHeader, 'student')
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('renders the StudentColumnHeader to the given container node', () => {
      render()
      ok($container.innerText.includes('Student Name'), 'the "Student Name" header is rendered')
    })

    test('calls the "ref" callback option with the component reference', () => {
      render()
      equal(component.constructor.name, 'StudentColumnHeader')
    })

    test('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement')
      render()
      component.props.addGradebookElement()
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1)
    })

    test('sets the component as disabled when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      render()
      strictEqual(component.props.disabled, true)
    })

    test('sets the component as not disabled when students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      render()
      strictEqual(component.props.disabled, false)
    })

    test('includes the login handle name from Gradebook', () => {
      render()
      equal(component.props.loginHandleName, 'a_jones')
    })

    test('includes a callback for keyDown events', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      const exampleEvent = new Event('example')
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown(exampleEvent)
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0]
      equal(event, exampleEvent)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1]
      equal(columnId, 'student')
    })

    test('includes a callback for closing the column header menu', () => {
      const clock = sinon.useFakeTimers()
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose')
      render()
      component.props.onMenuDismiss()
      clock.tick(0)
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 1)
      clock.restore()
    })

    test('does not call the menu close handler synchronously', () => {
      // The React render lifecycle is not yet complete at this time.
      // The callback must begin after React finishes to avoid conflicts.
      const clock = sinon.useFakeTimers()
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose')
      render()
      component.props.onMenuDismiss()
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 0)
      clock.restore()
    })

    test('includes a callback for selecting the primary info', () => {
      sinon.stub(gradebook, 'setSelectedPrimaryInfo')
      render()
      component.props.onSelectPrimaryInfo()
      strictEqual(gradebook.setSelectedPrimaryInfo.callCount, 1)
    })

    test('includes a callback for selecting the secondary info', () => {
      sinon.stub(gradebook, 'setSelectedSecondaryInfo')
      render()
      component.props.onSelectSecondaryInfo()
      strictEqual(gradebook.setSelectedSecondaryInfo.callCount, 1)
    })

    test('includes a callback for toggling the enrollment filter', () => {
      sinon.stub(gradebook, 'toggleEnrollmentFilter')
      render()
      component.props.onToggleEnrollmentFilter()
      strictEqual(gradebook.toggleEnrollmentFilter.callCount, 1)
    })

    test('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement')
      render()
      component.props.removeGradebookElement()
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1)
    })

    test('sets sectionsEnabled to false when sections are not in use', () => {
      render()
      strictEqual(component.props.sectionsEnabled, false)
    })

    test('sets studentGroupsEnabled to true when student groups are present', () => {
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
      render()
      strictEqual(component.props.studentGroupsEnabled, true)
    })

    test('sets studentGroupsEnabled to false when student groups are not present', () => {
      render()
      strictEqual(component.props.studentGroupsEnabled, false)
    })

    test('includes the selected enrollment filters', async () => {
      await gradebook.toggleEnrollmentFilter('concluded')
      render()
      deepEqual(component.props.selectedEnrollmentFilters, ['concluded'])
    })

    test('includes the selected primary info setting', () => {
      render()
      equal(component.props.selectedPrimaryInfo, 'first_last')
    })

    test('includes the selected secondary info setting', () => {
      render()
      equal(component.props.selectedSecondaryInfo, 'none')
    })

    test('includes the SIS name', () => {
      render()
      equal(component.props.sisName, 'Example SIS')
    })

    test('includes the "Sort by" direction setting', () => {
      render()
      equal(component.props.sortBySetting.direction, 'ascending')
    })

    test('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      gradebook.setStudentsLoaded(false)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to false when students are loaded', () => {
      gradebook.setStudentsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, false)
    })

    test('sets the "Sort by" isSortColumn setting to true when sorting by the student column', () => {
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, true)
    })

    test('sets the "Sort by" isSortColumn setting to false when not sorting by the student column', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, false)
    })

    test('includes the onSortBySortableName callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortBySortableName()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortBySisId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortBySisId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sis_user_id',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByIntegrationId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByIntegrationId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'integration_id',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByLoginId callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByLoginId()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'login_id',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortInAscendingOrder callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'descending')
      render()
      component.props.sortBySetting.onSortInAscendingOrder()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortInDescendingOrder callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'ascending')
      render()
      component.props.sortBySetting.onSortInDescendingOrder()
      const expectedSetting = {
        columnId: 'student',
        direction: 'descending',
        settingKey: 'sortable_name',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortBySortableNameAscending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'descending')
      render()
      component.props.sortBySetting.onSortBySortableNameAscending()
      const expectedSetting = {
        columnId: 'student',
        direction: 'ascending',
        settingKey: 'sortable_name',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortBySortableNameDescending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'sortable_name', 'ascending')
      render()
      component.props.sortBySetting.onSortBySortableNameDescending()
      const expectedSetting = {
        columnId: 'student',
        direction: 'descending',
        settingKey: 'sortable_name',
      }
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    QUnit.module('when not currently sorting by the student column', () => {
      test('defaults to the "sortable_name" key when "sort ascending" is selected', () => {
        gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'descending')
        render()
        component.props.sortBySetting.onSortInAscendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'ascending',
          settingKey: 'sortable_name',
        }
        deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
      })

      test('defaults to the "sortable_name" key when "sort descending" is selected', () => {
        gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
        render()
        component.props.sortBySetting.onSortInDescendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'descending',
          settingKey: 'sortable_name',
        }
        deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
      })
    })

    QUnit.module('when currently sorting by the student column', () => {
      test('preserves the existing sort key when "sort ascending" is selected', () => {
        gradebook.setSortRowsBySetting('student', 'integration_id', 'descending')
        render()
        component.props.sortBySetting.onSortInAscendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'ascending',
          settingKey: 'integration_id',
        }
        deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
      })

      test('preserves the existing sort key when "sort descending" is selected', () => {
        gradebook.setSortRowsBySetting('student', 'integration_id', 'ascending')
        render()
        component.props.sortBySetting.onSortInDescendingOrder()
        const expectedSetting = {
          columnId: 'student',
          direction: 'descending',
          settingKey: 'integration_id',
        }
        deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
      })
    })

    test('includes the "Sort by" settingKey', () => {
      render()
      equal(component.props.sortBySetting.settingKey, 'sortable_name')
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the component', () => {
      render()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      strictEqual(removed, false, 'the component was already unmounted')
    })
  })
})
/* eslint-enable qunit/no-identical-names */
