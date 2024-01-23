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

import React from 'react'
import {act, render, waitFor} from '@testing-library/react'
import AssignToPanel, {type AssignToPanelProps} from '../AssignToPanel'
import {ASSIGNMENT_OVERRIDES_DATA, SECTIONS_DATA, STUDENTS_DATA} from './mocks'
import * as utils from '../../utils/assignToHelper'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

describe('AssignToPanel', () => {
  const props: AssignToPanelProps = {
    courseId: '1',
    moduleId: '2',
    bodyHeight: '400px',
    footerHeight: '100px',
    moduleElement: document.createElement('div'),
    onDismiss: () => {},
    mountNodeRef: {current: null},
  }

  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/${props.courseId}/modules/${props.moduleId}/assignment_overrides`
  const SECTIONS_URL = `/api/v1/courses/${props.courseId}/sections`
  const STUDENTS_URL = `api/v1/courses/${props.courseId}/users?enrollment_type=student`

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    fetchMock.getOnce(SECTIONS_URL, SECTIONS_DATA)
    fetchMock.getOnce(STUDENTS_URL, STUDENTS_DATA)
    fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, [])
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const renderComponent = (overrides = {}) => render(<AssignToPanel {...props} {...overrides} />)

  it('renders', async () => {
    const {findByText} = renderComponent()
    expect(
      await findByText('By default everyone in this course has assigned access to this module.')
    ).toBeInTheDocument()
  })

  it('renders options', async () => {
    const {findByTestId} = renderComponent()
    expect(await findByTestId('loading-overlay')).toBeInTheDocument()
    expect(await findByTestId('everyone-option')).toBeInTheDocument()
    expect(await findByTestId('custom-option')).toBeInTheDocument()
  })

  it('renders everyone as the default option', async () => {
    const {findByTestId} = renderComponent()
    expect(await findByTestId('everyone-option')).toBeChecked()
    expect(await findByTestId('custom-option')).not.toBeChecked()
  })

  it('renders option if a default option is passed', async () => {
    const {findByTestId} = renderComponent({defaultOption: 'custom'})
    expect(await findByTestId('everyone-option')).not.toBeChecked()
    expect(await findByTestId('custom-option')).toBeChecked()
  })

  it('renders custom access as the default option if there are assignmentOverrides', async () => {
    fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
      overwriteRoutes: true,
    })
    const {findByTestId} = renderComponent()
    expect(await findByTestId('loading-overlay')).toBeInTheDocument()
    expect(await findByTestId('custom-option')).toBeChecked()
  })

  it('not render custom access as the default option if default option is called', async () => {
    fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
      overwriteRoutes: true,
    })
    const {findByTestId} = renderComponent({defaultOption: 'everyone'})
    expect(await findByTestId('everyone-option')).toBeChecked()
  })

  it('calls updateParentData on unmount with changes', async () => {
    const updateParentDataMock = jest.fn()
    const {unmount, findByTestId} = renderComponent({updateParentData: updateParentDataMock})
    userEvent.click(await findByTestId('custom-option'))
    unmount()
    expect(updateParentDataMock).toHaveBeenCalledWith(
      {
        selectedAssignees: [],
        selectedOption: 'custom',
      },
      true
    )
  })

  it('calls updateParentData on unmount with no changes', async () => {
    const updateParentDataMock = jest.fn()
    const {unmount} = renderComponent({updateParentData: updateParentDataMock})
    unmount()
    expect(updateParentDataMock).toHaveBeenCalledWith(
      {
        selectedAssignees: [],
        selectedOption: 'everyone',
      },
      false
    )
  })

  describe('AssigneeSelector', () => {
    it('selects multiple options', async () => {
      const {findByTestId, findByText, getAllByTestId} = renderComponent()
      const customOption = await findByTestId('custom-option')
      act(() => customOption.click())
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())
      act(() => assigneeSelector.click())
      const option2 = await findByText(SECTIONS_DATA[2].name)
      act(() => option2.click())
      expect(getAllByTestId('assignee_selector_selected_option').length).toBe(2)
    })

    it('clears selection', async () => {
      const {findByTestId, getByTestId, queryAllByTestId, findByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      act(() => customOption.click())
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option = await findByText(STUDENTS_DATA[0].name)
      act(() => option.click())
      expect(queryAllByTestId('assignee_selector_selected_option').length).toBe(1)
      act(() => getByTestId('clear_selection_button').click())
      expect(queryAllByTestId('assignee_selector_selected_option').length).toBe(0)
    })

    it('shows existing assignmentOverrides as the default selection', async () => {
      fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
        overwriteRoutes: true,
      })
      const assignedSections = ASSIGNMENT_OVERRIDES_DATA.filter(
        override => override.course_section !== undefined
      )
      const {getAllByTestId, findByText} = renderComponent()
      expect(await findByText(ASSIGNMENT_OVERRIDES_DATA[0].students![0].name)).toBeInTheDocument()
      expect(getAllByTestId('assignee_selector_selected_option').length).toBe(
        ASSIGNMENT_OVERRIDES_DATA[0].students!.length + assignedSections.length
      )
    })

    it('does not show existing assignmentOverrides as the default if defaultOption and defaultAssignees are passed', async () => {
      const defaultAssignees = [
        {
          id: '3',
          overrideId: '3',
          value: 'Previously added assignment',
          group: 'Sections',
        },
      ]
      const {getAllByTestId, findByText} = renderComponent({
        defaultOption: 'custom',
        defaultAssignees,
      })
      expect(await findByText(defaultAssignees[0].value)).toBeInTheDocument()
      expect(getAllByTestId('assignee_selector_selected_option').length).toBe(
        defaultAssignees.length
      )
    })
  })

  describe('on update', () => {
    it('creates new assignment overrides', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {}, {delay: 200})
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      act(() => customOption.click())
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())

      getByRole('button', {name: 'Update Module'}).click()
      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      expect((await findAllByText('Module access updated successfully.'))[0]).toBeInTheDocument()
      const requestBody = fetchMock.lastOptions(ASSIGNMENT_OVERRIDES_URL)?.body
      const expectedPayload = JSON.stringify({
        overrides: [{course_section_id: SECTIONS_DATA[0].id}],
      })
      expect(requestBody).toEqual(expectedPayload)
    })

    it('updates existing assignment overrides', async () => {
      fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {overwriteRoutes: true})
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {}, {delay: 200})
      const studentsOverride = ASSIGNMENT_OVERRIDES_DATA[0]
      const existingOverride = ASSIGNMENT_OVERRIDES_DATA[1]
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      act(() => customOption.click())
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(existingOverride.course_section?.name!)
      // removing the existing section override
      act(() => option1.click())

      getByRole('button', {name: 'Update Module'}).click()
      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      expect((await findAllByText('Module access updated successfully.'))[0]).toBeInTheDocument()
      const requestBody = fetchMock.lastOptions(ASSIGNMENT_OVERRIDES_URL)?.body
      // it sends back the student list override, including the assignment override id
      const expectedPayload = JSON.stringify({
        overrides: [
          {id: studentsOverride.id, student_ids: studentsOverride.students!.map(({id}) => id)},
        ],
      })
      expect(requestBody).toEqual(expectedPayload)
    })

    // LF-1169 - remove or rewrite to remove spies on imports
    it.skip('updates the modules UI', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {})
      jest.spyOn(utils, 'updateModuleUI')
      const {findByRole, findByTestId} = renderComponent()
      const updateButton = await findByRole('button', {name: 'Update Module'})
      updateButton.click()
      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      await waitFor(() => expect(utils.updateModuleUI).toHaveBeenCalled())
    })

    it('calls onDidSubmit instead of onDismiss if passed', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {}, {delay: 200})
      const onDidSubmitMock = jest.fn()
      const onDismissMock = jest.fn()
      const {findByTestId, findByText, getByRole} = renderComponent({
        onDidSubmit: onDidSubmitMock,
        onDismiss: onDismissMock,
      })
      userEvent.click(await findByTestId('custom-option'))
      userEvent.click(await findByTestId('assignee_selector'))
      userEvent.click(await findByText(SECTIONS_DATA[0].name))
      userEvent.click(getByRole('button', {name: 'Update Module'}))

      expect(await findByTestId('loading-overlay')).toBeInTheDocument()

      await waitFor(() => {
        expect(onDidSubmitMock).toHaveBeenCalled()
        expect(onDismissMock).not.toHaveBeenCalled()
      })
    })
  })
})
