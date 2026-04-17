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

import {render, waitFor} from '@testing-library/react'
import * as RegistrationsApi from '../../../api/registrations'
import {clickOrFail} from '../../__tests__/interactionHelpers'
import {ToolDetailsInner} from '../ToolDetails'
import {
  mockRegistrationWithAllInformation,
  mockSiteAdminRegistration,
} from '../../manage/__tests__/helpers'
import {BrowserRouter} from 'react-router-dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ZDeveloperKeyId} from '../../../model/developer_key/DeveloperKeyId'
import {ZAccountId} from '../../../model/AccountId'
import fakeENV from '@canvas/test-utils/fakeENV'
import {fireEvent, screen} from '@testing-library/dom'
import {ZLtiRegistrationId} from '../../../model/LtiRegistrationId'
import {showFlashAlert} from '@instructure/platform-alerts'
import {LtiRegistration} from '../../../model/LtiRegistration'

vi.mock('@instructure/platform-alerts', () => ({
  showFlashAlert: vi.fn(),
}))

const mockFlash = showFlashAlert as ReturnType<typeof vi.fn>

const server = setupServer()

describe('ToolDetailsInner', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  beforeEach(() => {
    mockFlash.mockClear()
  })

  const renderToolDetailsInner = (
    registration = mockRegistrationWithAllInformation({n: 'test', i: 1}),
  ) => {
    return render(
      <BrowserRouter>
        <QueryClientProvider client={new QueryClient()}>
          <ToolDetailsInner registration={registration} accountId={registration.account_id} />
        </QueryClientProvider>
      </BrowserRouter>,
    )
  }

  it('renders Delete and Copy Client ID buttons', async () => {
    const wrapper = renderToolDetailsInner()

    expect(wrapper.queryByText('Copy Client ID')).toBeInTheDocument()
    expect(wrapper.queryByText('Delete App')).toBeInTheDocument()
  })

  it('calls the delete API endpoint when the delete button is clicked', async () => {
    let capturedUrl = ''
    let capturedMethod = ''
    server.use(
      http.delete('/api/v1/accounts/:accountId/lti_registrations/:registrationId', ({request}) => {
        capturedUrl = request.url
        capturedMethod = request.method
        return HttpResponse.json({
          __type: 'Success',
          data: {},
        })
      }),
    )

    const wrapper = renderToolDetailsInner()
    const deleteBtn = await wrapper.getByText('Delete App').closest('button')
    await clickOrFail(deleteBtn)
    const confirmationModalAcceptBtn = await wrapper.getByText('Delete').closest('button')
    await clickOrFail(confirmationModalAcceptBtn)

    expect(capturedUrl).toContain('/api/v1/accounts/1/lti_registrations/1')
    expect(capturedMethod).toBe('DELETE')
  })

  it('shows the delete button on a site admin registration', async () => {
    const wrapper = renderToolDetailsInner()
    const deleteButton = wrapper.getByTestId('delete-app')
    expect(deleteButton).not.toHaveAttribute('disabled')
  })

  it('disables the delete button on a site admin registration', async () => {
    const registration = mockSiteAdminRegistration('site admin', 1)

    const wrapper = renderToolDetailsInner(registration)
    const deleteButton = wrapper.getByTestId('delete-app')
    expect(deleteButton).toHaveAttribute('disabled')
  })

  it('enables the delete button on a local copy registration', async () => {
    const registration = {
      ...mockRegistrationWithAllInformation({n: 'local copy', i: 1}),
      inherited: true,
      template_registration_id: ZLtiRegistrationId.parse('99'),
    }

    const wrapper = renderToolDetailsInner(registration)
    const deleteButton = wrapper.getByTestId('delete-app')
    expect(deleteButton).not.toHaveAttribute('disabled')
  })

  it('shows the "Migrate from LTI 2.0" button when turnitinAPClientId matches developer_key_id', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        developer_key_id: ZDeveloperKeyId.parse('12345'),
      },
    })
    window.ENV.turnitinAPClientId = '12345'

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Migrate from LTI 2.0')).toBeInTheDocument()

    delete window.ENV.turnitinAPClientId
  })

  it('does not show the "Migrate from LTI 2.0" button when turnitinAPClientId does not match', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        developer_key_id: ZDeveloperKeyId.parse('12345'),
      },
    })
    window.ENV.turnitinAPClientId = '99999'

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Migrate from LTI 2.0')).not.toBeInTheDocument()

    delete window.ENV.turnitinAPClientId
  })

  it('shows the "Reinstall App" button when dynamic_registration_url is present and reinstall is not disabled', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: 'https://example.com/register',
        reinstall_disabled: false,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).toBeInTheDocument()
  })

  it('does not show the "Reinstall App" button when reinstall_disabled is true', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: 'https://example.com/register',
        reinstall_disabled: true,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).not.toBeInTheDocument()
  })

  it('does not show the "Reinstall App" button when dynamic_registration_url is not present', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'test',
      i: 1,
      registration: {
        dynamic_registration_url: null,
        reinstall_disabled: false,
      },
    })

    const wrapper = renderToolDetailsInner(registration)

    expect(wrapper.queryByText('Reinstall App')).not.toBeInTheDocument()
  })

  describe('deactivate feature (lti_deactivate_registrations)', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {lti_deactivate_registrations: true},
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('shows "App is On" pill when workflow_state is active', () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {workflow_state: 'active'},
      })
      const wrapper = renderToolDetailsInner(registration)
      expect(wrapper.queryByText('App is On')).toBeInTheDocument()
      expect(wrapper.queryByText('Turn App Off')).toBeInTheDocument()
    })

    it('shows "App is Off" pill when workflow_state is not active', () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {workflow_state: 'inactive'},
      })
      const wrapper = renderToolDetailsInner(registration)
      expect(wrapper.queryByText('App is Off')).toBeInTheDocument()
      expect(wrapper.queryByText('Turn App On')).toBeInTheDocument()
    })

    it('calls the update API with workflowState: inactive when turning off an active app', async () => {
      let capturedBody: unknown
      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
          async ({request}) => {
            capturedBody = await request.json()
            return HttpResponse.json({})
          },
        ),
      )

      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {workflow_state: 'active'},
      })
      renderToolDetailsInner(registration)

      fireEvent.click(screen.getByTestId('toggle-app'))

      await waitFor(() => {
        expect(screen.getByText('Turn Off')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByText('Turn Off'))

      await waitFor(() => {
        expect(capturedBody).toMatchObject({workflow_state: 'inactive'})
      })
    })

    it('calls the update API with workflowState: active when turning on an inactive app', async () => {
      let capturedBody: unknown
      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
          async ({request}) => {
            capturedBody = await request.json()
            return HttpResponse.json({})
          },
        ),
      )

      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {workflow_state: 'inactive'},
      })
      renderToolDetailsInner(registration)

      fireEvent.click(screen.getByTestId('toggle-app'))

      await waitFor(() => {
        expect(screen.getByText('Turn On')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByText('Turn On'))

      await waitFor(() => {
        expect(capturedBody).toMatchObject({workflow_state: 'active'})
      })
    })

    it('shows an error flash when the toggle API call fails', async () => {
      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
          () => new HttpResponse(null, {status: 500}),
        ),
      )

      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {workflow_state: 'active'},
      })
      renderToolDetailsInner(registration)

      fireEvent.click(screen.getByTestId('toggle-app'))

      await waitFor(() => {
        expect(screen.getByText('Turn Off')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByText('Turn Off'))

      await waitFor(() => {
        expect(mockFlash).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'error',
            message: expect.stringContaining('turn off'),
          }),
        )
      })
    })

    describe('inherited registration (site admin only, no template_registration_id)', () => {
      it('shows "App is On" when account_binding.workflow_state is "on"', () => {
        // mockSiteAdminRegistration has account_binding.workflow_state = 'on' by default
        const registration = mockSiteAdminRegistration('site admin', 1)
        const wrapper = renderToolDetailsInner(registration)
        expect(wrapper.queryByText('App is On')).toBeInTheDocument()
      })

      it('shows "App is Off" when account_binding.workflow_state is not "on"', () => {
        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'off'},
        }
        const wrapper = renderToolDetailsInner(registration)
        expect(wrapper.queryByText('App is Off')).toBeInTheDocument()
      })

      it('calls the bind endpoint (not the update endpoint) when turning off', async () => {
        const unbindSpy = vi
          .spyOn(RegistrationsApi, 'unbindGlobalLtiRegistration')
          .mockResolvedValueOnce({_type: 'Success', data: {} as never, links: {}})
        const bindSpy = vi.spyOn(RegistrationsApi, 'bindGlobalLtiRegistration')

        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {...base, account_id: ZAccountId.parse('99')}
        renderToolDetailsInner(registration)

        fireEvent.click(screen.getByTestId('toggle-app'))

        await waitFor(() => {
          expect(screen.getByText('Turn Off')).toBeInTheDocument()
        })
        fireEvent.click(screen.getByText('Turn Off'))

        await waitFor(() => {
          expect(unbindSpy).toHaveBeenCalledWith(registration.account_id, registration.id)
        })
        expect(bindSpy).not.toHaveBeenCalled()
      })

      it('calls the bind endpoint (not the update endpoint) when turning on', async () => {
        const bindSpy = vi
          .spyOn(RegistrationsApi, 'bindGlobalLtiRegistration')
          .mockResolvedValueOnce({_type: 'Success', data: {} as never, links: {}})
        const unbindSpy = vi.spyOn(RegistrationsApi, 'unbindGlobalLtiRegistration')

        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'off'},
        }
        renderToolDetailsInner(registration)

        fireEvent.click(screen.getByTestId('toggle-app'))

        await waitFor(() => {
          expect(screen.getByText('Turn On')).toBeInTheDocument()
        })
        fireEvent.click(screen.getByText('Turn On'))

        await waitFor(() => {
          expect(bindSpy).toHaveBeenCalledWith(registration.account_id, registration.id)
        })
        expect(unbindSpy).not.toHaveBeenCalled()
      })

      it('shows an error flash when the bind API call fails', async () => {
        vi.spyOn(RegistrationsApi, 'bindGlobalLtiRegistration').mockResolvedValueOnce({
          _type: 'ApiError',
          status: 500,
          body: {error: 'Bind failed'},
        })

        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'off'},
        }
        renderToolDetailsInner(registration)

        fireEvent.click(screen.getByTestId('toggle-app'))

        await waitFor(() => {
          expect(screen.getByText('Turn On')).toBeInTheDocument()
        })
        fireEvent.click(screen.getByText('Turn On'))

        await waitFor(() => {
          expect(mockFlash).toHaveBeenCalledWith(
            expect.objectContaining({
              type: 'error',
              message: expect.stringContaining('turn on'),
            }),
          )
        })
      })
    })

    describe('site admin binding pill', () => {
      beforeEach(() => {
        window.ENV.ACCOUNT_IS_SITE_ADMIN = true
      })

      afterEach(() => {
        delete window.ENV.ACCOUNT_IS_SITE_ADMIN
      })

      it('shows "App is Allowed" when binding state is "allow"', () => {
        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'allow'},
        }
        const wrapper = renderToolDetailsInner(registration)
        expect(wrapper.queryByText('App is Allowed')).toBeInTheDocument()
      })

      it('shows "App is On" when binding state is "on"', () => {
        // mockSiteAdminRegistration defaults to account_binding.workflow_state = 'on'
        const registration = mockSiteAdminRegistration('site admin', 1)
        const wrapper = renderToolDetailsInner(registration)
        expect(wrapper.queryByText('App is On')).toBeInTheDocument()
      })

      it('shows "App is Off" when binding state is neither "allow" nor "on"', () => {
        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'off'},
        }
        const wrapper = renderToolDetailsInner(registration)
        expect(wrapper.queryByText('App is Off')).toBeInTheDocument()
      })
    })

    describe('forced-on inherited registration with templates flag off', () => {
      it('disables the toggle button when registration is forced on', () => {
        const registration = mockSiteAdminRegistration('site admin', 1)
        renderToolDetailsInner(registration)
        expect(screen.getByTestId('toggle-app')).toHaveAttribute('disabled')
      })

      it('enables the toggle button when binding is not forced on', () => {
        const base = mockSiteAdminRegistration('site admin', 1)
        const registration = {
          ...base,
          account_binding: {...base.account_binding!, workflow_state: 'allow'},
        }
        renderToolDetailsInner(registration)
        expect(screen.getByTestId('toggle-app')).not.toHaveAttribute('disabled')
      })

      it('shows a tooltip when the button is disabled', async () => {
        const registration = mockSiteAdminRegistration('site admin', 1)
        renderToolDetailsInner(registration)
        fireEvent.mouseOver(screen.getByTestId('toggle-app'))
        await waitFor(() => {
          expect(
            screen.getByText('This app is locked on by Instructure, and cannot be turned off.'),
          ).toBeInTheDocument()
        })
      })
    })

    describe('local copy registration (inherited with template_registration_id)', () => {
      const mockLocalCopyRegistration = (workflowState: LtiRegistration['workflow_state']) => ({
        ...mockRegistrationWithAllInformation({n: 'local copy', i: 1}),
        inherited: true,
        template_registration_id: ZLtiRegistrationId.parse('99'),
        workflow_state: workflowState,
      })

      it('shows "App is On" when workflow_state is active', () => {
        const wrapper = renderToolDetailsInner(mockLocalCopyRegistration('active'))
        expect(wrapper.queryByText('App is On')).toBeInTheDocument()
      })

      it('shows "App is Off" when workflow_state is not active', () => {
        const wrapper = renderToolDetailsInner(mockLocalCopyRegistration('inactive'))
        expect(wrapper.queryByText('App is Off')).toBeInTheDocument()
      })

      it('calls the update endpoint (not the bind endpoint) when turning off', async () => {
        let capturedUpdateBody: unknown
        const bindSpy = vi.spyOn(RegistrationsApi, 'bindGlobalLtiRegistration')
        const unbindSpy = vi.spyOn(RegistrationsApi, 'unbindGlobalLtiRegistration')
        server.use(
          http.put(
            '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
            async ({request}) => {
              capturedUpdateBody = await request.json()
              return HttpResponse.json({})
            },
          ),
        )

        renderToolDetailsInner(mockLocalCopyRegistration('active'))

        fireEvent.click(screen.getByTestId('toggle-app'))

        await waitFor(() => {
          expect(screen.getByText('Turn Off')).toBeInTheDocument()
        })
        fireEvent.click(screen.getByText('Turn Off'))

        await waitFor(() => {
          expect(capturedUpdateBody).toMatchObject({workflow_state: 'inactive'})
        })
        expect(bindSpy).not.toHaveBeenCalled()
        expect(unbindSpy).not.toHaveBeenCalled()
      })

      it('calls the update endpoint (not the bind endpoint) when turning on', async () => {
        let capturedUpdateBody: unknown
        const bindSpy = vi.spyOn(RegistrationsApi, 'bindGlobalLtiRegistration')
        const unbindSpy = vi.spyOn(RegistrationsApi, 'unbindGlobalLtiRegistration')
        server.use(
          http.put(
            '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
            async ({request}) => {
              capturedUpdateBody = await request.json()
              return HttpResponse.json({})
            },
          ),
        )

        renderToolDetailsInner(mockLocalCopyRegistration('inactive'))

        fireEvent.click(screen.getByTestId('toggle-app'))

        await waitFor(() => {
          expect(screen.getByText('Turn On')).toBeInTheDocument()
        })
        fireEvent.click(screen.getByText('Turn On'))

        await waitFor(() => {
          expect(capturedUpdateBody).toMatchObject({workflow_state: 'active'})
        })
        expect(bindSpy).not.toHaveBeenCalled()
        expect(unbindSpy).not.toHaveBeenCalled()
      })
    })
  })

  describe('lock/unlock feature (lock_lti_registrations)', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {lock_lti_registrations: true},
      })
    })

    it("shows a pill showing the registration's lock state", () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {lock_deploying: true},
      })
      const wrapper = renderToolDetailsInner(registration)
      expect(wrapper.queryByText('App is locked')).toBeInTheDocument()
    })

    it('disables the lock button on an inherited registration', () => {
      const registration = mockSiteAdminRegistration('site admin', 1)
      const wrapper = renderToolDetailsInner(registration)
      const lockButton = wrapper.getByTestId('toggle-lock')
      expect(lockButton).toHaveAttribute('disabled')
    })

    it('enables the lock button on a non-inherited registration', () => {
      const registration = mockRegistrationWithAllInformation({n: 'test', i: 1})
      const wrapper = renderToolDetailsInner(registration)
      const lockButton = wrapper.getByTestId('toggle-lock')
      expect(lockButton).not.toHaveAttribute('disabled')
    })

    it('enables the lock button on a local copy registration', () => {
      const registration = {
        ...mockRegistrationWithAllInformation({n: 'local copy', i: 1}),
        inherited: true,
        template_registration_id: ZLtiRegistrationId.parse('99'),
      }
      const wrapper = renderToolDetailsInner(registration)
      const lockButton = wrapper.getByTestId('toggle-lock')
      expect(lockButton).not.toHaveAttribute('disabled')
    })

    it('shows a tooltip on the lock button for an inherited registration', async () => {
      const registration = mockSiteAdminRegistration('site admin', 1)
      renderToolDetailsInner(registration)
      fireEvent.mouseOver(screen.getByTestId('toggle-lock'))
      await waitFor(() => {
        expect(
          screen.getByText("This account does not own this app and therefore can't lock it."),
        ).toBeInTheDocument()
      })
    })

    it("let's users change registration state", async () => {
      let capturedBody: unknown
      server.use(
        http.put(
          '/api/v1/accounts/:accountId/lti_registrations/:registrationId',
          async ({request}) => {
            capturedBody = await request.json()
            return HttpResponse.json({})
          },
        ),
      )

      const registration = mockRegistrationWithAllInformation({
        n: 'test',
        i: 1,
        registration: {lock_deploying: false},
      })
      renderToolDetailsInner(registration)

      fireEvent.click(screen.getByText('Lock app'))

      await waitFor(() => {
        expect(
          screen.getByText(/This app will no longer deployable by client ID or course copy/i),
        ).toBeInTheDocument()
      })

      fireEvent.click(screen.getByText(/Lock$/i))

      await waitFor(() => {
        expect(capturedBody).toMatchObject({lock_deploying: true})
      })
    })
  })
})
