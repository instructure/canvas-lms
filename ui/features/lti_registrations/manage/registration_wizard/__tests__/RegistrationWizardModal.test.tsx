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
  openRegistrationWizard,
  useRegistrationModalWizardState,
} from '../RegistrationWizardModalState'
import {apiError, genericError, success} from '../../../common/lib/apiResult/ApiResult'
import {mockJsonUrlWizardService} from './helpers'
import {
  mockDynamicRegistrationWizardService,
  mockLti1p3RegistrationWizardService,
} from '../../dynamic_registration_wizard/__tests__/helpers'
import userEvent from '@testing-library/user-event'
import {ZUnifiedToolId} from '../../model/UnifiedToolId'
import {mockInternalConfiguration} from '../../lti_1p3_registration_form/__tests__/helpers'

describe('RegistrationWizardModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    error = console.error

    warn = console.warn

    console.error = jest.fn()

    console.warn = jest.fn()
  })

  afterAll(() => {
    console.error = error

    console.warn = warn
  })

  const fetchRegistrationToken = jest.fn().mockImplementation(() => new Promise(() => {}))

  const emptyServices = {
    jsonUrlWizardService: mockJsonUrlWizardService({}),
    dynamicRegistrationWizardService: mockDynamicRegistrationWizardService({
      fetchRegistrationToken,
    }),
    lti1p3RegistrationWizardService: mockLti1p3RegistrationWizardService({}),
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
        jsonFetch: {_tag: 'initial'},
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
        jsonCode: '',
        onSuccessfulInstallation: jest.fn(),
        jsonFetch: {_tag: 'initial'},
      })
    })

    afterEach(() => {
      useRegistrationModalWizardState.getState().close()
    })

    it('should validate the json configuration from the URL', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(success(mockInternalConfiguration()))

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {url: 'https://example.com/json'},
        accountId,
      )
    })

    it('renders an error screen when the third party configuration fetch fails', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(
          genericError('An error occurred while fetching the third party tool configuration.'),
        )

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(/An error occurred. Please try again./i, {ignore: 'title'}),
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {url: 'https://example.com/json'},
        accountId,
      )
    })

    it('renders an error screen when the third party configuration is invalid', async () => {
      const accountId = ZAccountId.parse('123')

      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(apiError(422, {errors: ['Bad config']}))

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-url-input').focus()

      await userEvent.paste('https://example.com/json')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(
            /The configuration is invalid. Please reach out to the app provider for assistance./i,
            {ignore: 'title'},
          ),
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {url: 'https://example.com/json'},
        accountId,
      )
    })
  })

  describe('When opened with JSON Code', () => {
    beforeEach(() => {
      openRegistrationWizard({
        dynamicRegistrationUrl: '',
        unifiedToolId: undefined,
        lti_version: '1p3',
        method: 'json',
        registering: false,
        exitOnCancel: false,
        jsonUrl: '',
        jsonCode: '',
        onSuccessfulInstallation: jest.fn(),
        jsonFetch: {_tag: 'initial'},
      })
    })

    it('should validate the json configuration', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(success(mockInternalConfiguration()))

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-code-input').focus()

      await userEvent.paste('{}')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {lti_configuration: {}},
        accountId,
      )
    })

    it('renders an error screen when the third party configuration fetch fails', async () => {
      const accountId = ZAccountId.parse('123')
      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(
          genericError('An error occurred while fetching the third party tool configuration.'),
        )

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-code-input').focus()

      await userEvent.paste('{}')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(/An error occurred. Please try again./i, {ignore: 'title'}),
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {lti_configuration: {}},
        accountId,
      )
    })

    it('renders an error screen when the third party configuration is invalid', async () => {
      const accountId = ZAccountId.parse('123')

      const fetchThirdPartyToolConfiguration = jest
        .fn()
        .mockResolvedValue(apiError(422, {errors: ['Bad config']}))

      const jsonUrlWizardService = mockJsonUrlWizardService({fetchThirdPartyToolConfiguration})

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={jsonUrlWizardService}
        />,
      )
      screen.getByTestId('json-code-input').focus()

      await userEvent.paste('{}')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(
          screen.getByText(
            /The configuration is invalid. Please reach out to the app provider for assistance./i,
            {ignore: 'title'},
          ),
        ).toBeInTheDocument()
      })

      expect(fetchThirdPartyToolConfiguration).toHaveBeenCalledWith(
        {lti_configuration: {}},
        accountId,
      )
    })
  })

  describe('When opened with Manual', () => {
    beforeEach(() => {
      openRegistrationWizard({
        dynamicRegistrationUrl: '',
        unifiedToolId: undefined,
        lti_version: '1p3',
        method: 'manual',
        registering: false,
        exitOnCancel: false,
        jsonUrl: '',
        jsonCode: '',
        onSuccessfulInstallation: jest.fn(),
        jsonFetch: {_tag: 'initial'},
      })
    })

    it('should disable the Next button when the name is empty', async () => {
      const accountId = ZAccountId.parse('123')

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={mockJsonUrlWizardService()}
        />,
      )
      const nameInput = screen.getByTestId('manual-name-input')
      nameInput.focus()

      // Clear the input field
      await userEvent.clear(nameInput)

      expect(screen.getByTestId('registration-wizard-next-button')).toBeDisabled()

      // Type spaces only
      await userEvent.clear(nameInput)
      await userEvent.type(nameInput, '   ')

      expect(screen.getByTestId('registration-wizard-next-button')).toBeDisabled()
    })

    it('should start the registration wizard when the user clicks Next', async () => {
      const accountId = ZAccountId.parse('123')

      const screen = render(
        <RegistrationWizardModal
          accountId={accountId}
          {...emptyServices}
          jsonUrlWizardService={mockJsonUrlWizardService()}
        />,
      )
      screen.getByTestId('manual-name-input').focus()

      await userEvent.paste('My App')

      await userEvent.click(screen.getByTestId('registration-wizard-next-button'))

      await waitFor(() => {
        expect(screen.getByText(/LTI 1.3 Registration/i)).toBeInTheDocument()
      })
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
        jsonFetch: {_tag: 'initial'},
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
