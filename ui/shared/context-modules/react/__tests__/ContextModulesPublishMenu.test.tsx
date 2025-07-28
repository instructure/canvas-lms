// @vitest-environment jsdom
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render, waitFor, fireEvent} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  updateModulePendingPublishedStates,
  batchUpdateAllModulesApiCall,
  fetchAllItemPublishedStates,
} from '../../utils/publishAllModulesHelper'
import {monitorProgress, cancelProgressAction} from '@canvas/progress/ProgressHelpers'

import ContextModulesPublishMenu from '../ContextModulesPublishMenu'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(() =>
    Promise.resolve({
      response: new Response('', {status: 200}),
      json: {
        workflow_state: 'completed',
        completion: 100,
      },
      text: '',
    }),
  ),
}))

jest.mock('@canvas/progress/ProgressHelpers', () => ({
  _esModule: true,
  monitorProgress: jest.fn(),
  cancelProgressAction: jest.fn(),
}))

jest.mock('../../utils/publishAllModulesHelper', () => ({
  __esModule: true,
  updateModulePendingPublishedStates: jest.fn(),
  batchUpdateAllModulesApiCall: jest.fn(),
  fetchAllItemPublishedStates: jest.fn(),
}))

const mockUpdateModulePendingPublishedStates = updateModulePendingPublishedStates as jest.Mock
const mockMonitorProgress = monitorProgress as jest.Mock
const mockBatchUpdateAllModulesApiCall = batchUpdateAllModulesApiCall as jest.Mock
const mockCancelProgressAction = cancelProgressAction as jest.Mock
const mockFetchAllItemPublishedStates = fetchAllItemPublishedStates as jest.Mock

const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

const defaultProps = {
  courseId: '1',
  runningProgressId: null,
  disabled: false,
}

