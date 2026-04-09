/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {screen, waitFor, fireEvent} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {useNavigate, unstable_usePrompt} from 'react-router-dom'
import {ToolConfigurationJsonEditor} from '../ToolConfigurationJsonEditor'
import {renderApp} from './helpers'
import {mockRegistrationWithAllInformation} from '../../../manage/__tests__/helpers'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: vi.fn(),
    unstable_usePrompt: vi.fn(),
  }
})

const server = setupServer()

describe('ToolConfigurationJsonEditor', () => {
  let mockNavigate: ReturnType<typeof vi.fn>
  let mockUsePrompt: ReturnType<typeof vi.fn>

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    mockNavigate = vi.fn()
    mockUsePrompt = vi.fn()
    vi.mocked(useNavigate).mockReturnValue(mockNavigate)
    vi.mocked(unstable_usePrompt).mockImplementation(mockUsePrompt)
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders the JSON editor with initial configuration', () => {
      const {getByText, getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          title: 'Test App',
          target_link_uri: 'https://example.com',
          scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
        },
      })(<ToolConfigurationJsonEditor />)

      expect(getByText('Edit as JSON')).toBeInTheDocument()
      expect(getByText(/Use the JSON editor for advanced configurations/)).toBeInTheDocument()
      expect(getByText('View LTI Configuration Documentation')).toBeInTheDocument()

      const textarea = getByLabelText('JSON Configuration') as HTMLTextAreaElement
      const parsedValue = JSON.parse(textarea.value)
      expect(parsedValue.title).toBe('Test App')
      expect(parsedValue.target_link_uri).toBe('https://example.com')
    })

    it('renders Cancel and Update buttons', () => {
      const {getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      expect(getByText('Cancel')).toBeInTheDocument()
      expect(getByText('Update Configuration')).toBeInTheDocument()
    })

    it('renders documentation link with correct attributes', () => {
      const {getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const link = getByText('View LTI Configuration Documentation')
      expect(link).toHaveAttribute('href', '/doc/api/file.lti_dev_key_config.html')
      expect(link).toHaveAttribute('target', '_blank')
      expect(link).toHaveAttribute('rel', 'noopener noreferrer')
    })
  })

  describe('editing JSON', () => {
    it('updates the JSON value when typing', async () => {
      const user = userEvent.setup()
      const {getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          title: 'Test App',
        },
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration') as HTMLTextAreaElement
      await user.clear(textarea)
      await user.type(textarea, '{{"title": "Updated App"}')

      expect(textarea.value).toContain('Updated App')
    })

    it('marks the form as dirty when JSON is modified', async () => {
      const user = userEvent.setup()
      const {getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          title: 'Test App',
        },
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration') as HTMLTextAreaElement
      const initialValue = textarea.value

      await user.clear(textarea)
      await user.type(textarea, '{{"title": "Updated"}')

      // After modification, unstable_usePrompt should be called with when: true
      await waitFor(() => {
        const calls = mockUsePrompt.mock.calls
        const latestCall = calls[calls.length - 1]
        expect(latestCall?.[0]?.when).toBe(true)
      })
    })

    it('does not mark form as dirty when JSON matches initial value', async () => {
      const user = userEvent.setup()
      const {getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          title: 'Test App',
        },
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration') as HTMLTextAreaElement
      const initialValue = textarea.value

      // Type something
      await user.type(textarea, 'x')
      // Delete it to return to initial state
      await user.type(textarea, '{Backspace}')

      await waitFor(() => {
        const calls = mockUsePrompt.mock.calls
        const latestCall = calls[calls.length - 1]
        expect(latestCall?.[0]?.when).toBe(false)
      })
    })
  })

  describe('JSON validation', () => {
    it('shows validation error for invalid JSON on blur', async () => {
      const user = userEvent.setup()
      const {getByLabelText, findByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('invalid json')
      fireEvent.blur(textarea) // Trigger blur directly

      expect(await findByText(/Invalid JSON/, {exact: false}, {timeout: 3000})).toBeInTheDocument()
    })

    it('clears validation error when user starts typing', async () => {
      const user = userEvent.setup()
      const {getByLabelText, queryByText, findByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('invalid')
      fireEvent.blur(textarea) // Trigger blur directly

      await findByText(/Invalid JSON/, {exact: false}, {timeout: 3000})

      // Start typing again
      await user.type(textarea, 'x')

      await waitFor(() => {
        expect(queryByText(/Unexpected token|Invalid JSON/, {exact: false})).not.toBeInTheDocument()
      })
    })

    it('does not show validation error for valid JSON', async () => {
      const user = userEvent.setup()
      const {getByLabelText, queryByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Valid"}')
      fireEvent.blur(textarea) // Trigger blur directly

      await waitFor(() => {
        expect(queryByText(/Unexpected token|Invalid JSON/, {exact: false})).not.toBeInTheDocument()
      })
    })

    it('disables Update button when validation error exists', async () => {
      const user = userEvent.setup()
      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('invalid')
      fireEvent.blur(textarea) // Trigger blur directly

      await waitFor(() => {
        const updateButton = getByText('Update Configuration').closest('button')!
        expect(updateButton).toHaveAttribute('disabled')
      })
    })
  })

  describe('save functionality', () => {
    it('saves valid JSON and shows success message', async () => {
      const user = userEvent.setup()
      server.use(
        http.put('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(
            mockRegistrationWithAllInformation({
              n: 'Updated App',
              i: 1,
            }),
          )
        }),
      )

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          title: 'Test App',
        },
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated App"}')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      await waitFor(() => {
        expect(
          screen.queryAllByText('Configuration has been saved successfully.').length,
        ).toBeGreaterThan(0)
      })
    })

    it('navigates back to configuration view after successful save', async () => {
      const user = userEvent.setup()
      server.use(
        http.put('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(
            mockRegistrationWithAllInformation({
              n: 'Updated App',
              i: 1,
            }),
          )
        }),
      )

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated"}')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      await waitFor(
        () => {
          expect(mockNavigate).toHaveBeenCalledWith('/manage/1/configuration', {replace: true})
        },
        {timeout: 3000},
      )
    })

    it('shows error message when save fails', async () => {
      const user = userEvent.setup()
      server.use(
        http.put('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json({errors: [{message: 'Save failed'}]}, {status: 500})
        }),
      )

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated"}')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      await waitFor(() => {
        // doFetchApi throws an error with this message when the response is not ok
        expect(
          screen.queryAllByText(/bad response|error occurred while updating/i).length,
        ).toBeGreaterThan(0)
      })
    })

    it('does not save when JSON is invalid', async () => {
      const user = userEvent.setup()

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('invalid json')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      // Should not navigate or call API
      await waitFor(() => {
        expect(mockNavigate).not.toHaveBeenCalled()
      })
    })

    it('disables Update button while save is pending', async () => {
      const user = userEvent.setup()
      let resolveRequest: (value: any) => void
      const requestPromise = new Promise(resolve => {
        resolveRequest = resolve
      })

      server.use(
        http.put('/api/v1/accounts/:accountId/lti_registrations/:registrationId', async () => {
          await requestPromise
          return HttpResponse.json(
            mockRegistrationWithAllInformation({
              n: 'Updated App',
              i: 1,
            }),
          )
        }),
      )

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated"}')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      // Button should be disabled while pending
      await waitFor(() => {
        expect(updateButton).toHaveAttribute('disabled')
      })

      // Resolve the request
      resolveRequest!(null)
    })
  })

  describe('cancel functionality', () => {
    it('navigates back to configuration view when Cancel is clicked', async () => {
      const user = userEvent.setup()
      const {getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const cancelButton = getByText('Cancel').closest('button')!
      await user.click(cancelButton)

      expect(mockNavigate).toHaveBeenCalledWith('/manage/1/configuration', {replace: true})
    })

    it('does not save changes when Cancel is clicked', async () => {
      const user = userEvent.setup()
      const mutateSpy = vi.fn()

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated"}')

      const cancelButton = getByText('Cancel').closest('button')!
      await user.click(cancelButton)

      expect(mockNavigate).toHaveBeenCalledWith('/manage/1/configuration', {replace: true})
    })
  })

  describe('navigation blocking', () => {
    it('prompts user when navigating away with unsaved changes', async () => {
      const user = userEvent.setup()
      const {getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.type(textarea, 'x')

      await waitFor(() => {
        const calls = mockUsePrompt.mock.calls
        const latestCall = calls[calls.length - 1]
        expect(latestCall?.[0]?.message).toBe(
          'You have unsaved changes. Are you sure you want to leave?',
        )
        expect(latestCall?.[0]?.when).toBe(true)
      })
    })

    it('does not prompt when there are no unsaved changes', async () => {
      renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      await waitFor(() => {
        const calls = mockUsePrompt.mock.calls
        const latestCall = calls[calls.length - 1]
        expect(latestCall?.[0]?.when).toBe(false)
      })
    })

    it('sets up beforeunload event listener', () => {
      const addEventListenerSpy = vi.spyOn(window, 'addEventListener')
      const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener')

      const {unmount} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      expect(addEventListenerSpy).toHaveBeenCalledWith('beforeunload', expect.any(Function))

      unmount()

      expect(removeEventListenerSpy).toHaveBeenCalledWith('beforeunload', expect.any(Function))

      addEventListenerSpy.mockRestore()
      removeEventListenerSpy.mockRestore()
    })

    it('removes beforeunload listener after successful save', async () => {
      const user = userEvent.setup()
      const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener')

      server.use(
        http.put('/api/v1/accounts/:accountId/lti_registrations/:registrationId', () => {
          return HttpResponse.json(
            mockRegistrationWithAllInformation({
              n: 'Updated App',
              i: 1,
            }),
          )
        }),
      )

      const {getByLabelText, getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      await user.clear(textarea)
      await user.click(textarea)
      await user.paste('{"title": "Updated"}')

      const updateButton = getByText('Update Configuration').closest('button')!
      await user.click(updateButton)

      await waitFor(() => {
        expect(removeEventListenerSpy).toHaveBeenCalledWith('beforeunload', expect.any(Function))
      })

      removeEventListenerSpy.mockRestore()
    })
  })

  describe('data-pendo attributes', () => {
    it('has correct data-pendo attribute on textarea', () => {
      const {getByLabelText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const textarea = getByLabelText('JSON Configuration')
      expect(textarea).toHaveAttribute('data-pendo', 'lti-registrations-json-editor-textarea')
    })

    it('has correct data-pendo attribute on Cancel button', () => {
      const {container} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const cancelButton = container.querySelector('[data-pendo="lti-registrations-json-cancel"]')
      expect(cancelButton).toBeInTheDocument()
    })

    it('has correct data-pendo attribute on Update button', () => {
      const {container} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const updateButton = container.querySelector('[data-pendo="lti-registrations-json-update"]')
      expect(updateButton).toBeInTheDocument()
    })

    it('has correct data-pendo attribute on documentation link', () => {
      const {getByText} = renderApp({
        n: 'Test App',
        i: 1,
      })(<ToolConfigurationJsonEditor />)

      const link = getByText('View LTI Configuration Documentation')
      expect(link).toHaveAttribute('data-pendo', 'lti-registrations-json-docs-link')
    })
  })
})
