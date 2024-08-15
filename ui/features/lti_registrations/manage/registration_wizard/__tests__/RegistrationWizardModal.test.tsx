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
import {RegistrationWizardModal} from '../RegistrationWizardModal'
import {ZAccountId} from '../../model/AccountId'
import {
  openDynamicRegistrationWizard,
  openRegistrationWizard,
  useRegistrationModalWizardState,
} from '../RegistrationWizardModalState'
import {apiParseError, genericError, success} from '../../../common/lib/apiResult/ApiResult'
import {mockToolConfiguration, mockJsonUrlWizardService} from './helpers'
import {ZLtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'
import {mockDynamicRegistrationWizardService} from '../../dynamic_registration_wizard/__tests__/helpers'
import userEvent from '@testing-library/user-event'
import {ZUnifiedToolId} from '../../model/UnifiedToolId'

describe('RegistrationWizardModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    // eslint-disable-next-line no-console
    error = console.error
    // eslint-disable-next-line no-console
    warn = console.warn

    // eslint-disable-next-line no-console
    console.error = jest.fn()
    // eslint-disable-next-line no-console
    console.warn = jest.fn()
  })

  afterAll(() => {
    // eslint-disable-next-line no-console
    console.error = error
    // eslint-disable-next-line no-console
    console.warn = warn
  })

  const fetchRegistrationToken = jest.fn().mockImplementation(() => new Promise(() => {}))

  const emptyServices = {
    jsonUrlWizardService: mockJsonUrlWizardService({}),
    dynamicRegistrationWizardService: mockDynamicRegistrationWizardService({
      fetchRegistrationToken,
    }),
  }

  describe('When opened normally', () => {
    beforeEach(() => {
      openRegistrationWizard({
        dynamicRegistrationUrl: '',
        unifiedToolId: undefined,
        lti_version: '1p3',
        method: 'dynamic_registration',
        registering: false,
        exitOnCancel: false,
        jsonUrl: '',
        onSuccessfulInstallation: jest.fn(),
        jsonUrlFetch: {_tag: 'initial'},
      })
    })

    afterEach(() => {
      useRegistrationModalWizardState.getState().close()
    })

    it('should render the modal title', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} {...emptyServices} />)
      const headerText = screen.getByText(/Install App/i)
      expect(headerText).toBeInTheDocument()
    })

    it('should disable the next button when there is no dynamic registration url', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} {...emptyServices} />)
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      expect(nextButton).toBeInTheDocument()
      expect(nextButton).toBeDisabled()
    })

    it('should enable the next button when there is a valid url in the dynamic registration input', () => {
      const accountId = ZAccountId.parse('123')
      render(<RegistrationWizardModal accountId={accountId} {...emptyServices} />)
      const urlInput = screen.getByLabelText(/Dynamic Registration URL/i, {selector: 'input'})
      fireEvent.change(urlInput, {target: {value: 'https://example.com'}})
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      expect(nextButton).toBeInTheDocument()
      expect(nextButton).toBeEnabled()
    })

    it('should render the dynamic registration wizard when dynamic registration is selected', () => {
      const accountId = ZAccountId.parse('123')
      const screen = render(<RegistrationWizardModal accountId={accountId} {...emptyServices} />)
      const urlInput = screen.getByLabelText(/Dynamic Registration URL/i, {selector: 'input'})
      fireEvent.change(urlInput, {target: {value: 'https://example.com'}})
      const nextButton = screen.getByRole('button', {
        name: /Next/i,
      })
      fireEvent.click(nextButton)
      // expect the dynamic registration wizard to be rendered
      const el = screen.getByText(/Loading/i, {ignore: 'title'})
      expect(el).toBeInTheDocument()
    })
  })

  describe('When opened with JSON URL', () => {
    beforeEach(() => {
      openRegistrationWizard({
        dynamicRegistrationUrl: '',
        unifiedToolId: undefined,
        lti_version: '1p3',
        method: 'json_url',
        registering: false,
        exitOnCancel: false,
        jsonUrl: '',
        onSuccessfulInstallation: jest.fn(),
        jsonUrlFetch: {_tag: 'initial'},
      })
    })

    afterEach(() => {
      useRegistrationModalWizardState.getState().close()
    })

    it('should validate the json configuration from the URL', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest.fn().mockResolvedValue(
        success(
          mockToolConfiguration({
            title: 'Test Tool',
          })
        )
      )

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(screen.getByText(/Test Tool/i, {ignore: 'title'})).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        'https://example.com/json',
        accountId
      )
    })

    it('renders an error screen when the third party configuration fetch fails', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(
          genericError('An error occurred while fetching the third party tool configuration.')
        )

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(/An error occurred. Please try again./i, {ignore: 'title'})
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        'https://example.com/json',
        accountId
      )
    })

    it('renders an error screen when the third party configuration is invalid', async () => {
      const accountId = ZAccountId.parse('123')
      const result = ZLtiConfiguration.safeParse({
        title: 'An invalid tool',
        description: 'This tool is invalid',
        target_link_uri: 'http://example.com',
        oidc_initiation_url: 'http://example.com',
        custom_fields: 'An invalid custom field',
        oidc_initiation_urls: {},
        public_jwk_url: 'http://example.com',
        scopes: [],
        extensions: [],
      })

      if (result.success) {
        throw new Error('Expected an error')
      }

      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(apiParseError(result.error, 'http://example.com'))

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(
            /The configuration is invalid. Please reach out to the app provider for assistance./i,
            {ignore: 'title'}
          )
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        'https://example.com/json',
        accountId
      )
    })
  })

  describe('when pre-opened with dynamic registration', () => {
    it('should exit the modal when the cancel button is clicked & exitOnCancel is true', async () => {
      openRegistrationWizard({
        dynamicRegistrationUrl: 'http://example.com',
        unifiedToolId: ZUnifiedToolId.parse('asdf'),
        lti_version: '1p3',
        method: 'dynamic_registration',
        registering: true,
        exitOnCancel: true,
        jsonUrl: '',
        onSuccessfulInstallation: jest.fn(),
        jsonUrlFetch: {_tag: 'initial'},
      })
      const accountId = ZAccountId.parse('123')
      const screen = render(<RegistrationWizardModal accountId={accountId} {...emptyServices} />)
      const cancelButton = screen.getByRole('button', {
        name: /Cancel/i,
      })
      fireEvent.click(cancelButton)
      await waitFor(() => {
        expect(screen.queryByText(/Install App/i)).not.toBeInTheDocument()
      })
    })
  })
})
