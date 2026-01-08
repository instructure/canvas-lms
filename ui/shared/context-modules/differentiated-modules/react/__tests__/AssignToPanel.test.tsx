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
import {
  ASSIGNMENT_OVERRIDES_DATA,
  SECTIONS_DATA,
  STUDENTS_DATA,
  DIFFERENTIATION_TAGS_DATA,
} from './mocks'
import * as utils from '../../utils/assignToHelper'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import userEvent from '@testing-library/user-event'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

vi.mock('../../utils/assignToHelper', async () => {
  const originalModule = await vi.importActual('../../utils/assignToHelper')

  return {
    __esModule: true,
    ...originalModule,
    updateModuleUI: vi.fn(),
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

  let lastPutBody: unknown = null

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
    server.listen()
  })

  beforeEach(() => {
    lastPutBody = null
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
        return HttpResponse.json([])
      }),
      http.get(/\/api\/v1\/courses\/.+\/settings/, () => {
        return HttpResponse.json({hide_final_grades: false})
      }),
      http.put(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, async ({request}) => {
        lastPutBody = await request.json()
        return HttpResponse.json({})
      }),
      http.get(/\/api\/v1\/courses\/.+\/groups/, () => {
        return HttpResponse.json(DIFFERENTIATION_TAGS_DATA)
      }),
    )
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.removeQueries()
  })

  afterAll(() => {
    server.close()
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
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
        return HttpResponse.json(ASSIGNMENT_OVERRIDES_DATA)
      }),
    )
    const {findByTestId} = renderComponent()
    expect(await findByTestId('loading-overlay')).toBeInTheDocument()
    expect(await findByTestId('custom-option')).toBeChecked()
  })

  it('not render custom access as the default option if default option is called', async () => {
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
        return HttpResponse.json(ASSIGNMENT_OVERRIDES_DATA)
      }),
    )
    const {findByTestId} = renderComponent({defaultOption: 'everyone'})
    expect(await findByTestId('everyone-option')).toBeChecked()
  })

  it('calls updateParentData on unmount with changes', async () => {
    const updateParentDataMock = vi.fn()
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
    const updateParentDataMock = vi.fn()
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
      server.use(
        http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
          return HttpResponse.json(ASSIGNMENT_OVERRIDES_DATA)
        }),
      )
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

    it('can select a differentiation tag as an assignee', async () => {
      fakeENV.setup({
        ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS: true,
        CAN_MANAGE_DIFFERENTIATION_TAGS: true,
      })
      const {findByTestId, findByText, getAllByTestId} = renderComponent()
      const customOption = await findByTestId('custom-option')
      await userEvent.click(customOption)
      const assigneeSelector = await findByTestId('assignee_selector')
      await userEvent.click(assigneeSelector)
      const option = await findByText(DIFFERENTIATION_TAGS_DATA[0].name)
      await userEvent.click(option)
      expect(getAllByTestId('assignee_selector_selected_option')).toHaveLength(1)
      fakeENV.teardown()
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
      server.use(
        http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
          return HttpResponse.json(ASSIGNMENT_OVERRIDES_DATA)
        }),
      )
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
      const expectedPayload = {
        overrides: [{course_section_id: SECTIONS_DATA[0].id}],
      }
      expect(lastPutBody).toEqual(expectedPayload)
    })

    it('updates existing assignment overrides', async () => {
      server.use(
        http.get(/\/api\/v1\/courses\/.+\/modules\/.+\/assignment_overrides/, () => {
          return HttpResponse.json(ASSIGNMENT_OVERRIDES_DATA)
        }),
      )
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
      // it sends back the student list override, including the assignment override id
      const expectedPayload = {
        overrides: [
          {id: studentsOverride.id, student_ids: studentsOverride.students!.map(({id}) => id)},
        ],
      }
      expect(lastPutBody).toEqual(expectedPayload)
    })

    it('updates the modules UI', async () => {
      const {findByRole} = renderComponent()
      const updateButton = await findByRole('button', {name: 'Save'})
      await userEvent.click(updateButton)
      expect(utils.updateModuleUI).toHaveBeenCalled()
    })

    it('calls onDidSubmit instead of onDismiss if passed', async () => {
      const onDidSubmitMock = vi.fn()
      const onDismissMock = vi.fn()
      renderComponent({
        onDidSubmit: onDidSubmitMock,
        onDismiss: onDismissMock,
      })
      const customOption = await screen.findByTestId('custom-option')
      await userEvent.click(customOption)
      await userEvent.click(screen.getByTestId('assignee_selector'))
      await userEvent.click(screen.getByText(SECTIONS_DATA[0].name))
      await userEvent.click(screen.getByTestId('differentiated_modules_save_button'))
      expect(onDidSubmitMock).toHaveBeenCalled()
      expect(onDismissMock).not.toHaveBeenCalled()
    })
  })
})