describe('ContextModulesPublishMenu', () => {
  beforeEach(() => {
    mockDoFetchApi.mockReset()
    mockUpdateModulePendingPublishedStates.mockReset()
    mockMonitorProgress.mockReset()
    mockBatchUpdateAllModulesApiCall.mockReset()
    mockCancelProgressAction.mockReset()
    mockFetchAllItemPublishedStates.mockReset()
    mockDoFetchApi.mockImplementation(() =>
      Promise.resolve({
        response: new Response('', {status: 200}),
        json: {
          workflow_state: 'completed',
          completion: 100,
        },
        text: '',
      }),
    )
    mockUpdateModulePendingPublishedStates.mockImplementation(() => {})
    mockMonitorProgress.mockImplementation(() => {})
    mockBatchUpdateAllModulesApiCall.mockImplementation(() => {})
    mockCancelProgressAction.mockImplementation(() => {})
    mockFetchAllItemPublishedStates.mockImplementation(() => {})
  })

  afterEach(() => {
    mockDoFetchApi.mockReset()
    mockUpdateModulePendingPublishedStates.mockReset()
    mockMonitorProgress.mockReset()
    mockBatchUpdateAllModulesApiCall.mockReset()
    mockCancelProgressAction.mockReset()
    mockFetchAllItemPublishedStates.mockReset()
    document.body.innerHTML = ''
  })

  describe('basic rendering', () => {
    it('renders', () => {
      const {container, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
      expect(getByText('Publish All')).toBeInTheDocument()
      expect(container.querySelector('[name="IconPublish"]')).toBeInTheDocument()
    })

    it('is disabled when disabled prop is true', () => {
      const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} disabled={true} />)
      const menuButton = getByRole('button')
      expect(menuButton).toBeDisabled()
    })

    it('renders a spinner when publish is in-flight', () => {
      // Mock the progress API call
      ;(doFetchApi as jest.Mock).mockImplementation(() =>
        Promise.resolve({
          response: new Response('', {status: 200}),
          json: {
            id: '17',
            workflow_state: 'running',
            completion: 50,
          },
          text: '',
        }),
      )

      const {getByText} = render(
        <ContextModulesPublishMenu {...defaultProps} runningProgressId="17" />,
      )
      expect(getByText('Loading')).toBeInTheDocument()
    })

    it('updates all the modules when ready', async () => {
      // Mock the progress API call
      ;(doFetchApi as jest.Mock).mockImplementation(() =>
        Promise.resolve({
          response: new Response('', {status: 200}),
          json: {
            id: '17',
            workflow_state: 'completed',
            completion: 100,
          },
          text: '',
        }),
      )

      render(<ContextModulesPublishMenu {...defaultProps} runningProgressId="17" />)
      expect(mockUpdateModulePendingPublishedStates).not.toHaveBeenCalled()
      window.dispatchEvent(new Event('module-publish-models-ready'))
      await waitFor(() => {
        expect(mockUpdateModulePendingPublishedStates).toHaveBeenCalled()
      })
    })

    describe('progress', () => {
      let mockMonitorProgress: jest.Mock
      let mockBatchUpdateAllModulesApiCall: jest.Mock

      beforeEach(() => {
        mockMonitorProgress = monitorProgress as jest.Mock
        mockBatchUpdateAllModulesApiCall = batchUpdateAllModulesApiCall as jest.Mock
        mockBatchUpdateAllModulesApiCall.mockImplementation(() =>
          Promise.resolve({
            json: {
              progress: {
                progress: {
                  id: '17',
                  workflow_state: 'running',
                  completion: 0,
                },
              },
            },
          }),
        )
      })

      it('renders a screenreader message with progress starts', async () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        act(() => {
          continueButton.click()
        })

        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'running',
            completion: 0,
          })
        })

        // Wait for the alert to be added to the DOM
        await waitFor(() => {
          expect(document.querySelector('[role="alert"]')).toHaveTextContent(
            'Publishing modules has started.',
          )
        })
      })

      it('renders a screenreader message with progress updates', async () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        act(() => {
          continueButton.click()
        })

        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'running',
            completion: 50,
          })
        })

        // Wait for the alert to be added to the DOM
        await waitFor(() => {
          expect(document.querySelector('[role="alert"]')).toHaveTextContent(
            'Publishing progress is 50 percent complete',
          )
        })
      })

      it('renders a screenreader message when progress completes', async () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        act(() => {
          continueButton.click()
        })

        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'completed',
            completion: 100,
          })
        })

        // Wait for the alert to be added to the DOM
        await waitFor(() => {
          expect(document.querySelector('[role="alert"]')).toHaveTextContent(
            'Publishing progress is complete. Refreshing item status.',
          )
        })
      })

      it('renders message when publishing was canceled', async () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        act(() => {
          continueButton.click()
        })

        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'failed',
            message: 'canceled',
            completion: 0,
          })
        })

        // Wait for the alert to be added to the DOM
        await waitFor(() => {
          expect(document.querySelector('[role="alert"]')).toHaveTextContent(
            'Your publishing job was canceled before it completed.',
          )
        })
      })
    })

    describe('menu actions', () => {
      it('renders the menu when clicked', () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
        const menuButton = getByRole('button')
        act(() => menuButton.click())
        expect(getByText('Publish all modules and items')).toBeInTheDocument()
        expect(getByText('Publish modules only')).toBeInTheDocument()
        expect(getByText('Unpublish all modules and items')).toBeInTheDocument()
        expect(getByText('Unpublish modules only')).toBeInTheDocument()
      })

      it('calls publishAll when clicked publish all menu item is clicked', () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
        const menuButton = getByRole('button')
        act(() => menuButton.click())
        const publishButton = getByText('Publish all modules and items')
        act(() => publishButton.click())
        const modalTitle = getByRole('heading', {name: 'Publish all modules and items'})
        expect(modalTitle).toBeInTheDocument()
      })

      it('calls publishModuleOnly when clicked publish module menu item is clicked', () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
        const menuButton = getByRole('button')
        act(() => menuButton.click())
        const publishButton = getByText('Publish modules only')
        act(() => publishButton.click())
        const modalTitle = getByRole('heading', {name: 'Publish modules only'})
        expect(modalTitle).toBeInTheDocument()
      })

      it('calls unpublishAll when clicked unpublish all items is clicked', () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
        const menuButton = getByRole('button')
        act(() => menuButton.click())
        const publishButton = getByText('Unpublish all modules and items')
        act(() => publishButton.click())
        const modalTitle = getByRole('heading', {name: 'Unpublish all modules and items'})
        expect(modalTitle).toBeInTheDocument()
      })

      it('calls unpublishModuleOnly when unpublish modules only is clicked', () => {
        const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
        const menuButton = getByRole('button')
        act(() => menuButton.click())
        const publishButton = getByText('Unpublish modules only')
        act(() => publishButton.click())
        const modalTitle = getByRole('heading', {name: 'Unpublish modules only'})
        expect(modalTitle).toBeInTheDocument()
      })
    })

    describe('Modal actions', () => {
      it('closes the modal when stopping an action', async () => {
        mockBatchUpdateAllModulesApiCall.mockImplementation(() =>
          Promise.resolve({
            json: {
              progress: {
                progress: {
                  id: '17',
                  workflow_state: 'running',
                  completion: 0,
                },
              },
            },
          }),
        )
        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'running',
            completion: 50,
          })
        })
        mockFetchAllItemPublishedStates.mockImplementation(() => Promise.resolve())

        const {getByRole, getByTestId} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Click continue in modal
        const continueButton = getByRole('button', {name: /Continue/})
        await act(async () => {
          continueButton.click()
        })

        // Click stop in modal
        const stopButton = getByTestId('publish-button')
        await act(async () => {
          stopButton.click()
        })

        await waitFor(() => {
          expect(mockBatchUpdateAllModulesApiCall).toHaveBeenCalledWith('1', true, false)
          expect(mockMonitorProgress).toHaveBeenCalled()
        })
      })
    })

    describe('error handling', () => {
      it('shows alert on successful publish', async () => {
        mockBatchUpdateAllModulesApiCall.mockImplementation(() =>
          Promise.resolve({
            json: {
              progress: {
                progress: {
                  id: '17',
                  workflow_state: 'completed',
                  completion: 100,
                },
              },
            },
          }),
        )
        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'completed',
            completion: 100,
          })
        })
        mockFetchAllItemPublishedStates.mockImplementation(() => Promise.resolve())

        const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Click continue in modal
        const continueButton = getByRole('button', {name: /Continue/})
        await act(async () => {
          continueButton.click()
        })

        await waitFor(() => {
          expect(mockBatchUpdateAllModulesApiCall).toHaveBeenCalledWith('1', true, false)
          expect(mockFetchAllItemPublishedStates).toHaveBeenCalled()
          expect(mockMonitorProgress).toHaveBeenCalled()
        })
      })

      it('shows alert on failed publish', async () => {
        mockBatchUpdateAllModulesApiCall.mockRejectedValue(new Error('Failed to publish'))
        mockFetchAllItemPublishedStates.mockImplementation(() => Promise.resolve())

        const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        await act(async () => {
          continueButton.click()
        })

        await waitFor(() => {
          expect(mockBatchUpdateAllModulesApiCall).toHaveBeenCalled()
        })
      })

      it('shows alert on failed poll for progress', async () => {
        mockBatchUpdateAllModulesApiCall.mockImplementation(() =>
          Promise.resolve({
            json: {
              progress: {
                progress: {
                  id: '17',
                  workflow_state: 'running',
                  completion: 0,
                },
              },
            },
          }),
        )
        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'failed',
            completion: 0,
          })
        })
        mockFetchAllItemPublishedStates.mockImplementation(() => Promise.resolve())

        const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        await act(async () => {
          continueButton.click()
        })

        await waitFor(() => {
          expect(mockMonitorProgress).toHaveBeenCalled()
          expect(mockFetchAllItemPublishedStates).toHaveBeenCalled()
        })
      })

      it('shows alert when failing to update results', async () => {
        mockBatchUpdateAllModulesApiCall.mockImplementation(() =>
          Promise.resolve({
            json: {
              progress: {
                progress: {
                  id: '17',
                  workflow_state: 'running',
                  completion: 0,
                },
              },
            },
          }),
        )
        mockMonitorProgress.mockImplementation((id, callback) => {
          callback({
            workflow_state: 'completed',
            completion: 100,
          })
        })
        mockFetchAllItemPublishedStates.mockRejectedValue(new Error('Failed to fetch states'))

        const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} />)

        // Open menu
        const menuButton = getByRole('button')
        act(() => {
          menuButton.click()
        })

        // Click "Publish all modules and items"
        const publishAllButton = getByRole('menuitem', {name: /Publish all modules and items/})
        await act(async () => {
          publishAllButton.click()
        })

        // Set state variables before clicking continue
        const continueButton = getByRole('button', {name: /Continue/})
        await act(async () => {
          continueButton.click()
        })

        await waitFor(() => {
          expect(mockFetchAllItemPublishedStates).toHaveBeenCalled()
        })
      })
    })
  })
})
