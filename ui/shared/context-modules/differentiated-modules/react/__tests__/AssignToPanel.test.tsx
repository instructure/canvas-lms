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
import {screen, render} from '@testing-library/react'
import AssignToPanel, {type AssignToPanelProps} from '../AssignToPanel'
import {ASSIGNMENT_OVERRIDES_DATA, SECTIONS_DATA, STUDENTS_DATA, DIFFERENTIATION_TAGS_DATA} from './mocks'
import * as utils from '../../utils/assignToHelper'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

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

  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/${props.courseId}/modules/${props.moduleId}/assignment_overrides?per_page=100`
  const ASSIGNMENT_OVERRIDES_URL_PUT = `/api/v1/courses/${props.courseId}/modules/${props.moduleId}/assignment_overrides`
  const COURSE_SETTINGS_URL = `/api/v1/courses/${props.courseId}/settings`
  const SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?per_page=\d+/
  const DIFFERENTIATION_TAGS_URL = `/api/v1/courses/${props.courseId}/groups?per_page=100&collaboration_state=non_collaborative&include=group_category`

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    /*
      These are used for the differentiation tag tests
      This file has some leakage with other tests so setting the
      ENV variables between tests is inconsistent
      This is a workaround until we can refactor the tests
    */
    // These are being skipped for now because setting the ENV 
    // in this file causes tests to be flakey
    // window.ENV.ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS = true
    // window.ENV.CAN_MANAGE_DIFFERENTIATION_TAGS = true
  })

  beforeEach(() => {
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})
    fetchMock.put(ASSIGNMENT_OVERRIDES_URL_PUT, {})
    fetchMock.get(DIFFERENTIATION_TAGS_URL, DIFFERENTIATION_TAGS_DATA)
  })

  afterEach(() => {
    fetchMock.restore()
    queryClient.removeQueries()
  })

  const renderComponent = (overrides = {}) =>
    render(
      <MockedQueryProvider>
        <AssignToPanel {...props} {...overrides} />
      </MockedQueryProvider>,
    )

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
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
      overwriteRoutes: true,
    })
    const {findByTestId} = renderComponent()
    expect(await findByTestId('loading-overlay')).toBeInTheDocument()
    expect(await findByTestId('custom-option')).toBeChecked()
  })

  it('not render custom access as the default option if default option is called', async () => {
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
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
      true,
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
      false,
    )
  })

  describe('AssigneeSelector', () => {
    it('selects multiple options', async () => {
      const {findByTestId, findByText, getAllByTestId} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option1 = await findByText(SECTIONS_DATA[0].name)
      await userEvent.click(option1)
      await userEvent.click(assigneeSelector)
      const option2 = await findByText(SECTIONS_DATA[2].name)
      await userEvent.click(option2)
      expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(2)
    })

    it('clears selection', async () => {
      const {findByTestId, getByTestId, queryAllByTestId, findByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option = await findByText(SECTIONS_DATA[0].name)
      await userEvent.click(option)
      expect(queryAllByTestId('assignee_selector_selected_option')).toHaveLength(1)
      await userEvent.click(getByTestId('clear_selection_button'))
      expect(queryAllByTestId('assignee_selector_selected_option')).toHaveLength(0)
    })

    it('shows existing assignmentOverrides as the default selection', async () => {
      fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
        overwriteRoutes: true,
      })
      const assignedSections = ASSIGNMENT_OVERRIDES_DATA.filter(
        override => override.course_section !== undefined,
      )
      const {getAllByTestId, findByText} = renderComponent()
      expect(await findByText(ASSIGNMENT_OVERRIDES_DATA[0].students![0].name)).toBeInTheDocument()
      expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(
        ASSIGNMENT_OVERRIDES_DATA[0].students!.length + assignedSections.length,
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
      expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(
        defaultAssignees.length,
      )
    })

    // Skipping this test because it relies on the ENV variables
    // Setting these ENV variables causes tests in this file to be flakey
    it.skip('can select a differentiation tag as an assignee', async () => {
      const {findByTestId, findByText, getAllByTestId} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option = await findByText(DIFFERENTIATION_TAGS_DATA[0].name)
      await userEvent.click(option)
      expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(1)
    })
  })

  describe('error messages', () => {
    it('does not display empty assignee error on open', async () => {
      renderComponent()
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      expect(screen.queryByText(errorText)).toBeNull()
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
      const option = await screen.findByText(STUDENTS_DATA[0].value)
      await userEvent.click(option)
      expect(screen.queryByText(errorText)).toBeNull()
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
      fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {
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
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option1 = await findByText(SECTIONS_DATA[0].name)
      await userEvent.click(option1)

      getByRole('button', {name: 'Save'}).click()
      expect((await findAllByText('Module access updated successfully.'))[0]).toBeInTheDocument()
      const requestBody = fetchMock.lastOptions(ASSIGNMENT_OVERRIDES_URL_PUT)?.body
      const expectedPayload = JSON.stringify({
        overrides: [{course_section_id: SECTIONS_DATA[0].id}],
      })
      expect(requestBody).toEqual(expectedPayload)
    })

    it.skip('updates existing assignment overrides', async () => {
      fetchMock.get(ASSIGNMENT_OVERRIDES_URL, ASSIGNMENT_OVERRIDES_DATA, {overwriteRoutes: true})
      const studentsOverride = ASSIGNMENT_OVERRIDES_DATA[0]
      const existingOverride = ASSIGNMENT_OVERRIDES_DATA[1]
      const {findByTestId, findByText, getByRole, findAllByText} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option1 = await findByText(existingOverride.course_section?.name!)
      // removing the existing section override
      await userEvent.click(option1)

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
      const {findByRole} = renderComponent()
      const updateButton = await findByRole('button', {name: 'Save'})
      await userEvent.click(updateButton)
      expect(utils.updateModuleUI).toHaveBeenCalled()
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
