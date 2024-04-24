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
import AssignmentGroupColumnHeaderRenderer from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/AssignmentGroupColumnHeaderRenderer'
import {getAssignmentGroupColumnId} from 'ui/features/gradebook/react/default_gradebook/Gradebook.utils'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid AssignmentGroupColumnHeaderRenderer', suiteHooks => {
  let $container
  let gradebook
  let assignmentGroup
  let column
  let renderer
  let component

  function render() {
    renderer.render(
      column,
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

    gradebook = createGradebook()
    sinon.stub(gradebook, 'saveSettings')

    const assignments = [
      {
        id: '2301',
        assignment_visibility: null,
        course_id: '1201',
        html_url: '/assignments/2301',
        muted: false,
        name: 'Math Assignment',
        omit_from_final_grade: false,
        only_visible_to_overrides: false,
        published: true,
        submission_types: ['online_text_entry'],
      },
    ]

    assignmentGroup = {
      id: '2201',
      position: 1,
      name: 'Assignments',
      assignments,
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    column = {id: getAssignmentGroupColumnId('2201'), assignmentGroupId: '2201'}
    renderer = new AssignmentGroupColumnHeaderRenderer(gradebook)
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('renders the AssignmentGroupColumnHeader to the given container node', () => {
      render()
      ok($container.innerText.includes('Assignments'), 'the "Assignments" header is rendered')
    })

    test('calls the "ref" callback option with the component reference', () => {
      render()
      equal(component.constructor.name, 'AssignmentGroupColumnHeader')
    })

    test('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement')
      render()
      component.props.addGradebookElement()
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1)
    })

    test('includes the assignment group weight', () => {
      assignmentGroup.group_weight = 25
      render()
      strictEqual(component.props.assignmentGroup.groupWeight, 25)
    })

    test('includes the assignment group name', () => {
      render()
      equal(component.props.assignmentGroup.name, 'Assignments')
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
      strictEqual(columnId, column.id)
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

    test('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement')
      render()
      component.props.removeGradebookElement()
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1)
    })

    test('includes the "Sort by" direction setting', () => {
      render()
      equal(component.props.sortBySetting.direction, 'ascending')
    })

    test('sets the "Sort by" disabled setting to true when assignments are not loaded', () => {
      gradebook.contentLoadStates.assignmentsLoaded.all = false
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(false)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when submissions are not loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to false when necessary data are loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, false)
    })

    test('sets the "Sort by" isSortColumn setting to true when sorting by this column', () => {
      gradebook.setSortRowsBySetting('assignment_group_2201', 'grade', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, true)
    })

    test('sets the "Sort by" isSortColumn setting to false when not sorting by this column', () => {
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, false)
    })

    test('includes the onSortByGradeAscending callback', () => {
      gradebook.setSortRowsBySetting('assignment_group_2201', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeAscending()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByGradeDescending callback', () => {
      gradebook.setSortRowsBySetting('assignment_group_2201', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeDescending()
      const expectedSetting = {columnId: column.id, direction: 'descending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the "Sort by" settingKey', () => {
      gradebook.setSortRowsBySetting('assignment_group_2201', 'grade', 'ascending')
      render()
      equal(component.props.sortBySetting.settingKey, 'grade')
    })

    test('sets weightedGroups to true when groups are weighted', () => {
      sinon.stub(gradebook, 'weightedGroups').returns(true)
      render()
      strictEqual(component.props.weightedGroups, true)
    })

    test('sets weightedGroups to false when groups are not weighted', () => {
      sinon.stub(gradebook, 'weightedGroups').returns(false)
      render()
      strictEqual(component.props.weightedGroups, false)
    })

    test('sets onApplyScoreToUngraded to a function calling the method in gradebook if gradebook allows it', () => {
      sinon.stub(gradebook, 'allowApplyScoreToUngraded').returns(true)
      sinon.stub(gradebook, 'onApplyScoreToUngradedRequested')

      render()

      component.props.onApplyScoreToUngraded()
      ok(gradebook.onApplyScoreToUngradedRequested.calledOnce)
    })

    test('does not set onApplyScoreToUngraded if gradebook does not allow it', () => {
      sinon.stub(gradebook, 'allowApplyScoreToUngraded').returns(false)
      render()
      notOk(component.props.onApplyScoreToUngraded)
    })

    test('sends message when handleSendMessageStudentWho is executed', () => {
      const recipientsIds = [1, 2, 3, 4]
      const subject = 'foo'
      const body = 'bar'
      const contextCode = '1'

      sinon.stub(gradebook, 'sendMessageStudentsWho')
      render()
      component.props.onSendMessageStudentsWho(recipientsIds, subject, body, contextCode)
      strictEqual(gradebook.sendMessageStudentsWho.callCount, 1)
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
