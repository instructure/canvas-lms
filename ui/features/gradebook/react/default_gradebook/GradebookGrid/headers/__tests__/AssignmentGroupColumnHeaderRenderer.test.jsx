/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {createGradebook, setFixtureHtml} from '../../../__tests__/GradebookSpecHelper'
import AssignmentGroupColumnHeaderRenderer from '../AssignmentGroupColumnHeaderRenderer'
import {getAssignmentGroupColumnId} from '../../../Gradebook.utils'

describe('GradebookGrid AssignmentGroupColumnHeaderRenderer', () => {
  let container
  let gradebook
  let assignmentGroup
  let column
  let renderer
  let component

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

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    setFixtureHtml(container)

    gradebook = createGradebook({
      grading_standard_points_based: true,
      context_id: '1',
      currentUserId: '1',
      message_attachment_upload_folder_id: '1',
      show_message_students_with_observers_dialog: true,
    })
    ENV.SETTINGS = {}
    jest.spyOn(gradebook, 'saveSettings')

    assignmentGroup = {
      id: '2201',
      position: 1,
      name: 'Assignments',
      assignments,
    }

    gradebook.gotAllAssignmentGroups([assignmentGroup])
    gradebook.setAssignmentsLoaded()
    gradebook.setStudentsLoaded(true)
    gradebook.setSubmissionsLoaded(true)

    column = {id: getAssignmentGroupColumnId('2201'), assignmentGroupId: '2201'}
    renderer = new AssignmentGroupColumnHeaderRenderer(gradebook)

    // Setup keyboardNav mock
    gradebook.keyboardNav = {
      addGradebookElement: jest.fn(),
      removeGradebookElement: jest.fn(),
      handleMenuOrDialogClose: jest.fn(),
    }

    // Setup gridSupport mock
    gradebook.gradebookGrid = {
      gridSupport: {
        columns: {
          updateColumnHeaders: jest.fn(),
        },
        navigation: {
          handleHeaderKeyDown: jest.fn(),
        },
      },
      grid: {
        getColumnIndex: jest.fn(),
      },
      invalidate: jest.fn(),
    }

    // Setup grid display settings
    gradebook.gridDisplaySettings = {
      sortRowsBy: {
        columnId: '',
        settingKey: '',
        direction: 'ascending',
      },
      filterRowsBy: {},
      filterColumnsBy: {},
      selectedViewOptionsFilters: [],
      showEnrollments: {},
      colors: {},
      enterGradesAs: {},
      selectedPrimaryInfo: 'first_last',
      selectedSecondaryInfo: 'none',
    }
  })

  afterEach(() => {
    container.remove()
    jest.resetAllMocks()
  })

  const render = () => {
    renderer.render(
      column,
      container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      },
    )
  }

  describe('#render()', () => {
    it('renders the AssignmentGroupColumnHeader to the given container node', () => {
      render()
      expect(container.innerText).toContain('Assignments')
    })

    it('calls the "ref" callback option with the component reference', () => {
      render()
      expect(component.constructor.name).toBe('AssignmentGroupColumnHeader')
    })

    it('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      render()
      component.props.addGradebookElement()
      expect(gradebook.keyboardNav.addGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('includes the assignment group weight', () => {
      assignmentGroup.group_weight = 25
      render()
      expect(component.props.assignmentGroup.groupWeight).toBe(25)
    })

    it('includes the assignment group name', () => {
      render()
      expect(component.props.assignmentGroup.name).toBe('Assignments')
    })

    it('includes a callback for keyDown events', () => {
      render()
      const event = new Event('keydown')
      component.props.onHeaderKeyDown(event)
      expect(gradebook.gradebookGrid.gridSupport.navigation.handleHeaderKeyDown).toHaveBeenCalled()
    })

    it('calls Gradebook#handleHeaderKeyDown with the given event', () => {
      const event = new Event('example')
      render()
      component.props.onHeaderKeyDown(event)
      expect(gradebook.gradebookGrid.gridSupport.navigation.handleHeaderKeyDown).toHaveBeenCalled()
    })

    it('includes a callback for closing the column header menu', () => {
      jest.useFakeTimers()
      render()
      component.props.onMenuDismiss()
      jest.runAllTimers()
      expect(gradebook.keyboardNav.handleMenuOrDialogClose).toHaveBeenCalledTimes(1)
      jest.useRealTimers()
    })

    it('does not call the menu close handler synchronously', () => {
      jest.useFakeTimers()
      render()
      component.props.onMenuDismiss()
      expect(gradebook.keyboardNav.handleMenuOrDialogClose).not.toHaveBeenCalled()
      jest.useRealTimers()
    })

    it('includes a callback for removing elements from the Gradebook KeyboardNav', () => {
      render()
      component.props.removeGradebookElement()
      expect(gradebook.keyboardNav.removeGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('includes the "Sort by" direction setting', () => {
      render()
      expect(component.props.sortBySetting.direction).toBe('ascending')
    })

    it('sets the "Sort by" disabled setting to true when assignments are not loaded', () => {
      gradebook.contentLoadStates.assignmentsLoaded.all = false
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(false)
      gradebook.setSubmissionsLoaded(true)
      render()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to true when submissions are not loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      render()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to false when necessary data are loaded', () => {
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      expect(component.props.sortBySetting.disabled).toBe(false)
    })

    it('sets the "Sort by" isSortColumn setting to true when sorting by this column', () => {
      gradebook.gridDisplaySettings.sortRowsBy = {
        columnId: column.id,
        settingKey: 'assignment_group',
        direction: 'ascending',
      }
      render()
      expect(component.props.sortBySetting.isSortColumn).toBe(true)
    })

    it('sets the "Sort by" isSortColumn setting to false when not sorting by this column', () => {
      gradebook.gridDisplaySettings.sortRowsBy = {
        columnId: 'student',
        settingKey: 'sortable_name',
        direction: 'ascending',
      }
      render()
      expect(component.props.sortBySetting.isSortColumn).toBe(false)
    })
  })

  describe('#destroy()', () => {
    it('unmounts the component', () => {
      render()
      const unmountSpy = jest.spyOn(renderer, 'destroy')
      renderer.destroy(column, container, {})
      expect(unmountSpy).toHaveBeenCalled()
    })
  })
})
