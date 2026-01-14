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
import {render, waitFor} from '@testing-library/react'
import SettingsPanel, {type SettingsPanelProps} from '../SettingsPanel'
import * as miscUtils from '../../utils/miscHelpers'
import * as moduleUtils from '../../utils/moduleHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

vi.mock('../../utils/miscHelpers', async () => {
  const originalModule = await vi.importActual('../../utils/miscHelpers') as any

  return {
    __esModule: true,
    ...originalModule,
    convertModuleSettingsForApi: vi
      .fn()
      .mockImplementation(originalModule.convertModuleSettingsForApi),
  }
})

vi.mock('../../utils/moduleHelpers', async () => {
  const originalModule = await vi.importActual('../../utils/moduleHelpers') as any

  return {
    __esModule: true,
    ...originalModule,
    updateModuleUI: vi.fn(),
  }
})

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(() => vi.fn(() => {})),
}))

describe('SettingsPanel', () => {
  // Track captured request for verification
  let lastCapturedRequest: {path: string; method: string; body?: any} | null = null

  beforeAll(() => {
    server.listen()
    // GMT-7
    window.ENV.TIMEZONE = 'America/Denver'
  })

  afterAll(() => server.close())

  const props: SettingsPanelProps = {
    moduleElement: document.createElement('div'),
    moduleId: '1',
    moduleName: 'Week 1',
    unlockAt: '',
    bodyHeight: '400px',
    footerHeight: '100px',
    onDismiss: () => {},
    addModuleUI: () => {},
    mountNodeRef: {current: null},
  }

  const renderComponent = (overrides = {}) => render(<SettingsPanel {...props} {...overrides} />)

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Module Name')).toBeInTheDocument()
  })

  it('renders the module name', () => {
    const {getByDisplayValue} = renderComponent()
    const nameInput = getByDisplayValue('Week 1')
    expect(nameInput).toBeInTheDocument()
    expect(nameInput).toBeRequired()
  })

  it('renders the date time input when lock until is checked', () => {
    const {getByRole, getByText} = renderComponent()
    getByRole('checkbox').click()
    expect(getByText('Date')).toBeInTheDocument()
  })

  it('renders the date time input when unlockAt is set', () => {
    const {getByText, getAllByText, getByDisplayValue} = renderComponent({
      unlockAt: '2020-01-01T00:00:00Z',
    })
    expect(getByText('Date')).toBeInTheDocument()
    expect(getByText('Time')).toBeInTheDocument()
    expect(getByDisplayValue('December 31, 2019')).toBeInTheDocument()
    expect(getByDisplayValue('5:00 PM')).toBeInTheDocument()
    expect(getAllByText('Tuesday, December 31, 2019 5:00 PM')[0]).toBeInTheDocument()
  })

  it('renders the date time input when unlockAt is set and lockUntilChecked is true', () => {
    const {getByText, getAllByText, getByDisplayValue} = renderComponent({
      lockUntilChecked: true,
      unlockAt: '2020-01-01T00:00:00Z',
    })
    expect(getByText('Date')).toBeInTheDocument()
    expect(getByText('Time')).toBeInTheDocument()
    expect(getByDisplayValue('December 31, 2019')).toBeInTheDocument()
    expect(getByDisplayValue('5:00 PM')).toBeInTheDocument()
    expect(getAllByText('Tuesday, December 31, 2019 5:00 PM')[0]).toBeInTheDocument()
  })

  it('does not render the date time input when unlockAt is set and lockUntilChecked is false', () => {
    const {queryByText} = renderComponent({
      lockUntilChecked: false,
      unlockAt: '2020-01-01T00:00:00Z',
    })
    expect(queryByText('Date')).not.toBeInTheDocument()
  })

  it('does not render prerequisites when there are no modules available', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('prerequisite-form')).not.toBeInTheDocument()
  })

  it('renders prerequisite when there are modules available', () => {
    const {getByTestId} = renderComponent({
      moduleList: [
        {id: '0', name: 'Week 0'},
        {id: '1', name: 'Week 1'},
      ],
    })
    expect(getByTestId('prerequisite-form')).toBeInTheDocument()
  })

  it('does not render requirements when there are no module items', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('requirement-form')).not.toBeInTheDocument()
  })

  it('renders requirements when there are moduleItems', () => {
    const {getByTestId} = renderComponent({
      moduleItems: [{id: '0', name: 'Page 0', type: 'page'}],
    })
    expect(getByTestId('requirement-form')).toBeInTheDocument()
  })

  it('does not render publish final grade if not enabled', () => {
    const {queryByRole} = renderComponent()
    expect(queryByRole('checkbox', {name: /Publish final grade/})).not.toBeInTheDocument()
  })

  it('renders publish final grade if enabled', () => {
    const {getByRole} = renderComponent({enablePublishFinalGrade: true})
    expect(getByRole('checkbox', {name: /Publish final grade/})).toBeInTheDocument()
  })

  it('calls updateParentData on unmount with changes', async () => {
    const updateParentDataMock = vi.fn()
    const {unmount, findByTestId} = renderComponent({updateParentData: updateParentDataMock})
    await userEvent.type(await findByTestId('module-name-input'), '2')
    unmount()
    expect(updateParentDataMock).toHaveBeenCalledWith(
      {
        lockUntilChecked: false,
        moduleName: 'Week 12',
        moduleNameDirty: true,
        nameInputMessages: [],
        lockUntilInputMessages: [],
        prerequisites: [],
        publishFinalGrade: false,
        requireSequentialProgress: false,
        requirementCount: 'all',
        requirements: [],
        unlockAt: '',
        pointsInputMessages: [],
      },
      true,
    )
  })

  it('calls updateParentData on unmount with no changes', () => {
    const updateParentDataMock = vi.fn()
    const {unmount} = renderComponent({updateParentData: updateParentDataMock})
    unmount()
    expect(updateParentDataMock).toHaveBeenCalledWith(
      {
        lockUntilChecked: false,
        moduleName: 'Week 1',
        moduleNameDirty: false,
        nameInputMessages: [],
        lockUntilInputMessages: [],
        prerequisites: [],
        publishFinalGrade: false,
        requireSequentialProgress: false,
        requirementCount: 'all',
        requirements: [],
        unlockAt: '',
        pointsInputMessages: [],
      },
      false,
    )
  })

  describe('on update', () => {
    beforeAll(() => {
      window.ENV.COURSE_ID = '1'
    })

    beforeEach(() => {
      vi.clearAllMocks()
      lastCapturedRequest = null
      // Default success handler
      server.use(
        http.put('/courses/:courseId/modules/:moduleId', async ({request}) => {
          lastCapturedRequest = {
            path: new URL(request.url).pathname,
            method: 'PUT',
            body: await request.json(),
          }
          return HttpResponse.json({})
        }),
        http.post('/courses/:courseId/modules', async ({request}) => {
          lastCapturedRequest = {
            path: new URL(request.url).pathname,
            method: 'POST',
            body: await request.json(),
          }
          return HttpResponse.json({})
        }),
      )
    })

    afterEach(() => server.resetHandlers())

    it('validates the module name', () => {
      const {getByRole, getByText, getByTestId} = renderComponent({moduleName: ''})
      const updateButton = getByRole('button', {name: 'Save'})
      const nameInput = getByTestId('module-name-input')

      updateButton.click()
      expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
      expect(getByText('Module name can’t be blank')).toBeInTheDocument()
      expect(nameInput).toHaveFocus()
    })

    it('makes a request to the modules update endpoint', async () => {
      const {getByRole, findByTestId} = renderComponent()
      getByRole('button', {name: 'Save'}).click()
      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      await waitFor(() => {
        expect(lastCapturedRequest).not.toBeNull()
        expect(lastCapturedRequest!.path).toBe('/courses/1/modules/1')
        expect(lastCapturedRequest!.method).toBe('PUT')
        expect(lastCapturedRequest!.body).toBeDefined()
      })
    })

    it('formats the form state for the request body', async () => {
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Save'}).click()
      await waitFor(() => {
        expect(miscUtils.convertModuleSettingsForApi).toHaveBeenCalled()
      })
    })

    it('updates the modules page UI', async () => {
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Save'}).click()
      await waitFor(() => {
        expect(moduleUtils.updateModuleUI).toHaveBeenCalled()
      })
    })

    it('shows a flash alert on success', async () => {
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Save'}).click()
      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          type: 'success',
          message: 'Week 1 settings updated successfully.',
          politeness: 'polite',
        })
      })
    })

    it('shows a flash alert on failure', async () => {
      server.use(
        http.put('/courses/:courseId/modules/:moduleId', () => HttpResponse.error()),
      )
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Save'}).click()
      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          err: expect.any(Error),
          message: 'Error updating Week 1 settings.',
        })
      })
    })

    it('calls onDidSubmit instead of onDismiss if passed', async () => {
      const onDidSubmitMock = vi.fn()
      const onDismissMock = vi.fn()
      const {getByRole, findByTestId} = renderComponent({
        onDidSubmit: onDidSubmitMock,
        onDismiss: onDismissMock,
      })
      await userEvent.click(getByRole('button', {name: 'Save'}))

      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      await waitFor(() => {
        expect(onDidSubmitMock).toHaveBeenCalled()
      })
      expect(onDismissMock).not.toHaveBeenCalled()
    })

    it('calls updateParentData with moduleNameDirty state', async () => {
      const updateParentDataMock = vi.fn()
      const {unmount, findByTestId} = renderComponent({updateParentData: updateParentDataMock})
      await userEvent.type(await findByTestId('module-name-input'), '2')
      unmount()
      expect(updateParentDataMock).toHaveBeenCalledWith(
        {
          lockUntilChecked: false,
          moduleName: 'Week 12',
          moduleNameDirty: true,
          nameInputMessages: [],
          lockUntilInputMessages: [],
          prerequisites: [],
          publishFinalGrade: false,
          requireSequentialProgress: false,
          requirementCount: 'all',
          requirements: [],
          unlockAt: '',
          pointsInputMessages: [],
        },
        true,
      )
    })
    describe('modules_requirements_allow_percentage is enabled', () => {
      beforeAll(() => {
        window.ENV.FEATURES ||= {}
        window.ENV.FEATURES.modules_requirements_allow_percentage = true
      })

      it('Invalid input message is shown for points', () => {
        const overrideProps = {
          moduleItems: [{id: '1', name: 'Assignments'}],
          requirements: [
            {
              id: '1',
              name: 'Assignment 1',
              resource: 'assignment',
              type: 'percentage',
              minimumScore: '150',
              pointsPossible: '30',
            },
          ],
          pointsInputMessages: [{requirementId: '1', message: 'Invalid input'}],
        }
        const {getByRole, getByText} = renderComponent(overrideProps)
        const updateButton = getByRole('button', {name: 'Save'})
        updateButton.click()

        expect(getByText('Invalid input')).toBeInTheDocument()
      })

      it('addModuleUI is not called if error in requirements', () => {
        const addModuleUI = vi.fn()

        const overrideProps = {
          moduleItems: [{id: '1', name: 'Assignments'}],
          requirements: [
            {
              id: '1',
              name: 'Assignment 1',
              resource: 'assignment',
              type: 'percentage',
              minimumScore: '150',
              pointsPossible: '30',
            },
          ],
          pointsInputMessages: [{requirementId: '1', message: 'Invalid input'}],
          addModuleUI,
        }
        const {getByRole} = renderComponent(overrideProps)
        const updateButton = getByRole('button', {name: 'Save'})
        updateButton.click()

        expect(addModuleUI).not.toHaveBeenCalled()
      })
    })
  })

  describe('on create', () => {
    beforeEach(() => {
      vi.clearAllMocks()
      // Set up handler for module creation
      server.use(
        http.post('/courses/:courseId/modules', async ({request}) => {
          return HttpResponse.json({})
        }),
      )
    })

    afterEach(() => server.resetHandlers())

    it('calls addModuleUI when module is created', async () => {
      const addModuleUI = vi.fn()
      const {getByRole, findByTestId} = renderComponent({moduleId: undefined, addModuleUI})
      getByRole('button', {name: 'Add Module'}).click()
      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      await waitFor(() => {
        expect(showFlashAlert).toHaveBeenCalledWith({
          type: 'success',
          message: 'Week 1 created successfully.',
          politeness: 'polite',
        })
        expect(addModuleUI).toHaveBeenCalled()
      })
    })

    it('calls onDidSubmit instead of onDismiss if passed', async () => {
      const onDidSubmitMock = vi.fn()
      const onDismissMock = vi.fn()
      const {getByRole, findByTestId} = renderComponent({
        moduleId: undefined,
        onDidSubmit: onDidSubmitMock,
        onDismiss: onDismissMock,
      })
      await userEvent.click(getByRole('button', {name: 'Add Module'}))

      expect(await findByTestId('loading-overlay')).toBeInTheDocument()
      await waitFor(() => {
        expect(onDidSubmitMock).toHaveBeenCalled()
      })
      expect(onDismissMock).not.toHaveBeenCalled()
    })
  })
})
