/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {render, fireEvent, screen} from '@testing-library/react'
import React from 'react'
import {AssignmentDueDatesManager} from '../AssignmentDueDatesManager'
import {
  GradedDiscussionDueDatesContext,
  defaultEveryoneOption,
  defaultEveryoneElseOption,
  masteryPathsOption,
} from '../../../util/constants'

const DEFAULT_LIST_OPTIONS = {
  'Course Sections': [
    {id: '1', name: 'Section 1'},
    {id: '2', name: 'Section 2'},
  ],
  Students: [
    {_id: 'u_1', name: 'Jason'},
    {_id: 'u_2', name: 'Drake'},
    {_id: 'u_3', name: 'Caleb'},
    {_id: 'u_4', name: 'Aaron'},
    {_id: 'u_5', name: 'Chawn'},
    {_id: 'u_6', name: 'Omar'},
  ],
  Groups: [
    {_id: '1', name: 'Group 1'},
    {_id: '2', name: 'Group 2'},
    {_id: '3', name: 'Group 3'},
  ],
}

const setup = ({
  assignedInfoList = [{assignedList: [defaultEveryoneOption.assetCode], dueDateId: 'uniqueID'}],
  setAssignedInfoList = () => {},
  students = DEFAULT_LIST_OPTIONS.Students,
  courseSections = DEFAULT_LIST_OPTIONS['Course Sections'],
  courseGroups = DEFAULT_LIST_OPTIONS.Groups,
  gradedDiscussionRefMap = new Map(),
  setGradedDiscussionRefMap = () => {},
} = {}) => {
  return render(
    <GradedDiscussionDueDatesContext.Provider
      value={{
        assignedInfoList,
        setAssignedInfoList,
        studentEnrollments: students,
        sections: courseSections,
        groups: courseGroups,
        gradedDiscussionRefMap,
        setGradedDiscussionRefMap,
      }}
    >
      <AssignmentDueDatesManager />
    </GradedDiscussionDueDatesContext.Provider>
  )
}

describe('AssignmentDueDatesManager', () => {
  it('renders Assignment Settings correctly', () => {
    const {queryByText} = setup()
    expect(queryByText('Assignment Settings')).toBeInTheDocument()
  })

  it('adds a new AssignmentDueDate when Add Assignment is clicked', () => {
    const setAssignedInfoList = jest.fn()
    setup({setAssignedInfoList})

    const addButton = screen.getByText('Add Assignment')
    fireEvent.click(addButton)

    // an array with 2 object should be sent to setAssignedInfoList when the add button is clicked
    expect(setAssignedInfoList).toHaveBeenCalledWith(
      expect.arrayContaining([
        expect.objectContaining({dueDateId: expect.any(String)}),
        expect.objectContaining({dueDateId: expect.any(String)}),
      ])
    )
  })

  it('shows Close button when there is more than one AssignmentDueDate', () => {
    setup({assignedInfoList: [{dueDateId: 'uniqueID'}, {dueDateId: 'uniqueID2'}]})
    // Assuming the CloseButton has a specific label or text
    expect(screen.getAllByText('Close').length).toBe(2)
  })

  it('removes an AssignmentDueDate when Close is clicked', () => {
    const setAssignedInfoList = jest.fn()
    setup({
      setAssignedInfoList,
      assignedInfoList: [{dueDateId: 'uniqueID'}, {dueDateId: 'uniqueID2'}],
    })

    // Verifying that a due date components exist
    const assignmentDueDates = screen.getAllByTestId('assignment-due-date')
    expect(assignmentDueDates.length).toBe(2)

    // Verifying that there is a close button
    const closeButtons = screen.getAllByText('Close')
    fireEvent.click(closeButtons[0])

    expect(setAssignedInfoList).toHaveBeenCalledWith(
      expect.arrayContaining([expect.objectContaining({dueDateId: expect.any(String)})])
    )
  })

  // currently this will use options from the DEFAULT_LIST_OPTIONS, will get replaced in the future.
  it('correctly manages available assignTo options', () => {
    window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    const testAssignedTo = [
      {
        dueDateId: 'C2mULLRUV9e8p7zVJNPfr',
        assignedList: ['course_section_1', 'course_section_2'],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
      {
        dueDateId: 'Wd7eOGpYc-KFouW-ePdpm',
        assignedList: [masteryPathsOption.assetCode],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
    ]
    setup({assignedInfoList: testAssignedTo})
    // This is getting all the select menus
    // on a UI this would be showing two assignment
    // override menus
    const selectOptions = screen.getAllByTestId('assign-to-select')
    const assignToOptionOne = selectOptions[0]
    const assignToOptionTwo = selectOptions[1]

    fireEvent.click(assignToOptionOne)

    let availableOptions = screen.getAllByTestId('assign-to-select-option')

    // There are 13 options by default
    // 1 option is selected in the other menu
    // therefore, there will only be 12 options available
    expect(availableOptions.length).toBe(12)

    // 2 options are selected in the other menu
    // therefore, there will only be 11 options available
    fireEvent.click(assignToOptionTwo)
    availableOptions = screen.getAllByTestId('assign-to-select-option')
    expect(availableOptions.length).toBe(11)
  })

  describe('everyone option', () => {
    it('when another option is selected, displays as "Everyone Else"', () => {
      setup({
        assignedInfoList: [
          {
            dueDateId: 'C2mULLRUV9e8p7zVJNPfr',
            assignedList: ['course_section_1', 'course_section_2'],
            dueDate: '',
            availableFrom: '',
            availableUntil: '',
          },
        ],
      })
      const selectOptions = screen.getAllByTestId('assign-to-select')
      const assignToOptionOne = selectOptions[0]

      fireEvent.click(assignToOptionOne)

      const availableOptions = screen.getAllByTestId('assign-to-select-option')
      expect(
        availableOptions.map(o => o.textContent).includes(defaultEveryoneElseOption.label)
      ).toBe(true)
    })
  })

  describe('group options', () => {
    it('with defaults data defined above, group options should show', () => {
      setup()
      const selectOptions = screen.getAllByTestId('assign-to-select')
      const assignToOptionOne = selectOptions[0]
      fireEvent.click(assignToOptionOne)

      const availableOptions = screen.getAllByTestId('assign-to-select-option')
      expect(availableOptions.length).toBe(13)
      expect(availableOptions.map(o => o.textContent).includes('Group 1')).toBe(true)
      expect(availableOptions.map(o => o.textContent).includes('Group 2')).toBe(true)
      expect(availableOptions.map(o => o.textContent).includes('Group 3')).toBe(true)
    })

    it('when groups is set to [] no group options should show', () => {
      setup({courseGroups: []})
      const selectOptions = screen.getAllByTestId('assign-to-select')
      const assignToOptionOne = selectOptions[0]
      fireEvent.click(assignToOptionOne)

      const availableOptions = screen.getAllByTestId('assign-to-select-option')
      expect(availableOptions.length).toBe(10)
      expect(availableOptions.map(o => o.textContent).includes('Group 1')).toBe(false)
    })

    it('renders the course pacing notice instead fo ', () => {
      window.ENV = {
        DISCUSSION_TOPIC: {
          ATTRIBUTES: {in_paced_course: true},
        },
      }
      setup()
      const coursePacingNotice = screen.getByText(
        'This course is using Course Pacing. Go to Course Pacing to manage due dates.'
      )
      const addAssignmentOption = screen.queryByText('Add Assignment')

      expect(coursePacingNotice).toBeInTheDocument()
      expect(addAssignmentOption).not.toBeInTheDocument()
    })
  })
})
