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
import {GradedDiscussionDueDatesContext} from '../../../util/constants'

const setup = ({
  assignedInfoList = [{dueDateId: 'uniqueID'}],
  setAssignedInfoList = () => {},
} = {}) => {
  return render(
    <GradedDiscussionDueDatesContext.Provider value={{assignedInfoList, setAssignedInfoList}}>
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
    const testAssignedTo = [
      {
        dueDateId: 'C2mULLRUV9e8p7zVJNPfr',
        assignedList: ['sec_1', 'sec_2'],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
      {
        dueDateId: 'Wd7eOGpYc-KFouW-ePdpm',
        assignedList: ['mp_option1'],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
    ]
    setup({assignedInfoList: testAssignedTo})
    // There should be 2 menus
    const selectOptions = screen.getAllByTestId('assign-to-select')
    const assignToOptionOne = selectOptions[0]
    const assignToOptionTwo = selectOptions[1]

    fireEvent.click(assignToOptionOne)

    let availableOptions = screen.getAllByTestId('assign-to-select-option')

    // Currently there are 10 DEFAULT_OPTIONS defined in AssignmentDueDatesManager.jsx.
    // All the checks below rely on this.
    // When VICE-3865 is complete, the default data will be replaced with real data that will
    // Need to be mocked. and the data below will need to be updated

    // Since 1 option is selected in the other menu, there will only be 9 options available
    expect(availableOptions.length).toBe(9)

    // Since there are 2 options selected in the first menu, there will only be 8 options available
    fireEvent.click(assignToOptionTwo)
    availableOptions = screen.getAllByTestId('assign-to-select-option')
    expect(availableOptions.length).toBe(8)
  })
})
