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
import {act, screen, render, waitFor} from '@testing-library/react'
import AssignToPanel, {type AssignToPanelProps} from '../AssignToPanel'
import {ASSIGNMENT_OVERRIDES_DATA, SECTIONS_DATA, STUDENTS_DATA} from './mocks'
import * as utils from '../../utils/assignToHelper'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

jest.mock('../../utils/assignToHelper', () => {
  const originalModule = jest.requireActual('../../utils/assignToHelper')

  return {
    __esModule: true,
    ...originalModule,
    updateModuleUI: jest.fn(),
  }
})

const errorText = 'A student or section must be selected'
const errorTooltipText = 'Please fix errors before continuing'

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
  const STUDENTS_URL = `/api/v1/courses/${props.courseId}/users?enrollment_type=student`

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
    expect(await findByText('By default, this module is visible to everyone.')).toBeInTheDocument()
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
    await userEvent.click(await findByTestId('custom-option'))
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

  describe('error messages', () => {
    it('does not display empty assignee error on open', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      await waitFor(() => expect(screen.queryByText(errorText)).toBeNull())
    })

    it('does display empty assignee error on blur', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
    })

    it('clears empty assignee error on selection', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()

      await userEvent.click(assigneeSelector)
      const option = await screen.findByText(STUDENTS_DATA[0].name)
      await userEvent.click(option)
      await waitFor(() => expect(screen.queryByText(errorText)).toBeNull())
    })

    it('clears empty assignee error when Everyone is selected', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.hover(saveButton)
      expect(screen.getByText(errorTooltipText)).toBeInTheDocument()

      const everyoneOption = await screen.findByTestId('everyone-option')
      await userEvent.click(everyoneOption)
      expect(screen.queryByText(errorText)).toBeNull()
      await userEvent.hover(saveButton)
      expect(screen.queryByText(errorTooltipText)).not.toBeInTheDocument()
    })

    it('does not save when empty assignee error is displayed', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.click(saveButton)
      expect(assigneeSelector).toHaveFocus()
    })

    it('displays empty assignee error on clearAll', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)

      const clearAllButton = screen.getByTestId('clear_selection_button')
      await userEvent.click(clearAllButton)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
    })

    it('displays empty assignee error on clearAll after component is rendered with pills', async () => {
      fetchMock.getOnce(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
        overwriteRoutes: true,
      })
      renderComponent()
      expect(await screen.findByTestId('custom-option')).toBeChecked()
      const clearAllButton = screen.getByTestId('clear_selection_button')
      await userEvent.click(clearAllButton)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
    })

    it('displays empty assignee error after switching options', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()

      const everyoneOption = await screen.findByTestId('everyone-option')
      await userEvent.click(everyoneOption)
      expect(screen.queryByText(errorText)).toBeNull()
      await userEvent.click(customOption)
      expect(await screen.findByText(errorText)).toBeInTheDocument()
    })

    it('displays empty assignee error if the user switches to custom and clicks save without adding any assignees', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      expect(screen.queryByText(errorText)).not.toBeInTheDocument()
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.click(saveButton)
      const assigneeSelector = await screen.findByTestId('assignee_selector')
      expect(screen.getByText(errorText)).toBeInTheDocument()
      expect(assigneeSelector).toHaveFocus()
    })
  })

  describe('on update', () => {
    it('creates new assignment overrides', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {})
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      act(() => customOption.click())
      const assigneeSelector = await findByTestId('assignee_selector')
      act(() => assigneeSelector.click())
      const option1 = await findByText(SECTIONS_DATA[0].name)
      act(() => option1.click())

      getByRole('button', {name: 'Save'}).click()
      expect((await findAllByText('Module access updated successfully.'))[0]).toBeInTheDocument()
      const requestBody = fetchMock.lastOptions(ASSIGNMENT_OVERRIDES_URL)?.body
      const expectedPayload = JSON.stringify({
        overrides: [{course_section_id: SECTIONS_DATA[0].id}],
      })
      expect(requestBody).toEqual(expectedPayload)
    })

    it('updates existing assignment overrides', async () => {
      fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {overwriteRoutes: true})
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {})
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

      getByRole('button', {name: 'Save'}).click()
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

    it('updates the modules UI', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {})
      const {findByRole} = renderComponent()
      const updateButton = await findByRole('button', {name: 'Save'})
      updateButton.click()
      await waitFor(() => expect(utils.updateModuleUI).toHaveBeenCalled())
    })

    it('calls onDidSubmit instead of onDismiss if passed', async () => {
      fetchMock.put(ASSIGNMENT_OVERRIDES_URL, {})
      const onDidSubmitMock = jest.fn()
      const onDismissMock = jest.fn()
      renderComponent({
        onDidSubmit: onDidSubmitMock,
        onDismiss: onDismissMock,
      })
      await userEvent.click(screen.getByTestId('custom-option'))
      await userEvent.click(screen.getByTestId('assignee_selector'))
      await userEvent.click(screen.getByText(SECTIONS_DATA[0].name))
      await userEvent.click(screen.getByTestId('differentiated_modules_save_button'))
      expect(onDidSubmitMock).toHaveBeenCalled()
      expect(onDismissMock).not.toHaveBeenCalled()
    })
  })
})
