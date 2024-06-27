/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {ZAccountId} from '../../model/AccountId'
import {DynamicRegistrationWizard} from '../DynamicRegistrationWizard'
import type {DynamicRegistrationWizardService} from '../DynamicRegistrationWizardService'
import {success} from '../../../common/lib/apiResult/ApiResult'
import userEvent from '@testing-library/user-event'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {i18nLtiScope} from '../../model/LtiScope'
import {mockRegistration, mockService} from './helpers'
import {htmlEscape} from '@instructure/html-escape'

jest.mock('@canvas/alerts/react/FlashAlert')

const mockAlert = showFlashAlert as jest.Mock<typeof showFlashAlert>

describe('DynamicRegistrationWizard', () => {
  it('renders a loading screen when fetching the registration token', () => {
    const accountId = ZAccountId.parse('123')
    const unifiedToolId = 'asdf'

    const fetchRegistrationToken = jest.fn().mockImplementation(() => new Promise(() => {}))

    const getRegistrationByUUID = jest.fn().mockResolvedValue(success(mockRegistration()))

    const service = mockService({fetchRegistrationToken, getRegistrationByUUID})

    render(
      <DynamicRegistrationWizard
        dynamicRegistrationUrl="https://example.com"
        service={service}
        accountId={accountId}
        unifiedToolId={unifiedToolId}
        unregister={() => {}}
      />
    )

    expect(fetchRegistrationToken).toHaveBeenCalledWith(accountId, unifiedToolId)
    // Ignore screenreader title.
    expect(screen.getByText(/Loading/i, {ignore: 'title'})).toBeInTheDocument()
  })

  it('forwards users to the tool', async () => {
    const accountId = ZAccountId.parse('123')
    const unifiedToolId = 'asdf'
    const fetchRegistrationToken = jest.fn().mockResolvedValue(
      success({
        token: 'reg_token_value',
        oidc_configuration_url: 'oidc_config_url_value',
        uuid: 'uuid_value',
      })
    )
    const getRegistrationByUUID = jest.fn().mockResolvedValue(success(mockRegistration()))
    const service = mockService({fetchRegistrationToken, getRegistrationByUUID})

    render(
      <DynamicRegistrationWizard
        dynamicRegistrationUrl="https://example.com?foo=bar"
        service={service}
        accountId={accountId}
        unifiedToolId={unifiedToolId}
        unregister={() => {}}
      />
    )
    expect(fetchRegistrationToken).toHaveBeenCalledWith(accountId, unifiedToolId)
    const frame = await waitFor(() => screen.getByTestId('dynamic-reg-wizard-iframe'))
    expect(frame).toBeInTheDocument()
    expect(frame).toBeInstanceOf(HTMLIFrameElement)
    expect(frame as HTMLIFrameElement).toHaveAttribute(
      'src',
      'https://example.com/?foo=bar&openid_configuration=oidc_config_url_value&registration_token=reg_token_value'
    )
  })

  it('retrieves the registration when the tool returns', async () => {
    const accountId = ZAccountId.parse('123')
    const fetchRegistrationToken = jest.fn().mockResolvedValue(
      success({
        token: 'reg_token_value',
        oidc_configuration_url: 'oidc_config_url_value',
        uuid: 'uuid_value',
      })
    )
    const getRegistrationByUUID = jest.fn().mockResolvedValue(success(mockRegistration()))
    const service = mockService({fetchRegistrationToken, getRegistrationByUUID})

    render(
      <DynamicRegistrationWizard
        service={service}
        dynamicRegistrationUrl="https://example.com/"
        accountId={accountId}
        unregister={() => {}}
      />
    )

    const iframe = await screen.findByTestId('dynamic-reg-wizard-iframe')
    expect(iframe).toBeInTheDocument()
    expect(iframe).toHaveAttribute(
      'src',
      'https://example.com/?openid_configuration=oidc_config_url_value&registration_token=reg_token_value'
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'org.imsglobal.lti.close',
        },
        origin: 'https://example.com',
      })
    )

    await waitFor(() => {
      expect(screen.getByText(/Loading Registration/i)).toBeInTheDocument()
    })

    await waitFor(() => screen.findByText(/Permissions/i))

    expect(getRegistrationByUUID).toHaveBeenCalledWith('123', 'uuid_value')
  })

  describe('PermissionConfirmation', () => {
    const accountId = ZAccountId.parse('123')
    const fetchRegistrationToken = jest.fn().mockResolvedValue(
      success({
        token: 'reg_token_value',
        oidc_configuration_url: 'oidc_config_url_value',
        uuid: 'uuid_value',
      })
    )
    let reg = mockRegistration()
    const getRegistrationByUUID = jest.fn().mockImplementation(async () => success(reg))
    const deleteDeveloperKey = jest.fn().mockImplementation(async () => success(reg))
    const service = mockService({
      fetchRegistrationToken,
      getRegistrationByUUID,
      deleteDeveloperKey,
    })

    const setup = async () => {
      render(
        <DynamicRegistrationWizard
          service={service}
          dynamicRegistrationUrl="https://example.com/"
          accountId={accountId}
          unregister={() => {}}
        />
      )

      await screen.findByTestId('dynamic-reg-wizard-iframe')

      fireEvent(
        window,
        new MessageEvent('message', {
          data: {
            subject: 'org.imsglobal.lti.close',
          },
          origin: 'https://example.com',
        })
      )
      await screen.findByText(/Permissions/i)
    }

    it('renders the requested permissions', async () => {
      await setup()
      expect(reg.scopes.length).toBeGreaterThan(0)
      for (const scope of reg.scopes) {
        expect(screen.getByText(i18nLtiScope(scope))).toBeInTheDocument()
      }
    })

    it("doesn't allow for xss", async () => {
      const xss = '<script>alert("xss")</script>'
      reg = mockRegistration({client_name: xss})
      await setup()
      expect(screen.getByText(htmlEscape(xss))).toBeInTheDocument()
    })

    it("renders the tool's name in bold", async () => {
      reg = mockRegistration({client_name: 'Tool Name'})
      await setup()
      expect(screen.getByText(reg.client_name).closest('strong')).toBeInTheDocument()
    })

    it('lets the user disable scopes', async () => {
      await setup()
      const checkbox = screen.getByTestId(reg.scopes[0])
      expect(checkbox).toBeChecked()
      await userEvent.click(checkbox)
      expect(checkbox).not.toBeChecked()
    })

    it('tries to delete the associated dev key when Cancel is clicked', async () => {
      await setup()
      await userEvent.click(screen.getByText(/Cancel/i).closest('button')!)

      await waitFor(() => {
        expect(service.deleteDeveloperKey).toHaveBeenCalledWith(reg.developer_key_id)
        expect(mockAlert).not.toHaveBeenCalled()
      })
    })
  })
})
