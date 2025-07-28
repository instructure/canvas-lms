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

import {createGradebook} from '../../../__tests__/GradebookSpecHelper'
import TotalGradeColumnHeaderRenderer from '../TotalGradeColumnHeaderRenderer'

describe('GradebookGrid TotalGradeColumnHeaderRenderer', () => {
  let container
  let gradebook
  let gridSupport
  let columns
  let column
  let renderer
  let component

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)

    gradebook = createGradebook()
    gradebook.keyboardNav = {
      addGradebookElement: jest.fn(),
      removeGradebookElement: jest.fn(),
      handleMenuOrDialogClose: jest.fn(),
    }
    gradebook.gradingPeriodSet = {id: '1', weighted: false}
    gradebook.options = {
      ...gradebook.options,
      grading_standard_points_based: true,
      show_total_grade_as_points: true,
      context_id: '1',
      currentUserId: '1',
      message_attachment_upload_folder_id: '1',
    }

    jest.spyOn(gradebook, 'saveSettings')

    columns = {
      frozen: [{id: 'student'}],
      scrollable: [{id: 'assignment_2301'}, {id: 'total_grade'}],
    }

    gridSupport = {
      columns: {
        getColumns() {
          return columns
        },
      },
    }

    column = {id: 'total_grade'}
    renderer = new TotalGradeColumnHeaderRenderer(gradebook)
  })

  afterEach(() => {
    component = null
    container.remove()
  })

  const renderHeader = () => {
    renderer.render(column, container, gridSupport, {
      ref(ref) {
        component = ref
      },
    })
  }

  describe('#render()', () => {
    it('renders the TotalGradeColumnHeader', () => {
      renderHeader()
      expect(container.textContent).toContain('Total')
    })

    it('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      renderHeader()
      component.props.addGradebookElement()
      expect(gradebook.keyboardNav.addGradebookElement).toHaveBeenCalled()
    })

    it('sets grabFocus to true when the column header option menu needs focus', () => {
      jest.spyOn(gradebook, 'totalColumnShouldFocus').mockReturnValue(true)
      renderHeader()
      expect(component.props.grabFocus).toBe(true)
    })

    it('sets grabFocus to false when the column header option menu does not need focus', () => {
      jest.spyOn(gradebook, 'totalColumnShouldFocus').mockReturnValue(false)
      renderHeader()
      expect(component.props.grabFocus).toBe(false)
    })

    it('displays grades as points when set in gradebook options', () => {
      gradebook.options.show_total_grade_as_points = true
      renderHeader()
      expect(component.props.gradeDisplay.currentDisplay).toBe('points')
    })

    it('displays grades as percent when set in gradebook options', () => {
      gradebook.options.show_total_grade_as_points = false
      renderHeader()
      expect(component.props.gradeDisplay.currentDisplay).toBe('percentage')
    })

    it('hides the action to change grade display when assignment groups are weighted', () => {
      jest.spyOn(gradebook, 'weightedGroups').mockReturnValue(true)
      renderHeader()
      expect(component.props.gradeDisplay.hidden).toBe(true)
    })

    it('hides the action to change grade display when grading periods are weighted', () => {
      gradebook.gradingPeriodSet = {id: '1', weighted: true}
      renderHeader()
      expect(component.props.gradeDisplay.hidden).toBe(true)
    })

    it('shows the action to change grade display when assignment groups are not weighted', () => {
      jest.spyOn(gradebook, 'weightedGroups').mockReturnValue(false)
      renderHeader()
      expect(component.props.gradeDisplay.hidden).toBe(false)
    })

    it('shows the action to change grade display when grading periods are not weighted', () => {
      gradebook.gradingPeriodSet = {id: '1', weighted: false}
      renderHeader()
      expect(component.props.gradeDisplay.hidden).toBe(false)
    })

    it('includes a callback to toggle grade display', () => {
      jest.spyOn(gradebook, 'togglePointsOrPercentTotals')
      renderHeader()
      // Mock the dialog to prevent jQuery errors
      jest.spyOn(gradebook, 'togglePointsOrPercentTotals').mockImplementation(() => {})
      component.props.gradeDisplay.onSelect()
      expect(gradebook.togglePointsOrPercentTotals).toHaveBeenCalled()
    })

    it('calls Gradebook#handleHeaderKeyDown with the event and column id', () => {
      const event = new Event('keydown')
      jest.spyOn(gradebook, 'handleHeaderKeyDown').mockImplementation(() => {})
      renderHeader()
      component.props.onHeaderKeyDown(event)
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledWith(event, column.id)
    })

    it('includes a callback for closing the column header menu', () => {
      jest.useFakeTimers()
      renderHeader()
      component.props.onMenuDismiss()
      expect(gradebook.keyboardNav.handleMenuOrDialogClose).not.toHaveBeenCalled()
      jest.runAllTimers()
      expect(gradebook.keyboardNav.handleMenuOrDialogClose).toHaveBeenCalled()
      jest.useRealTimers()
    })

    it('sets position.isInBack to true when the column is the last scrollable column', () => {
      renderHeader()
      expect(component.props.position.isInBack).toBe(true)
    })

    it('sets position.isInBack to false when the column is not the last scrollable column', () => {
      columns.scrollable = [{id: 'total_grade'}, {id: 'assignment_2301'}]
      renderHeader()
      expect(component.props.position.isInBack).toBe(false)
    })

    it('sets position.isInBack to false when the column is not scrollable', () => {
      columns.frozen = [{id: 'student'}, {id: 'total_grade'}]
      columns.scrollable = [{id: 'assignment_2301'}]
      renderHeader()
      expect(component.props.position.isInBack).toBe(false)
    })

    it('sets weightedGroups to true when groups are weighted', () => {
      jest.spyOn(gradebook, 'weightedGroups').mockReturnValue(true)
      renderHeader()
      expect(component.props.weightedGroups).toBe(true)
    })
  })
})
